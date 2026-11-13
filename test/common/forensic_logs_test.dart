import 'package:bett_box/common/forensic_logs.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('buildForensicLogSection (T110 export attachments)', () {
    String identity(String line) => line;

    test('missing content attaches nothing', () {
      expect(
        buildForensicLogSection(
          fileName: 'fair_memory_events.log',
          content: null,
          redactLine: identity,
        ),
        isNull,
      );
    });

    test('blank content attaches nothing', () {
      expect(
        buildForensicLogSection(
          fileName: 'quick_start_failure.json',
          content: '  \n\n',
          redactLine: identity,
        ),
        isNull,
      );
    });

    test('content becomes a delimited section with the file name', () {
      final section = buildForensicLogSection(
        fileName: 'fair_memory_events.log',
        content: '2026-11-11T01:02:03+0800 KILL service=VpnService\n',
        redactLine: identity,
      );
      expect(section, isNotNull);
      expect(section, startsWith('----- fair_memory_events.log -----'));
      expect(section, contains('KILL service=VpnService'));
    });

    test('every line passes through the redactor', () {
      final section = buildForensicLogSection(
        fileName: 'quick_start_failure.json',
        content: '{"error":"token=secret-one"}\nsecond secret-two line',
        redactLine: (line) => line.replaceAll('secret', '•••'),
      );
      expect(section, isNot(contains('secret')));
      expect(section, contains('•••-one'));
      expect(section, contains('second •••-two line'));
    });

    test('CRLF content is normalized', () {
      final section = buildForensicLogSection(
        fileName: 'fair_memory_events.log',
        content: 'one\r\ntwo\r\n',
        redactLine: identity,
      );
      expect(section, isNot(contains('\r')));
      expect(section, contains('one\ntwo'));
    });
  });
}
