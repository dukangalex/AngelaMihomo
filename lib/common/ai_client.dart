import 'dart:io';

import 'package:bett_box/common/ai_config.dart';
import 'package:bett_box/common/http.dart';
import 'package:bett_box/common/log_redaction.dart';
import 'package:bett_box/models/patrol.dart';
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

/// Sends the (already user-confirmed) redacted summary and returns
/// the model's plain-language interpretation. Throws on any failure;
/// the caller shows the error verbatim.
Future<String> fetchAiInterpretation(AiConfig config, String summary) async {
  final response = await _aiDio(config).post<Map<String, dynamic>>(
    _endpoint(config, '/chat/completions'),
    data: {
      'model': config.model.trim(),
      'messages': [
        {
          'role': 'system',
          'content':
              'You are the diagnostic assistant inside a proxy client app. '
              'Explain the patrol report in plain language: what is wrong, '
              'the most likely cause, and the concrete next step for each '
              'problem. Be concise. The report is redacted; never ask for '
              'unredacted data, credentials or subscription URLs.',
        },
        {'role': 'user', 'content': summary},
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
