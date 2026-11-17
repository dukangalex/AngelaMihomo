import 'package:angelamihomo/common/common.dart';
import 'package:angelamihomo/providers/config.dart';
import 'package:angelamihomo/widgets/widgets.dart';
import 'package:angelamihomo/views/config/sniffer.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SnifferOverride extends StatelessWidget {
  const SnifferOverride({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: getWidgetHeight(context, 1),
      child: CommonCard(
        info: Info(label: 'Sniffer', iconData: Icons.radar),
        onPressed: () {
          // Open Sniffer settings
          showExtend(
            context,
            builder: (_, type) {
              return AdaptiveSheetScaffold(
                type: type,
                title: appLocalizations.sniffer,
                body: const SnifferListView(),
              );
            },
            props: const ExtendProps(blur: false),
          );
        },
        child: Container(
          padding: baseInfoEdgeInsets.copyWith(top: 4, bottom: 8, right: 8),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                flex: 1,
                child: TooltipText(
                  text: Text(
                    appLocalizations.override,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(
                      context,
                    ).textTheme.titleSmall?.adjustSize(-2).toLight,
                  ),
                ),
              ),
              Consumer(
                builder: (_, ref, _) {
                  final override = ref.watch(overrideSnifferProvider);
                  return Switch(
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    value: override,
                    onChanged: (value) {
                      ref.read(overrideSnifferProvider.notifier).value = value;
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
