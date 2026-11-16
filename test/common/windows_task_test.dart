import 'package:bett_box/common/windows_task.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('quoteSchtasksArgument', () {
    test('quotes a task name containing spaces', () {
      expect(quoteSchtasksArgument('Angela Mihomo'), '"Angela Mihomo"');
      expect(
        quoteSchtasksArgument('Angela Mihomo Portable'),
        '"Angela Mihomo Portable"',
      );
    });

    test('leaves a single-word value unquoted', () {
      expect(quoteSchtasksArgument('AngelaMihomo'), 'AngelaMihomo');
    });

    test('quotes a path containing spaces', () {
      expect(
        quoteSchtasksArgument(r'C:\Users\A B\AppData\Local\Temp\task.xml'),
        r'"C:\Users\A B\AppData\Local\Temp\task.xml"',
      );
    });

    test('quotes the empty string and escapes embedded quotes', () {
      expect(quoteSchtasksArgument(''), '""');
      expect(quoteSchtasksArgument('a"b'), r'"a\"b"');
    });
  });

  group('schtasks command lines', () {
    test('register quotes both the task name and the XML path', () {
      final commandLine = buildRegisterTaskCommandLine(
        taskName: 'Angela Mihomo',
        taskXmlPath: r'C:\Users\A B\AppData\Local\Temp\task.xml',
      );
      expect(
        commandLine,
        r'/Create /TN "Angela Mihomo" /XML "C:\Users\A B\AppData\Local\Temp\task.xml" /F',
      );
    });

    test('register keeps a space-free task name unquoted', () {
      final commandLine = buildRegisterTaskCommandLine(
        taskName: 'AngelaMihomo',
        taskXmlPath: r'C:\Temp\task.xml',
      );
      expect(commandLine, r'/Create /TN AngelaMihomo /XML C:\Temp\task.xml /F');
    });

    test('delete quotes the task name', () {
      expect(
        buildDeleteTaskCommandLine(taskName: 'Angela Mihomo'),
        '/Delete /TN "Angela Mihomo" /F',
      );
      expect(
        buildDeleteTaskCommandLine(taskName: 'Angela Mihomo Portable'),
        '/Delete /TN "Angela Mihomo Portable" /F',
      );
    });
  });

  group('buildAutoLaunchTaskXml', () {
    final xml = buildAutoLaunchTaskXml(
      taskName: 'Angela Mihomo',
      executablePath: r'C:\Program Files\Angela Mihomo\Angela Mihomo.exe',
      workingDirectory: r'C:\Program Files\Angela Mihomo',
    );

    test('Command holds the bare executable path without wrapping quotes', () {
      expect(
        xml,
        contains(
          r'<Command>C:\Program Files\Angela Mihomo\Angela Mihomo.exe</Command>',
        ),
      );
      expect(xml, isNot(contains('<Command>"')));
    });

    test('URI carries the full task name including spaces', () {
      expect(xml, contains(r'<URI>\Angela Mihomo</URI>'));
    });

    test('keeps the logon trigger and run-level semantics', () {
      expect(xml, contains('<LogonTrigger>'));
      expect(xml, contains('<RunLevel>HighestAvailable</RunLevel>'));
      expect(
        xml,
        contains('<MultipleInstancesPolicy>IgnoreNew</MultipleInstancesPolicy>'),
      );
      expect(
        xml,
        contains(r'<WorkingDirectory>C:\Program Files\Angela Mihomo</WorkingDirectory>'),
      );
    });
  });
}
