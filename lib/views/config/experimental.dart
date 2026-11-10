import 'package:bett_box/common/common.dart';
import 'package:bett_box/providers/config.dart';
import 'package:bett_box/widgets/widgets.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// T81 batch 3 (P-2): the OverrideExperimentalItem gate switch is
// gone — the experimental section is unconditionally App-owned.

class QuicGoDisableGsoItem extends ConsumerWidget {
  const QuicGoDisableGsoItem({super.key});

  @override
  Widget build(BuildContext context, ref) {
    final value = ref.watch(
      patchClashConfigProvider.select(
        (state) => state.experimental.quicGoDisableGso,
      ),
    );
    return ListItem.switchItem(
      title: Text(appLocalizations.quicGoDisableGso),
      delegate: SwitchDelegate(
        value: value,
        onChanged: (bool newValue) async {
          ref
              .read(patchClashConfigProvider.notifier)
              .updateState(
                (state) => state.copyWith(
                  experimental: state.experimental.copyWith(
                    quicGoDisableGso: newValue,
                  ),
                ),
              );
        },
      ),
    );
  }
}

class QuicGoDisableEcnItem extends ConsumerWidget {
  const QuicGoDisableEcnItem({super.key});

  @override
  Widget build(BuildContext context, ref) {
    final value = ref.watch(
      patchClashConfigProvider.select(
        (state) => state.experimental.quicGoDisableEcn,
      ),
    );
    return ListItem.switchItem(
      title: Text(appLocalizations.quicGoDisableEcn),
      delegate: SwitchDelegate(
        value: value,
        onChanged: (bool newValue) async {
          ref
              .read(patchClashConfigProvider.notifier)
              .updateState(
                (state) => state.copyWith(
                  experimental: state.experimental.copyWith(
                    quicGoDisableEcn: newValue,
                  ),
                ),
              );
        },
      ),
    );
  }
}

class DialerIp4pConvertItem extends ConsumerWidget {
  const DialerIp4pConvertItem({super.key});

  @override
  Widget build(BuildContext context, ref) {
    final value = ref.watch(
      patchClashConfigProvider.select(
        (state) => state.experimental.dialerIp4pConvert,
      ),
    );
    return ListItem.switchItem(
      title: Text(appLocalizations.dialerIp4pConvert),
      delegate: SwitchDelegate(
        value: value,
        onChanged: (bool newValue) async {
          ref
              .read(patchClashConfigProvider.notifier)
              .updateState(
                (state) => state.copyWith(
                  experimental: state.experimental.copyWith(
                    dialerIp4pConvert: newValue,
                  ),
                ),
              );
        },
      ),
    );
  }
}

final experimentalItems = <Widget>[
  ...generateSection(
    title: appLocalizations.options,
    items: const [
      QuicGoDisableGsoItem(),
      QuicGoDisableEcnItem(),
      DialerIp4pConvertItem(),
    ],
  ),
];

class ExperimentalListView extends ConsumerWidget {
  const ExperimentalListView({super.key});

  @override
  Widget build(BuildContext context, ref) {
    return generateListView(experimentalItems);
  }
}
