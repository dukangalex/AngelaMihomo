import 'dart:math';

import 'package:bett_box/common/common.dart';
import 'package:bett_box/providers/app.dart';
import 'package:bett_box/widgets/pop_scope.dart';
import 'package:bett_box/widgets/glass.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bett_box/state.dart';
import 'text.dart';

class CommonDialog extends ConsumerWidget {
  final String title;
  final Widget? titleTrailing;
  final Widget? child;
  final List<Widget>? actions;
  final EdgeInsets? padding;
  final bool overrideScroll;
  final Color? backgroundColor;

  const CommonDialog({
    super.key,
    required this.title,
    this.titleTrailing,
    this.actions,
    this.child,
    this.padding,
    this.overrideScroll = false,
    this.backgroundColor,
  });

  List<Widget>? _buildActions(BuildContext context) {
    final actions = this.actions;
    if (actions == null || actions.isEmpty) {
      return actions;
    }
    final colorScheme = context.colorScheme;
    final backgroundColor = colorScheme.primary.opacity12;
    return [
      ...actions.take(actions.length - 1),
      FilledButtonTheme(
        data: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: backgroundColor,
            foregroundColor: colorScheme.primary,
            elevation: 0,
          ),
        ),
        child: TextButtonTheme(
          data: TextButtonThemeData(
            style: TextButton.styleFrom(
              backgroundColor: backgroundColor,
              padding: const EdgeInsets.symmetric(horizontal: 24),
            ),
          ),
          child: actions.last,
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context, ref) {
    final size = ref.watch(viewSizeProvider);
    final isTv = globalState.isAndroidTV;
    final theme = Theme.of(context);
    final titleStyle = context.textTheme.titleLarge?.copyWith(
      fontSize: 19,
      fontWeight: FontWeight.w600,
    );
    final contentStyle = context.textTheme.bodyMedium?.copyWith(
      color: context.colorScheme.onSurfaceVariant,
    );
    final titleWidget = titleTrailing == null
        ? EmojiText(title)
        : Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              EmojiText(title),
              const SizedBox(width: 8),
              titleTrailing!,
            ],
          );
    final content = Theme(
      data: theme.copyWith(
        inputDecorationTheme: theme.inputDecorationTheme.copyWith(
          fillColor: theme.brightness == Brightness.light
              ? theme.colorScheme.surfaceContainer
              : null,
        ),
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: min(size.height - 40, 500),
          maxWidth: 300,
        ),
        width: size.width - 40,
        child: !overrideScroll ? SingleChildScrollView(child: child) : child,
      ),
    );
    final actions = _buildActions(context);
    return PopScope(
      canPop: !isTv,
      onPopInvokedWithResult: !isTv
          ? null
          : (didPop, result) {
              if (didPop) return;
              if (dismissTvInputFocus()) return;
              if (ModalRoute.of(context)?.isCurrent != true) return;
              Navigator.of(context).pop();
            },
      child: backgroundColor != null
          // An explicit solid background keeps the classic dialog.
          ? AlertDialog(
              title: titleWidget,
              actions: actions,
              titleTextStyle: titleStyle,
              contentTextStyle: contentStyle,
              titlePadding: const EdgeInsets.fromLTRB(22, 22, 22, 0),
              contentPadding:
                  padding ?? const EdgeInsets.fromLTRB(22, 14, 22, 18),
              actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              backgroundColor: backgroundColor,
              content: content,
            )
          : Dialog(
              backgroundColor: Colors.transparent,
              elevation: 0,
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 40,
                vertical: 24,
              ),
              clipBehavior: Clip.antiAlias,
              shape: RoundedSuperellipseBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              child: GlassSurface(
                tier: GlassTier.dialog,
                radius: 28,
                live: true,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(22, 22, 22, 0),
                      child: DefaultTextStyle(
                        style: titleStyle ?? const TextStyle(),
                        child: titleWidget,
                      ),
                    ),
                    Padding(
                      padding:
                          padding ?? const EdgeInsets.fromLTRB(22, 14, 22, 18),
                      child: DefaultTextStyle(
                        style: contentStyle ?? const TextStyle(),
                        child: content,
                      ),
                    ),
                    if (actions != null && actions.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Wrap(
                          alignment: WrapAlignment.end,
                          spacing: 8,
                          runSpacing: 8,
                          children: actions,
                        ),
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}

class CommonModal extends ConsumerWidget {
  final Widget? child;

  const CommonModal({super.key, this.child});

  @override
  Widget build(BuildContext context, ref) {
    final size = ref.watch(viewSizeProvider);
    return Center(
      child: SizedBox(
        width: size.width * 0.85,
        height: size.height * 0.85,
        child: GlassSurface(
          tier: GlassTier.dialog,
          radius: 20,
          live: true,
          child: SizedBox.expand(child: child),
        ),
      ),
    );
  }
}
