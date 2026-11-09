import 'package:bett_box/common/common.dart';
import 'package:bett_box/state.dart';
import 'package:bett_box/widgets/dialog.dart';
import 'package:material_ui/material_ui.dart';

/// T75: minimal unified form for *implicit* secondary explanations.
///
/// Setting rows stay clean by default (no flat-laid description text); the
/// explanation is hidden behind this small info marker and only expands when
/// the user taps it. New capability entries should pass their (sourced)
/// explanation text here instead of adding a permanent subtitle.
class InfoHintButton extends StatelessWidget {
  final String title;
  final String message;

  const InfoHintButton({super.key, required this.title, required this.message});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkResponse(
        radius: 16,
        highlightShape: BoxShape.circle,
        onTap: () {
          globalState.showCommonDialog(
            child: CommonDialog(
              title: title,
              child: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(message),
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(7),
          child: Icon(
            Icons.info_outline,
            size: 18,
            color: context.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

/// A setting row title with an implicit-explanation marker attached, matching
/// the title-row pattern already used on the general settings page.
class InfoTitle extends StatelessWidget {
  final String text;
  final String info;

  const InfoTitle({super.key, required this.text, required this.info});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(child: Text(text)),
        InfoHintButton(title: text, message: info),
      ],
    );
  }
}
