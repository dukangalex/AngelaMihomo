import 'package:bett_box/common/ai_client.dart';
import 'package:flutter_test/flutter_test.dart';

/// T65: the /models response parser behind the model dropdown.
/// Providers return the OpenAI shape ({data: [{id: ...}]}), but the
/// parser must survive the variants seen in the wild and never hand
/// the dropdown blanks or duplicates.
void main() {
  group('parseAiModelList', () {
    test('openai shape: ids extracted, sorted, deduplicated', () {
      final models = parseAiModelList({
        'object': 'list',
        'data': [
          {'id': 'llama-3.3-70b-versatile', 'object': 'model'},
          {'id': 'gpt-oss-120b', 'object': 'model'},
          {'id': 'llama-3.3-70b-versatile', 'object': 'model'},
        ],
      });
      expect(models, ['gpt-oss-120b', 'llama-3.3-70b-versatile']);
    });

    test('bare list and string entries are accepted', () {
      expect(parseAiModelList(['b-model', 'a-model']), [
        'a-model',
        'b-model',
      ]);
      expect(
        parseAiModelList({
          'data': ['x', {'id': 'y'}],
        }),
        ['x', 'y'],
      );
    });

    test('blanks and id-less entries are dropped', () {
      expect(
        parseAiModelList({
          'data': [
            {'id': '  '},
            {'object': 'model'},
            {'id': ' kept '},
          ],
        }),
        ['kept'],
      );
    });

    test('junk bodies parse to empty (fetch failure path)', () {
      expect(parseAiModelList(null), isEmpty);
      expect(parseAiModelList('not json'), isEmpty);
      expect(parseAiModelList({'error': 'unauthorized'}), isEmpty);
      expect(parseAiModelList({'data': 'nope'}), isEmpty);
    });
  });
}
