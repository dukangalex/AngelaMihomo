import 'package:bett_box/common/ai_client.dart';
import 'package:bett_box/common/ai_config.dart';
import 'package:bett_box/common/common.dart';
import 'package:bett_box/state.dart';
import 'package:bett_box/widgets/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

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
  // T30 root cause (2026-11-07, fix15f4/f5 instruments): this page
  // rendered as one solid grey block because its fields were
  // Flutter's TextField (via package:flutter/material.dart) while the
  // rest of the app — including MaterialApp and its localization
  // delegates — comes from the material_ui fork. Flutter's
  // TextField._getEffectiveDecoration calls Flutter's
  // MaterialLocalizations.of, which is absent from the app's scope
  // (only the fork's MaterialLocalizations is provided), so every
  // field threw "Null check operator used on a null value" and was
  // replaced by a 100000px-tall release-grey RenderErrorBox. The
  // exception never surfaced because FlutterError.onError only dumps
  // in debug mode. Fix: use material_ui like every other view.
  // (The earlier TextFormField -> TextField swap was a red herring
  // and stays only because the page never validates.)
  final _baseUrlController = TextEditingController();
  final _apiKeyController = TextEditingController();
  final _modelController = TextEditingController();
  String? _presetName;
  bool _loaded = false;
  bool _testing = false;
  String? _testResult;

  // T65: the model field is a dropdown fed by the provider's live
  // /models list once endpoint + key are in. Manual entry stays as
  // the fallback (fetch failed, or a model outside the list) and is
  // remembered per session: a fetched list the current model is not
  // part of starts in manual mode so nothing the user typed is lost.
  List<String> _models = const [];
  bool _manualModel = true;
  bool _fetchingModels = false;
  String? _modelsStatus;
  bool _modelsFailed = false;

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

  /// T65 fetch: pull the provider's model list with the endpoint and
  /// key currently in the fields. Loading / success / failure all
  /// surface on this page (联动反馈）; failure drops back to manual
  /// entry, which always stays available.
  Future<void> _fetchModels() async {
    final config = _current();
    if (config.baseUrl.isEmpty) {
      setState(() {
        _modelsFailed = true;
        _modelsStatus = appLocalizations.aiModelNeedEndpoint;
      });
      return;
    }
    setState(() {
      _fetchingModels = true;
      _modelsFailed = false;
      _modelsStatus = appLocalizations.aiModelFetching;
    });
    try {
      final models = await fetchAiModelList(config);
      if (!mounted) return;
      setState(() {
        _fetchingModels = false;
        _models = models;
        _modelsFailed = false;
        _modelsStatus = appLocalizations.aiModelFetchOk(models.length);
        // Keep a model the list does not contain visible and
        // editable instead of silently swapping it for list item 0.
        _manualModel = !models.contains(_modelController.text.trim());
        if (!_manualModel) {
          _modelController.text = _modelController.text.trim();
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _fetchingModels = false;
        _modelsFailed = true;
        _manualModel = true;
        _modelsStatus = appLocalizations.aiModelFetchFailed;
      });
    }
  }

  Widget _modelField(BuildContext context) {
    final fromList = !_manualModel && _models.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (fromList)
          InputDecorator(
            decoration: InputDecoration(
              labelText: appLocalizations.aiModel,
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: _models.contains(_modelController.text)
                    ? _modelController.text
                    : null,
                items: [
                  for (final model in _models)
                    DropdownMenuItem(value: model, child: Text(model)),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _modelController.text = value);
                },
              ),
            ),
          )
        else
          TextField(
            controller: _modelController,
            decoration: InputDecoration(
              labelText: appLocalizations.aiModel,
            ),
          ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            OutlinedButton(
              onPressed: _fetchingModels ? null : _fetchModels,
              child: Text(appLocalizations.aiModelFetch),
            ),
            if (_models.isNotEmpty)
              TextButton(
                onPressed: () => setState(() {
                  _manualModel = !_manualModel;
                  // Returning to the list with an off-list model
                  // selects nothing rather than a wrong entry.
                  if (!_manualModel &&
                      !_models.contains(_modelController.text.trim())) {
                    _modelController.clear();
                  }
                }),
                child: Text(
                  fromList
                      ? appLocalizations.aiModelManual
                      : appLocalizations.aiModelFromList,
                ),
              ),
            if (_modelsStatus != null)
              Text(
                _modelsStatus!,
                style: TextStyle(
                  color: _modelsFailed
                      ? context.colorScheme.error
                      : context.colorScheme.primary,
                ),
              ),
          ],
        ),
      ],
    );
  }

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
                            // A different provider means a different
                            // model list; the old one must not linger.
                            _models = const [];
                            _manualModel = true;
                            _modelsStatus = null;
                            _modelsFailed = false;
                          });
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _baseUrlController,
                  decoration: InputDecoration(
                    labelText: appLocalizations.aiEndpoint,
                  ),
                  keyboardType: TextInputType.url,
                  onChanged: (_) => _presetName = _matchPreset(
                    _baseUrlController.text.trim(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _apiKeyController,
                  decoration: InputDecoration(
                    labelText: appLocalizations.aiApiKey,
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 12),
                _modelField(context),
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
                        onPressed: () => globalState.openUrl(preset.keysUrl!),
                        child: Text(appLocalizations.aiGetKey),
                      ),
                      if (preset.zdrUrl != null)
                        TextButton(
                          onPressed: () => globalState.openUrl(preset.zdrUrl!),
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
