/// Pure builders for the Windows Task Scheduler auto-launch integration.
///
/// The schtasks command lines are handed to ShellExecuteW as a single
/// parameter string, so every value that may contain spaces (the display
/// name "Angela Mihomo" does) must be quoted here: an unquoted task name
/// makes schtasks treat only the first word as the task name and reject
/// the rest, so the task is never created. These builders are free of
/// platform imports so they can be unit-tested on any host.
library;

/// Quotes [value] for a Windows command-line parameter string when it
/// contains characters that would otherwise split it into several
/// arguments. Embedded double quotes are backslash-escaped following the
/// standard C runtime convention.
String quoteSchtasksArgument(String value) {
  if (value.isEmpty) return '""';
  if (!value.contains(' ') && !value.contains('\t') && !value.contains('"')) {
    return value;
  }
  return '"${value.replaceAll('"', '\\"')}"';
}

/// Builds the `schtasks` parameter string that creates (or overwrites)
/// the auto-launch task [taskName] from the task XML at [taskXmlPath].
String buildRegisterTaskCommandLine({
  required String taskName,
  required String taskXmlPath,
}) {
  return [
    '/Create',
    '/TN',
    quoteSchtasksArgument(taskName),
    '/XML',
    quoteSchtasksArgument(taskXmlPath),
    '/F',
  ].join(' ');
}

/// Builds the `schtasks` parameter string that deletes the auto-launch
/// task [taskName].
String buildDeleteTaskCommandLine({required String taskName}) {
  return ['/Delete', '/TN', quoteSchtasksArgument(taskName), '/F'].join(' ');
}

/// Builds the Task Scheduler XML for the logon auto-launch task.
///
/// The `<Command>` element holds the executable path itself, not a
/// command line, so it must not be wrapped in quotes: Task Scheduler
/// does not parse it, and a quoted path may fail to resolve at runtime.
String buildAutoLaunchTaskXml({
  required String taskName,
  required String executablePath,
  required String workingDirectory,
}) {
  return '''
<?xml version="1.0" encoding="UTF-16"?>
<Task version="1.3" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task">
  <RegistrationInfo>
    <Description>开机自动启动代理服务</Description>
    <URI>\\$taskName</URI>
  </RegistrationInfo>
  <Principals>
    <Principal id="Author">
      <LogonType>InteractiveToken</LogonType>
      <RunLevel>HighestAvailable</RunLevel>
    </Principal>
  </Principals>
  <Triggers>
    <LogonTrigger>
      <Enabled>true</Enabled>
    </LogonTrigger>
  </Triggers>
  <Settings>
    <MultipleInstancesPolicy>IgnoreNew</MultipleInstancesPolicy>
    <DisallowStartIfOnBatteries>false</DisallowStartIfOnBatteries>
    <StopIfGoingOnBatteries>false</StopIfGoingOnBatteries>
    <AllowHardTerminate>false</AllowHardTerminate>
    <StartWhenAvailable>true</StartWhenAvailable>
    <RunOnlyIfNetworkAvailable>false</RunOnlyIfNetworkAvailable>
    <IdleSettings>
      <StopOnIdleEnd>false</StopOnIdleEnd>
      <RestartOnIdle>false</RestartOnIdle>
    </IdleSettings>
    <AllowStartOnDemand>true</AllowStartOnDemand>
    <Enabled>true</Enabled>
    <Hidden>false</Hidden>
    <RunOnlyIfIdle>false</RunOnlyIfIdle>
    <WakeToRun>false</WakeToRun>
    <ExecutionTimeLimit>PT0S</ExecutionTimeLimit>
    <Priority>6</Priority>
  </Settings>
  <Actions Context="Author">
    <Exec>
      <Command>$executablePath</Command>
      <WorkingDirectory>$workingDirectory</WorkingDirectory>
    </Exec>
  </Actions>
</Task>''';
}
