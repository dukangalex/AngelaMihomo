// T88: log-export attachments for on-device forensic records.
//
// Two records live outside the in-memory log, so a plain log export
// never contained them (audit, hidden_files/
// t88-background-disconnect-audit.md section 11):
//  - fair_memory_events.log: the Kotlin FairMemoryHelper's trail of
//    OEM memory callbacks (TRIM/KILL pre-notices) — often the only
//    evidence inside the death window of a background kill.
//  - quick_start_failure.json: the persistent marker an exhausted
//    background quick start leaves behind.
// exportLogs appends each file as a delimited section when it exists,
// using the same per-line redaction as the main log body.

/// Builds one export section for an on-device forensic file, or
/// returns null when there is nothing to attach (file missing or
/// blank). [content] is the file's raw text; [redactLine] is applied
/// to every line, exactly like the main log body (T36 discipline).
String? buildForensicLogSection({
  required String fileName,
  required String? content,
  required String Function(String line) redactLine,
}) {
  if (content == null || content.trim().isEmpty) return null;
  final body = content
      .replaceAll('\r\n', '\n')
      .split('\n')
      .map(redactLine)
      .join('\n')
      .trim();
  if (body.isEmpty) return null;
  return '----- $fileName -----\n$body';
}
