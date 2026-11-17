import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

// T169 (chain.26): the seven locales must carry identical key sets in
// both the arb sources and the generated messages, and arb and messages
// must agree with each other. A key missing in one locale silently
// falls back to English at runtime, which is how the gaps this test
// guards against shipped in the first place.
void main() {
  test('l10n key sets are identical across all seven locales', () {
    const langs = ['en', 'fa', 'ja', 'ko', 'ru', 'zh_CN', 'zh_TC'];

    Set<String> messagesKeys(String lang) {
      final src = File(
        'lib/l10n/intl/messages_$lang.dart',
      ).readAsStringSync();
      return {
        for (final m in RegExp(
          r'"(\w+)":\s*(?:MessageLookupByLibrary|m\d+)',
        ).allMatches(src))
          m.group(1)!,
      };
    }

    Set<String> arbKeys(String lang) {
      final json = jsonDecode(File('arb/intl_$lang.arb').readAsStringSync())
          as Map<String, dynamic>;
      return json.keys.where((k) => !k.startsWith('@')).toSet();
    }

    final baseMessages = messagesKeys('en');
    final baseArb = arbKeys('en');
    expect(baseArb, baseMessages, reason: 'arb and messages_en disagree');
    for (final lang in langs.skip(1)) {
      expect(messagesKeys(lang), baseMessages, reason: 'messages_$lang');
      expect(arbKeys(lang), baseArb, reason: 'intl_$lang.arb');
    }
  });
}
