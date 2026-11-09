import 'dart:io';

import 'package:bett_box/common/ai_config.dart';
import 'package:bett_box/common/http.dart';
import 'package:bett_box/common/log_redaction.dart';
import 'package:bett_box/models/patrol.dart';
import 'package:bett_box/models/patrol_diagnosis.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';

/// Masks a node/profile name for the AI summary: first and last
/// characters survive so the user can still tell entries apart,
/// the identifying middle does not leave the device.
String maskPatrolName(String name) {
  final trimmed = name.trim();
  if (trimmed.length <= 2) return '•••';
  if (trimmed.length == 3) return '${trimmed[0]}•••';
  return '${trimmed[0]}•••${trimmed[trimmed.length - 1]}';
}

String _maskKnownNames(String text, List<String> names) {
  var result = text;
  // Longest first so a short name cannot partially eat a longer one.
  final sorted = [...names]..sort((a, b) => b.length.compareTo(a.length));
  for (final name in sorted) {
    if (name.trim().length < 2) continue;
    result = result.replaceAll(name, maskPatrolName(name));
  }
  return result;
}

/// Builds the exact text that would be sent to the AI provider —
/// the patrol page shows this verbatim in the preview dialog before
/// anything is sent (T30: 发送前预览、确认才发）. Everything passes
/// through the log redactor (URLs, UUIDs, tokens, share links) and
/// known node names are masked on top.
String buildPatrolSummary(
  PatrolReport report, {
  required List<String> nodeNames,
  List<String> localConclusions = const [],
}) {
  final lines = <String>[
    'AngelaMihomo AI patrol report (redacted summary)',
    'problems: ${report.problemCount}, notices: ${report.noticeCount}',
    '',
    '[logs] severity: ${report.logs.severity.name}, '
        'issues: ${report.logs.totalIssues}, '
        'transient noise skipped: ${report.logs.transientSkipped}',
  ];
  for (final kind in PatrolLogIssueKind.values) {
    final group = report.logs.groupOf(kind);
    if (group == null) continue;
    lines.add('- ${kind.name} x${group.count}');
    final sample = group.sample;
    if (sample != null && sample.isNotEmpty) {
      lines.add('  sample: ${_maskKnownNames(redactLogText(sample), nodeNames)}');
    }
  }
  final sub = report.subscription;
  lines.add(
    '[subscription] severity: ${sub.severity.name}, '
    'remote: ${sub.input.isRemote}, expired: ${sub.isExpired}, '
    'stale: ${sub.isStale}, neverUpdated: ${sub.neverUpdated}, '
    'lastUpdateFailed: ${sub.lastUpdateFailed}',
  );
  final nodes = report.nodes;
  lines.add(
    '[nodes] severity: ${nodes.severity.name}, total: ${nodes.total}, '
    'alive: ${nodes.alive}, dead: ${nodes.dead}, untested: ${nodes.untested}, '
    'widespreadOutage: ${nodes.widespreadOutage}',
  );
  final link = report.link;
  lines.add(
    '[link] severity: ${link.severity.name}, mode: ${link.input.mode}, '
    'chainEnabled: ${link.input.chainEnabled}, '
    'chainIncomplete: ${link.chainIncomplete}, '
    'chainHopDown: ${link.chainHopDown}',
  );
  final core = report.core;
  lines.add(
    '[core] severity: ${core.severity.name}, '
    'version: ${core.input.versionLabel}, '
    'configCheck: ${core.input.configCheck?.name ?? 'not run'}',
  );
  if (core.input.configError.isNotEmpty) {
    lines.add(
      '  config error: ${_maskKnownNames(redactLogText(core.input.configError), nodeNames)}',
    );
  }
  if (localConclusions.isNotEmpty) {
    // T69: the app's own diagnoses ride along as established
    // facts — the AI deepens them, it does not re-decide them.
    lines.add('');
    lines.add('local diagnoses (established facts, do not contradict):');
    for (final conclusion in localConclusions) {
      lines.add(
        '- ${_maskKnownNames(redactLogText(conclusion), nodeNames)}',
      );
    }
  }
  return lines.join('\n');
}

Dio _aiDio(AiConfig config) {
  final dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 90),
      headers: {
        if (config.apiKey.trim().isNotEmpty)
          'Authorization': 'Bearer ${config.apiKey.trim()}',
        'Content-Type': 'application/json',
      },
    ),
  );
  // Requests leave through the app's running core proxy, like every
  // other app request (spec: 请求经 App 核心出站）.
  dio.httpClientAdapter = IOHttpClientAdapter(
    createHttpClient: () {
      final client = HttpClient();
      client.findProxy = (uri) => AngelaHttpOverrides.handleFindProxy(uri);
      return client;
    },
  );
  return dio;
}

String _endpoint(AiConfig config, String path) =>
    '${config.baseUrl.trim().replaceAll(RegExp(r'/+$'), '')}$path';

/// Parses an OpenAI-compatible GET /models response body into the
/// list of model ids the account may use. Pure function: tolerant of
/// the shapes providers actually return (a `data` list of objects
/// with `id`, a bare list, or plain string entries), deduplicates,
/// sorts, and drops blanks. Anything else yields an empty list,
/// which the settings page treats as a failed fetch (manual entry
/// stays available — T65).
List<String> parseAiModelList(dynamic body) {
  final raw = body is Map ? body['data'] : body;
  if (raw is! List) return const [];
  final ids = <String>{};
  for (final entry in raw) {
    final id = entry is Map
        ? entry['id']?.toString()
        : entry?.toString();
    final trimmed = id?.trim() ?? '';
    if (trimmed.isNotEmpty) ids.add(trimmed);
  }
  return ids.toList()..sort();
}

/// Fetches the provider's model list (GET /models with the user's
/// key) for the settings-page dropdown (T65). Throws on transport or
/// HTTP failure; an empty parsed list is also a failure — the caller
/// falls back to manual entry and says so on the page.
Future<List<String>> fetchAiModelList(AiConfig config) async {
  final response = await _aiDio(
    config,
  ).get<dynamic>(_endpoint(config, '/models'));
  final status = response.statusCode ?? 0;
  if (status < 200 || status >= 300) {
    throw StateError('models request failed: HTTP $status');
  }
  final models = parseAiModelList(response.data);
  if (models.isEmpty) throw StateError('models list was empty');
  return models;
}

/// Connectivity check for the settings page: GET /models.
Future<bool> testAiConnection(AiConfig config) async {
  try {
    final response = await _aiDio(
      config,
    ).get<dynamic>(_endpoint(config, '/models'));
    return (response.statusCode ?? 0) >= 200 &&
        (response.statusCode ?? 0) < 300;
  } catch (_) {
    return false;
  }
}

Future<String> _chatCompletion(
  AiConfig config, {
  required String system,
  required String user,
}) async {
  final response = await _aiDio(config).post<Map<String, dynamic>>(
    _endpoint(config, '/chat/completions'),
    data: {
      'model': config.model.trim(),
      'messages': [
        {'role': 'system', 'content': system},
        {'role': 'user', 'content': user},
      ],
    },
  );
  final choices = response.data?['choices'];
  if (choices is List && choices.isNotEmpty) {
    final message = (choices.first as Map)['message'];
    final content = (message as Map?)?['content'];
    if (content is String && content.trim().isNotEmpty) return content.trim();
  }
  throw StateError('empty AI response');
}

/// Cleans a model answer for direct display (T69): the result
/// dialogs render plain text, so a Markdown-flavoured answer used
/// to show raw `**`, `<br>` and pipe tables to the user. The
/// prompts already demand plain text; this is the deterministic
/// net for models that ignore them — `<br>` and block tags become
/// line breaks, table rows become cell lists, separator rows and
/// emphasis markers are dropped.
String sanitizeAiText(String raw) {
  var text = raw.replaceAll(
    RegExp(r'<br\s*/?>', caseSensitive: false),
    '\n',
  );
  text = text.replaceAll(
    RegExp(r'</(p|div|li|tr|h[1-6])>', caseSensitive: false),
    '\n',
  );
  text = text.replaceAll(RegExp(r'<[^>]+>'), '');
  final lines = <String>[];
  for (var line in text.split('\n')) {
    line = line.trim();
    // Markdown table separator row: only pipes, dashes, colons.
    if (line.contains('|') &&
        RegExp(r'^[\|\-: ]+$').hasMatch(line)) {
      continue;
    }
    if (line.contains('|')) {
      final cells = line
          .split('|')
          .map((cell) => cell.trim())
          .where((cell) => cell.isNotEmpty)
          .toList();
      if (cells.isEmpty) continue;
      line = cells.join(' · ');
    }
    line = line
        .replaceAll('**', '')
        .replaceAll('__', '')
        .replaceAll('`', '')
        .replaceFirst(RegExp(r'^#{1,6}\s+'), '')
        .trim();
    if (line.isEmpty && (lines.isEmpty || lines.last.isEmpty)) continue;
    lines.add(line);
  }
  while (lines.isNotEmpty && lines.last.isEmpty) {
    lines.removeLast();
  }
  return lines.join('\n');
}

const _aiPlainChineseRules =
    'Reply ONLY in Simplified Chinese, in plain paragraphs and '
    'short lines: no Markdown, no tables, no HTML tags, no bold '
    'or heading markers. Any local diagnosis included in the data '
    'is an established fact: build on it, never contradict it, and '
    'never suggest what it rules out (for example, when the local '
    'diagnosis says an HTTP 5xx is the provider\'s server fault, '
    'do not suggest resetting or replacing the subscription '
    'link). Be concise and plain-spoken. The data is redacted; '
    'never ask for unredacted data, credentials or subscription '
    'URLs.';

/// Sends the (already user-confirmed) redacted summary and returns
/// the model's plain-language interpretation. Throws on any failure;
/// the caller shows the error verbatim.
Future<String> fetchAiInterpretation(AiConfig config, String summary) async {
  final answer = await _chatCompletion(
    config,
    system:
        'You are the diagnostic assistant inside a proxy client '
        'app. Explain the patrol report in plain language: what '
        'is wrong, the most likely cause, and the concrete next '
        'step for each problem. $_aiPlainChineseRules',
    user: summary,
  );
  return sanitizeAiText(answer);
}

/// Builds the redacted per-issue summary for the detail page's AI
/// layer (T68): the local diagnosis (cause, stage, evidence, probe
/// outcomes) is the input — the AI strengthens the reasoning, it
/// does not replace it. Same redaction discipline as the report
/// summary; the subscription URL itself is never included, only its
/// host is named by the facts, and known names are masked.
String buildPatrolIssueSummary(
  PatrolIssue issue, {
  required List<String> nodeNames,
  Map<PatrolProbeKind, ({bool ok, String detail})> probes = const {},
  PatrolFetchStage? measuredStage,
  String localConclusion = '',
  String localAdvice = '',
}) {
  String clean(String text) =>
      _maskKnownNames(redactLogText(text), nodeNames);
  final lines = <String>[
    'AngelaMihomo AI patrol — single problem diagnosis (redacted)',
    'problem: ${issue.id}, severity: ${issue.severity.name}, '
        'local cause: ${issue.cause.name}',
  ];
  // T69: the app's own conclusion and advice are passed verbatim
  // (localized, user-visible wording) and marked as established
  // facts. Field failure mode being fixed: the raw log sample
  // itself could suggest a remedy ("try resetting the link"), and
  // with no local conclusion in the prompt the model followed the
  // log instead of the diagnosis.
  if (localConclusion.isNotEmpty) {
    lines.add(
      'local diagnosis (established fact, do not contradict): '
      '${clean(localConclusion)}',
    );
  }
  if (localAdvice.isNotEmpty) {
    lines.add('local advice already given to the user: ${clean(localAdvice)}');
  }
  if (issue.stage != null) {
    lines.add('recorded failure stage: ${issue.stage!.name}');
  }
  if (issue.httpStatus != null) {
    lines.add('HTTP status: ${issue.httpStatus}');
  }
  if (measuredStage != null) {
    lines.add('measured failure stage (live probes): ${measuredStage.name}');
  }
  lines.add('evidence:');
  for (final fact in issue.facts) {
    switch (fact.kind) {
      case PatrolFactKind.occurrences:
        lines.add('- matched ${fact.count} log entries');
      case PatrolFactKind.state:
        lines.add('- ${fact.label!.name}: ${fact.value}');
      case PatrolFactKind.sample:
      case PatrolFactKind.recordedError:
        lines.add('- ${clean(fact.text)}');
    }
  }
  if (probes.isNotEmpty) {
    lines.add('live probe results:');
    for (final entry in probes.entries) {
      lines.add(
        '- ${entry.key.name}: ${entry.value.ok ? 'ok' : 'FAILED'}'
        '${entry.value.detail.isEmpty ? '' : ' (${clean(entry.value.detail)})'}',
      );
    }
  }
  if (issue.rawInfo.isNotEmpty) {
    lines.add('raw info (redacted): ${clean(issue.rawInfo)}');
  }
  return lines.join('\n');
}

/// Per-issue AI interpretation (T68): possible causes ranked by
/// likelihood, the impact scope, and concrete next steps. Throws on
/// any failure; the caller shows the error verbatim.
Future<String> fetchAiIssueInterpretation(
  AiConfig config,
  String summary,
) async {
  final answer = await _chatCompletion(
    config,
    system:
        'You are the diagnostic assistant inside a proxy client '
        'app. For this single patrol problem, answer with: (1) '
        'the possible causes ranked by likelihood, each with the '
        'evidence for or against it; (2) the impact scope — what '
        'stops working for the user; (3) concrete next steps the '
        'user can take. $_aiPlainChineseRules',
    user: summary,
  );
  return sanitizeAiText(answer);
}
