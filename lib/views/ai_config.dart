import 'package:bett_box/common/ai_client.dart';
import 'package:bett_box/common/ai_config.dart';
import 'package:bett_box/common/common.dart';
import 'package:bett_box/state.dart';
import 'package:bett_box/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Settings entry for AI patrol interpretation (T30, BYOK). Lives in
/// the application settings list; the patrol page links here too.
class AiConfigEntryItem extends StatelessWidget {
  const AiConfigEntryItem({super.key});

  @override
  Widget build(BuildContext context) {
    return ListItem(
      leading: const Icon(Icons.auto_awesome_outlined),
      title: Text(appLocalizations.aiConfigTitle),
      subtitle: Text(appLocalizations.aiConfigDesc),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => BaseNavigator.push(context, const AiConfigView()),
    );
  }
}

/// AI provider configuration: preset picker, endpoint / key / model
/// fields, a connectivity test, and — for Groq, the recommended
/// preset — the in-app step-by-step guide (spec requirement). With
/// nothing configured this page is the only place AI exists: the
/// patrol page shows no AI UI at all until a config is saved.
class AiConfigView extends ConsumerStatefulWidget {
  const AiConfigView({super.key});

  @override
  ConsumerState<AiConfigView> createState() => _AiConfigViewState();
}

class _AiConfigViewState extends ConsumerState<AiConfigView> {
  final _baseUrlController = TextEditingController();
  final _apiKeyController = TextEditingController();
  final _modelController = TextEditingController();
  String? _presetName;
  bool _loaded = false;
  bool _testing = false;
  String? _testResult;

  @override
  void initState() {
    super.initState();
    AiConfigStore.load().then((config) {
      if (!mounted) return;
      _baseUrlController.text = config.baseUrl;
      _apiKeyController.text = config.apiKey;
      _modelController.text = config.model;
      _presetName = _matchPreset(config.baseUrl);
      setState(() => _loaded = true);
    });
  }

  @override
  void dispose() {
    _baseUrlController.dispose();
    _apiKeyController.dispose();
    _modelController.dispose();
    super.dispose();
  }

  String? _matchPreset(String baseUrl) {
    for (final preset in aiProviderPresets) {
      if (preset.baseUrl == baseUrl) return preset.name;
    }
    return null;
  }

  AiProviderPreset? get _preset {
    for (final preset in aiProviderPresets) {
      if (preset.name == _presetName) return preset;
    }
    return null;
  }

  AiConfig _current() => AiConfig(
    baseUrl: _baseUrlController.text.trim(),
    apiKey: _apiKeyController.text.trim(),
    model: _modelController.text.trim(),
  );

  Future<void> _save() async {
    await AiConfigStore.save(_current());
    if (mounted) globalState.showNotifier(appLocalizations.saveSuccess);
  }

  Future<void> _test() async {
    setState(() {
      _testing = true;
      _testResult = null;
    });
    final ok = await testAiConnection(_current());
    if (!mounted) return;
    setState(() {
      _testing = false;
      _testResult = ok
          ? appLocalizations.aiTestOk
          : appLocalizations.aiTestFailed;
    });
  }

  @override
  Widget build(BuildContext context) {
    final preset = _preset;
    return CommonScaffold(
      title: appLocalizations.aiConfigTitle,
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              children: [
                Text(
                  appLocalizations.aiConfigDesc,
                  style: context.textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                Text(
                  appLocalizations.aiPreset,
                  style: context.textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final item in aiProviderPresets)
                      ChoiceChip(
                        label: Text(item.name),
                        selected: _presetName == item.name,
                        onSelected: (_) {
                          setState(() {
                            _presetName = item.name;
                            _baseUrlController.text = item.baseUrl;
                            if (item.defaultModel.isNotEmpty) {
                              _modelController.text = item.defaultModel;
                            }
                            _testResult = null;
                          });
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _baseUrlController,
                  decoration: InputDecoration(
                    labelText: appLocalizations.aiEndpoint,
                    border: const OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.url,
                  onChanged: (_) => _presetName = _matchPreset(
                    _baseUrlController.text.trim(),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _apiKeyController,
                  decoration: InputDecoration(
                    labelText: appLocalizations.aiApiKey,
                    border: const OutlineInputBorder(),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _modelController,
                  decoration: InputDecoration(
                    labelText: appLocalizations.aiModel,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    FilledButton(
                      onPressed: _save,
                      child: Text(appLocalizations.save),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton(
                      onPressed: _testing ? null : _test,
                      child: Text(appLocalizations.aiTestConnection),
                    ),
                    if (_testResult != null) ...[
                      const SizedBox(width: 12),
                      Expanded(child: Text(_testResult!)),
                    ],
                  ],
                ),
                if (preset != null && preset.keysUrl != null) ...[
                  const SizedBox(height: 24),
                  Text(
                    appLocalizations.aiGroqGuideTitle,
                    style: context.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(appLocalizations.aiGuideSteps),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      TextButton(
                        onPressed: () =>
                            globalState.openUrl(preset.keysUrl!),
                        child: Text(appLocalizations.aiGetKey),
                      ),
                      if (preset.zdrUrl != null)
                        TextButton(
                          onPressed: () =>
                              globalState.openUrl(preset.zdrUrl!),
                          child: Text(appLocalizations.aiZdrSettings),
                        ),
                    ],
                  ),
                ],
              ],
            ),
    );
  }
}
