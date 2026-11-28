import 'package:angelamihomo/common/common.dart';
import 'package:angelamihomo/enum/enum.dart';
import 'package:angelamihomo/models/models.dart';
import 'package:angelamihomo/providers/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'profile_info.dart';

/// The subscription-remaining tile (T337): the days-left readout
/// the hero's speed card used to pin, as an editable-grid tile —
/// the shared presentation helper (three-band threshold colours,
/// T292) over the current profile's usage, with the plan's own
/// expiry text as the second line.
class SubscriptionRemaining extends ConsumerWidget {
  const SubscriptionRemaining({super.key, this.size});

  final DashboardTileSize? size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider);
    final usage = profile == null ? null : ProfileUsage.of(profile);
    final presentation = subscriptionRemainingPresentation(context, usage);
    return ReadoutTileCard(
      label: appLocalizations.subscriptionRemaining,
      value: presentation.text,
      valueColor: presentation.color,
      footnote: Text(
        usage?.expireText ?? '',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: context.textTheme.bodySmall?.copyWith(
          color: context.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
