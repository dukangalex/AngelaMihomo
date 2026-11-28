import 'package:angelamihomo/common/common.dart';
import 'package:angelamihomo/enum/enum.dart';
import 'package:angelamihomo/providers/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import 'profile_info.dart';
import 'quick_options.dart';

/// The outbound-mode tile (T337): the hero-era mode readout as an
/// editable-grid tile. It shows the mode and only the mode — the
/// live delay lives in exactly one place, the hero's status pill
/// — with the running-mode status chips (TUN / VPN, system proxy)
/// as its second line, the same chips that sat in the merged
/// card's mode zone and on the start button, opening the same
/// sheets. Tapping the card opens the same outbound-mode sheet
/// the hero's mode card opened.
class OutboundModeCard extends ConsumerWidget {
  const OutboundModeCard({super.key, this.size});

  final DashboardTileSize? size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(patchClashConfigProvider.select((s) => s.mode));
    return ReadoutTileCard(
      label: appLocalizations.outboundMode,
      value: Intl.message(mode.name),
      footnote: const OutboundStatusChips(),
      onTap: () => showOutboundModeSheet(context),
    );
  }
}
