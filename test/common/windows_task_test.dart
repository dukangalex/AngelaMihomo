import 'package:angelamihomo/common/windows_task.dart';
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

  group('autoLaunchTaskDefinitionIsCurrent', () {
    const exe = r'D:\VPN\Bettbox\AngelaMihomo.exe';
    const dir = r'D:\VPN\Bettbox';

    String exported({
      bool runLevel = true,
      String command = exe,
      bool workingDirectory = true,
    }) {
      return '''
<?xml version="1.0" encoding="UTF-16"?>
<Task version="1.3" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task">
  <Principals><Principal id="Author"><LogonType>InteractiveToken</LogonType>${runLevel ? '<RunLevel>HighestAvailable</RunLevel>' : ''}</Principal></Principals>
  <Actions Context="Author"><Exec><Command>$command</Command>${workingDirectory ? '<WorkingDirectory>$dir</WorkingDirectory>' : ''}</Exec></Actions>
</Task>''';
    }

    test('accepts a definition built to the current template', () {
      expect(
        autoLaunchTaskDefinitionIsCurrent(
          exported(),
          executablePath: exe,
          workingDirectory: dir,
        ),
        isTrue,
      );
    });

    test('rejects the legacy definition without run level', () {
      expect(
        autoLaunchTaskDefinitionIsCurrent(
          exported(runLevel: false),
          executablePath: exe,
          workingDirectory: dir,
        ),
        isFalse,
      );
    });

    test('rejects a definition without a working directory', () {
      expect(
        autoLaunchTaskDefinitionIsCurrent(
          exported(workingDirectory: false),
          executablePath: exe,
          workingDirectory: dir,
        ),
        isFalse,
      );
    });

    test('rejects a definition pointing at a moved executable', () {
      expect(
        autoLaunchTaskDefinitionIsCurrent(
          exported(command: r'C:\Old\AngelaMihomo.exe'),
          executablePath: exe,
          workingDirectory: dir,
        ),
        isFalse,
      );
    });
  });
}
