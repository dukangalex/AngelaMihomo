import 'package:bett_box/common/common.dart';
import 'package:bett_box/state.dart';
import 'package:bett_box/widgets/dialog.dart';
import 'package:bett_box/widgets/input.dart';
import 'package:material_ui/material_ui.dart';

/// T84: the one preset/custom URL picker shared by the global test-URL
/// setting (常规页「测试链接」) and the per-group health-check URL editor
/// (组编辑器「健康检查地址」) — single spec: one preset list
/// ([presetTestUrls]) and one picker widget, never a second copy.
///
/// Callers differ only in persistence and context extras:
/// [onSelected] writes wherever the caller's context needs (the global
/// `testUrl` setting vs the group's `groupOverrides.url`), and
/// context-only extras such as the global "override config" switch are
/// passed in as [header] — group contexts pass no header, so no
/// global-only switch leaks into the group editor.
class TestUrlPickerDialog extends StatelessWidget {
  /// Dialog title (「测试链接」 in the global context, 「健康检查地址」
  /// in the group context).
  final String title;

  /// The URL currently in effect; echoed as the selected row on open
  /// (a preset row, or the custom row when it matches no preset).
  final String currentUrl;

  /// Field name used in the custom-input validation messages.
  final String fieldLabel;

  /// Value offered by the custom input's reset action; null hides it.
  /// The global context passes [defaultTestUrl]; the group context
  /// passes the subscription's own URL (restore-to-subscription).
  final String? customResetValue;

  /// Optional section rendered above the preset list.
  final Widget? header;

  /// Called with the chosen URL (preset tap, or a valid custom input).
  /// Invoked before this dialog pops itself for preset selections, and
  /// after it pops for custom input — implementations must not rely on
  /// this dialog still being mounted.
  final ValueChanged<String> onSelected;

  const TestUrlPickerDialog({
    super.key,
    required this.title,
    required this.currentUrl,
    required this.fieldLabel,
    required this.onSelected,
    this.customResetValue,
    this.header,
  });

  @override
  Widget build(BuildContext context) {
    final isPresetUrl = presetTestUrls.contains(currentUrl);
    final header = this.header;
    return CommonDialog(
      title: title,
      padding: const EdgeInsets.fromLTRB(10, 12, 10, 14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (header != null) ...[header, const SizedBox(height: 8)],
          for (final url in presetTestUrls)
            OptionItem(
              text: url,
              selected: currentUrl == url,
              onTap: () {
                onSelected(url);
                Navigator.of(context, rootNavigator: true).pop();
              },
            ),
          OptionItem(
            text: appLocalizations.customUrl,
            selected: !isPresetUrl,
            onTap: () async {
              Navigator.of(context, rootNavigator: true).pop();
              final customUrl = await globalState.showCommonDialog<String>(
                child: InputDialog(
                  title: appLocalizations.customUrl,
                  value: isPresetUrl ? '' : currentUrl,
                  resetValue: customResetValue,
                  validator: (String? inputValue) {
                    if (inputValue == null || inputValue.isEmpty) {
                      return appLocalizations.emptyTip(fieldLabel);
                    }
                    if (!inputValue.isHttpUrl) {
                      return appLocalizations.urlTip(fieldLabel);
                    }
                    return null;
                  },
                ),
              );
              if (customUrl != null) {
                onSelected(customUrl);
              }
            },
          ),
        ],
      ),
    );
  }
}
