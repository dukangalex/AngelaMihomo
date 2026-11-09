import 'package:bett_box/common/string.dart';
import 'package:bett_box/l10n/l10n.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

// T73: the import paths must never hand a novice a raw DioException
// dump or the core's validation wording. formatProfileImportError is
// the single place that translation happens; formatError (used by
// other features) must stay untouched by it.
void main() {
  setUpAll(() async {
    await AppLocalizations.load(const Locale('zh', 'CN'));
  });

  group('formatProfileImportError', () {
    test('HTTP 状态码失败沿用既有本地化文案', () {
      const e =
          'DioException [bad response]: This exception was thrown because the response has a status code of 502 and RequestOptions.validateStatus was configured to throw for this status code.';
      expect(e.formatProfileImportError, contains('502'));
      expect(e.formatProfileImportError, contains('配置导入失败'));
    });

    test('连接超时翻成人话（网络问题＋下一步）', () {
      const e =
          'DioException [connection timeout]: The request connection took longer than 0:00:15.000000 and it was aborted.';
      final text = e.formatProfileImportError;
      expect(text, contains('网络'));
      expect(text, isNot(contains('DioException')));
    });

    test('连接错误翻成人话', () {
      const e =
          'DioException [connection error]: The connection errored: Failed host lookup: example.com';
      final text = e.formatProfileImportError;
      expect(text, contains('网络'));
      expect(text, isNot(contains('DioException')));
    });

    test('核心校验原文被换成内容不可识别的人话', () {
      const e = ProfileImportFailure(
        'yaml: unmarshal errors: line 3: mapping values are not allowed',
      );
      final text = e.formatProfileImportError;
      expect(text, contains('无法识别'));
      expect(text, isNot(contains('yaml')));
      // 日志侧仍保留原文，不许把证据一起吞掉。
      expect(e.formatErrorLog, contains('yaml: unmarshal errors'));
      expect(e.formatError, contains('yaml: unmarshal errors'));
    });

    test('其它错误原样透传，不乱翻', () {
      const e = 'some other failure';
      expect(e.formatProfileImportError, 'some other failure');
    });
  });
}
