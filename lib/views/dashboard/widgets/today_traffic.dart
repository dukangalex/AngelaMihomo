import 'dart:async';

import 'package:angelamihomo/common/common.dart';
import 'package:angelamihomo/enum/enum.dart';
import 'package:angelamihomo/models/models.dart';
import 'package:angelamihomo/pages/toolbox/traffic_stats.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'profile_info.dart';

/// The today's-traffic tile (T337): the day total the hero's
/// speed card used to pin, as an editable-grid tile. Same shared
/// query (todayTrafficProvider), same 30 s refresh cadence the
/// hero kept for it, same traffic-stats page behind the tap.
class TodayTraffic extends ConsumerStatefulWidget {
  const TodayTraffic({super.key, this.size});

  final DashboardTileSize? size;

  @override
  ConsumerState<TodayTraffic> createState() => _TodayTrafficState();
}

class _TodayTrafficState extends ConsumerState<TodayTraffic> {
  Timer? _statsTimer;

  @override
  void initState() {
    super.initState();
    // Same live cadence the traffic stats page keeps for its
    // current-day view: today's total is re-asked every 30 s.
    _statsTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      ref.invalidate(todayTrafficProvider);
    });
  }

  @override
  void dispose() {
    _statsTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final todayTraffic = ref.watch(todayTrafficProvider).value;
    return ReadoutTileCard(
      label: appLocalizations.todayTraffic,
      value: todayTraffic == null
          ? '—'
          : TrafficValue(value: todayTraffic).show,
      footnote: const SizedBox.shrink(),
      onTap: () => BaseNavigator.push(context, const TrafficStatsPage()),
    );
  }
}
