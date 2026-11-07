import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// One OpenAI-compatible provider preset for AI patrol (T30). All
/// endpoints speak the same chat-completions shape; the user may also
/// type any other compatible endpoint by hand.
class AiProviderPreset {
  final String name;
  final String baseUrl;
  final String defaultModel;

  /// Where to get a key (guide card links), when the provider has a
  /// self-serve console.
  final String? keysUrl;

  /// Zero-data-retention settings page, when the provider offers one.
  final String? zdrUrl;

  const AiProviderPreset({
    required this.name,
    required this.baseUrl,
    required this.defaultModel,
    this.keysUrl,
    this.zdrUrl,
  });
}

/// Presets ordered by the spec's preference: Groq first (free tier,
/// zero data retention available, fast), then other OpenAI-compatible
/// providers, then a local Ollama (no key, nothing leaves the device).
const aiProviderPresets = [
  AiProviderPreset(
    name: 'Groq',
    baseUrl: 'https://api.groq.com/openai/v1',
    defaultModel: 'llama-3.3-70b-versatile',
    keysUrl: 'https://console.groq.com/keys',
    zdrUrl: 'https://console.groq.com/docs/your-data',
  ),
  AiProviderPreset(
    name: 'Cloudflare Workers AI',
    baseUrl: 'https://api.cloudflare.com/client/v4/accounts/ACCOUNT_ID/ai/v1',
    defaultModel: '@cf/meta/llama-3.3-70b-instruct-fp8-fast',
  ),
  AiProviderPreset(
    name: 'OpenRouter',
    baseUrl: 'https://openrouter.ai/api/v1',
    defaultModel: '',
    keysUrl: 'https://openrouter.ai/keys',
  ),
  AiProviderPreset(
    name: 'DeepSeek',
    baseUrl: 'https://api.deepseek.com/v1',
    defaultModel: 'deepseek-chat',
    keysUrl: 'https://platform.deepseek.com/api_keys',
  ),
  AiProviderPreset(
    name: 'SiliconFlow',
    baseUrl: 'https://api.siliconflow.cn/v1',
    defaultModel: '',
    keysUrl: 'https://cloud.siliconflow.cn/account/ak',
  ),
  AiProviderPreset(
    name: 'Ollama (local)',
    baseUrl: 'http://127.0.0.1:11434/v1',
    defaultModel: '',
  ),
];

/// The user's BYOK configuration. The API key lives ONLY in this
/// standalone SharedPreferences store: app backups are built from the
/// config model and profile files, never from this store, so the key
/// cannot leak into a backup export (same construction as
/// SystemExplicitStore / PatrolStore).
class AiConfig {
  final String baseUrl;
  final String apiKey;
  final String model;

  const AiConfig({this.baseUrl = '', this.apiKey = '', this.model = ''});

  /// Ready to call: an endpoint and a model. A key is not required
  /// (local Ollama needs none).
  bool get configured => baseUrl.trim().isNotEmpty && model.trim().isNotEmpty;

  AiConfig copyWith({String? baseUrl, String? apiKey, String? model}) =>
      AiConfig(
        baseUrl: baseUrl ?? this.baseUrl,
        apiKey: apiKey ?? this.apiKey,
        model: model ?? this.model,
      );

  Map<String, dynamic> toJson() => {
    'baseUrl': baseUrl,
    'apiKey': apiKey,
    'model': model,
  };

  factory AiConfig.fromJson(Map<String, dynamic> json) => AiConfig(
    baseUrl: json['baseUrl']?.toString() ?? '',
    apiKey: json['apiKey']?.toString() ?? '',
    model: json['model']?.toString() ?? '',
  );
}

class AiConfigStore {
  static const _key = 'ai_patrol.config.v1';

  static Future<AiConfig> load() async {
    final raw = (await SharedPreferences.getInstance()).getString(_key);
    if (raw == null || raw.isEmpty) return const AiConfig();
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic>
          ? AiConfig.fromJson(decoded)
          : const AiConfig();
    } catch (_) {
      return const AiConfig();
    }
  }

  static Future<void> save(AiConfig config) async {
    await (await SharedPreferences.getInstance()).setString(
      _key,
      jsonEncode(config.toJson()),
    );
  }
}
