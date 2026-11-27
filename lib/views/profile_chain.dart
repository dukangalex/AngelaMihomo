import 'package:angelamihomo/clash/core.dart';
import 'package:angelamihomo/common/chain_health.dart';
import 'package:angelamihomo/common/path_score.dart';
import 'package:angelamihomo/common/common.dart';
import 'package:angelamihomo/common/profile_chain.dart';
import 'package:angelamihomo/models/models.dart';
import 'package:angelamihomo/providers/providers.dart';
import 'package:angelamihomo/state.dart';
import 'package:angelamihomo/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProfileChainPage extends ConsumerStatefulWidget {
  final Profile profile;

  const ProfileChainPage({super.key, required this.profile});

  @override
  ConsumerState<ProfileChainPage> createState() => _ProfileChainPageState();
}

class _ChainChoice {
  final ChainTargetKind kind;
  final String name;

  const _ChainChoice(this.kind, this.name);

  String get key => chainTargetKey(kind, name);
}

class _ChainProfileChoices {
  final Profile profile;
  final List<_ChainChoice> choices;

  const _ChainProfileChoices(this.profile, this.choices);
}

class _ProfileChainPageState extends ConsumerState<ProfileChainPage> {
  var _ready = false;
  var _saving = false;

  String? _error;
  Map<String, _ChainProfileChoices> _byProfile = {};
  List<Profile> _profiles = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  String _kindLabel(ChainTargetKind kind) => switch (kind) {
    ChainTargetKind.proxy => appLocalizations.chainTargetProxy,
    ChainTargetKind.group => appLocalizations.chainTargetGroup,
  };

  String _choiceLabel(_ChainChoice choice) =>
      '${_kindLabel(choice.kind)} · ${choice.name}';

  Future<void> _load() async {
    await ProfileChainStore.instance.ensureLoaded();
    final profiles = [...globalState.config.profiles];
    if (!profiles.any((item) => item.id == widget.profile.id)) {
      profiles.add(widget.profile);
    }
    final options = <String, _ChainProfileChoices>{};
    for (final profile in profiles) {
      try {
        final raw = await globalState.getProfileConfig(
          profile.id,
          effective: true,
        );
        options[profile.id] = _ChainProfileChoices(
          profile,
          _choicesFromConfig(raw),
        );
      } catch (_) {
        // An unavailable profile remains visible as a source choice, but has
        // no targets; it is never silently replaced with another profile.
        options[profile.id] = _ChainProfileChoices(profile, const []);
      }
    }
    final current = globalState.config.currentProfile?.id == widget.profile.id;
    if (current && globalState.isStart) {
      try {
        final groups = await clashCore.getProxiesGroups();
        final existing = options[widget.profile.id]?.choices ?? const [];
        final all = [...existing];
        for (final group in groups) {
          for (final proxy in group.all) {
            if (!isLeafPath(proxy.type) ||
                reservedPathNames.contains(proxy.name)) {
              continue;
            }
            if (!all.any(
              (choice) =>
                  choice.kind == ChainTargetKind.proxy &&
                  choice.name == proxy.name,
            )) {
              all.add(_ChainChoice(ChainTargetKind.proxy, proxy.name));
            }
          }
        }
        options[widget.profile.id] = _ChainProfileChoices(widget.profile, all);
      } catch (_) {}
    }
    if (!mounted) return;
    setState(() {
      _profiles = profiles;
      _byProfile = options;
      _ready = true;
    });
  }

  // The extraction rules live in common/chain_health.dart so the chain
  // page's choice lists and the profile-card health projection read the
  // same definition of what exists in a profile.
  List<_ChainChoice> _choicesFromConfig(Map<String, dynamic> config) => [
    for (final target in chainTargetsOf(config))
      _ChainChoice(target.kind, target.name),
  ];

  Map<String, Set<String>> get _landingTargetsByProfile => {
    for (final entry in _byProfile.entries)
      entry.key: {for (final choice in entry.value.choices) choice.key},
  };

  Set<String> get _entryKeys => {
    for (final choice in _byProfile[widget.profile.id]?.choices ?? const [])
      choice.key,
  };

  /// The chain has exactly one exit (T310: the user's clarification that
  /// choice belongs in the generated landing group, not in extra exits
  /// configured here). Stored lists keep only their first entry in effect.
  ChainLanding? _exitLanding(ProfileChain chain) =>
      chain.landings.isEmpty ? null : chain.landings.first;

  String _exitProfileId(ProfileChain chain) =>
      _exitLanding(chain)?.resolvedProfileId(widget.profile.id) ??
      widget.profile.id;

  ProfileChainIssue? get _currentIssue => ProfileChainStore.instance
      .of(widget.profile.id)
      .selectionIssue(
        currentProfileId: widget.profile.id,
        entryTargets: _entryKeys,
        landingTargetsByProfile: _landingTargetsByProfile,
      );

  String _issueMessage(ProfileChainIssue issue) => switch (issue) {
    ProfileChainIssue.incomplete => appLocalizations.chainIssueIncomplete,
    ProfileChainIssue.sameNode => appLocalizations.chainIssueSameNode,
    ProfileChainIssue.otherProfileRequired =>
      appLocalizations.chainIssueOtherProfile,
    ProfileChainIssue.unavailable => appLocalizations.chainIssueUnavailable,
  };

  Future<void> _commit(ProfileChain candidate) async {
    if (_saving) return;
    final issue = candidate.selectionIssue(
      currentProfileId: widget.profile.id,
      entryTargets: _entryKeys,
      landingTargetsByProfile: _landingTargetsByProfile,
    );
    if (issue != null) {
      setState(() => _error = _issueMessage(issue));
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final store = ProfileChainStore.instance;
    final previous = store.of(widget.profile.id);
    try {
      if (candidate.enabled) {
        final setup = await globalState.buildSetupParams(
          patchConfig: globalState.config.patchClashConfig,
          profile: widget.profile,
          chainOverride: candidate,
        );
        final message = await clashCore.validateConfig('', setup: setup);
        if (message.isNotEmpty) throw message;
      }
      // Do not replace the last saved choice on validation or storage failure.
      store.byProfile[widget.profile.id] = candidate;
      try {
        await store.save();
      } catch (_) {
        store.byProfile[widget.profile.id] = previous;
        rethrow;
      }
      // The saved selection changed: the profile cards' chain health
      // markers (T152) must be recomputed against it.
      ref.invalidate(chainCardHealthProvider);
      if (globalState.config.currentProfile?.id == widget.profile.id) {
        globalState.appController.applyProfileDebounce();
      }
    } on Object catch (error) {
      if (mounted) setState(() => _error = failureNoticeOf(error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// Replace the single exit and commit. Any extra stored exits from
  /// the T303 multi-exit layout are dropped here: only the first exit
  /// was ever in effect under T310, and saving makes that explicit.
  void _commitLanding(ProfileChain chain, ChainLanding landing) {
    _commit(chain.copyWith(landings: [landing]));
  }

  ListItem<String> _targetItem({
    required String title,
    required ChainTargetKind selectedKind,
    required String selectedName,
    required List<_ChainChoice> choices,
    required void Function(_ChainChoice choice) onChanged,
    required String unavailableHint,
  }) {
    final keys = [for (final choice in choices) choice.key];
    final currentKey = chainTargetKey(selectedKind, selectedName);
    final valid = keys.contains(currentKey);
    final options = List<String>.unmodifiable(keys);
    final value = valid ? currentKey : (options.isEmpty ? '' : options.first);
    final labels = {
      for (final choice in choices) choice.key: _choiceLabel(choice),
    };
    return ListItem<String>.options(
      title: Text(title),
      subtitle: Text(
        selectedName.isEmpty
            ? appLocalizations.chainChooseTarget
            : valid
            ? _choiceLabel(_ChainChoice(selectedKind, selectedName))
            : '$selectedName · $unavailableHint',
      ),
      delegate: OptionsDelegate<String>(
        title: title,
        options: options,
        value: value,
        textBuilder: (key) => labels[key] ?? key,
        onChanged: (key) {
          if (_saving || key == null || key.isEmpty) return;
          final choice = choices.firstWhere((item) => item.key == key);
          onChanged(choice);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chain = ProfileChainStore.instance.of(widget.profile.id);
    final label = widget.profile.label ?? widget.profile.id;
    final entryChoices = _byProfile[widget.profile.id]?.choices ?? const [];
    final exitProfiles = _profiles
        .where((profile) => profile.id != widget.profile.id)
        .toList(growable: false);
    final editing = _exitLanding(chain);
    final editingProfileId = _exitProfileId(chain);
    final selectedExitProfileId =
        exitProfiles.any((profile) => profile.id == editingProfileId)
        ? editingProfileId
        : '';
    final landingProfile = selectedExitProfileId.isEmpty
        ? null
        : _byProfile[selectedExitProfileId];
    final landingChoices = landingProfile?.choices ?? const [];
    final issue = _currentIssue;
    return CommonScaffold(
      title: appLocalizations.chainTitle,
      body: !_ready
          ? const Center(child: CircularProgressIndicator())
          : generateListView(
              generateSection(
                title: label,
                items: [
                  ListItem.switchItem(
                    title: Text(appLocalizations.chainEnable),
                    subtitle: Text(appLocalizations.chainEnableDesc),
                    delegate: SwitchDelegate(
                      value: chain.enabled,
                      onChanged: _saving
                          ? null
                          : (on) => _commit(chain.copyWith(enabled: on)),
                    ),
                  ),
                  if (_error != null || issue != null)
                    ListItem(
                      title: Text(appLocalizations.chainAttention),
                      subtitle: Text(
                        _error ?? _issueMessage(issue!),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  ListItem(
                    title: Text(appLocalizations.tip),
                    subtitle: Text(appLocalizations.chainExitScriptHint),
                  ),
                  if (entryChoices.isEmpty)
                    ListItem(
                      title: Text(appLocalizations.chainNoEntry),
                      subtitle: Text(appLocalizations.chainNoEntryDesc),
                    )
                  else
                    _targetItem(
                      title: appLocalizations.chainEntry,
                      selectedKind: chain.entryKind,
                      selectedName: chain.entry,
                      choices: entryChoices,
                      unavailableHint: appLocalizations.chainNotInProfile,
                      onChanged: (choice) {
                        _commit(
                          chain.copyWith(
                            entry: choice.name,
                            entryKind: choice.kind,
                          ),
                        );
                      },
                    ),
                  if (exitProfiles.isNotEmpty)
                    ListItem<String>.options(
                      title: Text(appLocalizations.chainExitProfile),
                      subtitle: Text(
                        landingProfile?.profile.label ??
                            landingProfile?.profile.id ??
                            appLocalizations.chainChooseOtherProfile,
                      ),
                      delegate: OptionsDelegate<String>(
                        title: appLocalizations.chainExitProfile,
                        options: [
                          '',
                          for (final profile in exitProfiles) profile.id,
                        ],
                        value: selectedExitProfileId,
                        textBuilder: (id) {
                          if (id.isEmpty) {
                            return appLocalizations.chainChooseOtherProfile;
                          }
                          final profile = exitProfiles.firstWhere(
                            (item) => item.id == id,
                          );
                          return profile.label ?? profile.id;
                        },
                        onChanged: (profileId) {
                          if (_saving ||
                              profileId == null ||
                              profileId.isEmpty) {
                            return;
                          }
                          final choices =
                              _byProfile[profileId]?.choices ?? const [];
                          final current = editing;
                          final existing = current != null && choices.any(
                            (choice) =>
                                choice.kind == current.kind &&
                                choice.name == current.name,
                          );
                          final next = existing
                              ? choices.firstWhere(
                                  (choice) =>
                                      choice.kind == current.kind &&
                                      choice.name == current.name,
                                )
                              : (choices.isEmpty ? null : choices.first);
                          if (next == null) {
                            setState(
                              () => _error = appLocalizations.chainNoExits,
                            );
                            return;
                          }
                          _commitLanding(
                            chain,
                            ChainLanding(
                              profileId: profileId,
                              kind: next.kind,
                              name: next.name,
                            ),
                          );
                        },
                      ),
                    ),
                  if (exitProfiles.isEmpty)
                    ListItem(
                      title: Text(appLocalizations.chainNoOtherProfiles),
                      subtitle: Text(appLocalizations.chainNoOtherProfilesDesc),
                    ),
                  if (landingChoices.isEmpty)
                    ListItem(
                      title: Text(appLocalizations.chainNoExitChoices),
                      subtitle: Text(appLocalizations.chainNoExitChoicesDesc),
                    )
                  else
                    _targetItem(
                      title: appLocalizations.chainExit,
                      selectedKind: editing?.kind ?? ChainTargetKind.proxy,
                      selectedName: editing?.name ?? '',
                      choices: landingChoices,
                      unavailableHint:
                          appLocalizations.chainNotInSelectedProfile,
                      onChanged: (choice) {
                        _commitLanding(
                          chain,
                          ChainLanding(
                            profileId: selectedExitProfileId,
                            kind: choice.kind,
                            name: choice.name,
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
    );
  }
}
