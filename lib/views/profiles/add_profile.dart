import 'package:bett_box/common/common.dart';
import 'package:bett_box/common/import_normalize.dart';
import 'package:bett_box/enum/enum.dart';
import 'package:bett_box/models/models.dart';
import 'package:bett_box/pages/scan.dart';
import 'package:bett_box/state.dart';
import 'package:bett_box/widgets/widgets.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'edit_profile.dart';
import 'tv_qr_import_dialog.dart';

class AddProfileView extends StatelessWidget {
  final BuildContext context;

  const AddProfileView({super.key, required this.context});

  Future<void> _handleAddProfileFormFile() async {
    globalState.appController.addProfileFormFile();
  }

  Future<void> _handleAddProfileFormURL(
    String url, {
    String? ageSecretKey,
  }) async {
    final editKey = GlobalKey<EditProfileViewState>();
    final profile = Profile.normal(url: url, ageSecretKey: ageSecretKey);
    showExtend(
      context,
      builder: (_, type) {
        return AdaptiveSheetScaffold(
          type: type,
          actions: [
            IconButton(
              icon: const Icon(Icons.security),
              tooltip: appLocalizations.ageKeyGenerateTitle,
              onPressed: () {
                editKey.currentState?.showAgeKeyGenerator();
              },
            ),
          ],
          body: EditProfileView(
            key: editKey,
            profile: profile,
            context: context,
            isNew: true,
          ),
          title: appLocalizations.importFromURL,
        );
      },
    );
  }

  Future<void> _handleAddProfileFromClipboard() async {
    try {
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      final text = clipboardData?.text?.trim();

      if (text == null || text.isEmpty) {
        if (context.mounted) {
          context.showSnackBar(
            appLocalizations.emptyTip(appLocalizations.clipboard),
          );
        }
        return;
      }

      if (!text.isUrl) {
        // T73: the clipboard often carries node info rather than a
        // subscription URL — import it as content instead of
        // dead-ending with a "must be a URL" tip.
        if (ImportNormalize.hasImportableContent(text)) {
          await globalState.appController.addProfileFromContent(text);
          return;
        }
        if (context.mounted) {
          context.showSnackBar(
            appLocalizations.urlTip(appLocalizations.clipboard),
          );
        }
        return;
      }

      _handleAddProfileFormURL(text);
    } catch (e) {
      if (context.mounted) {
        context.showSnackBar(e.toString());
      }
    }
  }

  Future<void> _toScan() async {
    if (system.isDesktop) {
      globalState.appController.addProfileFormQrCode();
      return;
    }
    if (globalState.isAndroidTV) {
      await showDialog(
        context: context,
        builder: (_) => const TvQrImportDialog(),
      );
      return;
    }
    final scanned = await BaseNavigator.push(context, const ScanPage());
    if (scanned == null) return;
    // T73: node QR codes carry share links, not subscription URLs —
    // import them as content instead of opening a URL form whose
    // validation would reject them.
    if (!scanned.isUrl && ImportNormalize.hasImportableContent(scanned)) {
      await globalState.appController.addProfileFromContent(scanned);
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleAddProfileFormURL(scanned);
    });
  }

  Future<void> _toAdd() async {
    _handleAddProfileFormURL('');
  }

  @override
  Widget build(context) {
    return ScrollEdgeRise(
      builder: (_, rise) => ListView(
        padding: EdgeInsets.fromLTRB(16, 12 + rise, 16, 12),
        children: [
          CommonCard(
            type: CommonCardType.filled,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListItem(
                  leading: const Icon(Icons.qr_code_sharp),
                  title: Text(appLocalizations.qrcode),
                  subtitle: Text(appLocalizations.qrcodeDesc),
                  onTap: _toScan,
                ),
                Divider(
                  height: 1,
                  thickness: 1,
                  color: context.colorScheme.outlineVariant.withValues(
                    alpha: context.colorScheme.brightness == Brightness.light
                        ? 0.6
                        : 0.45,
                  ),
                  indent: 16,
                  endIndent: 16,
                ),
                ListItem(
                  leading: const Icon(Icons.content_paste),
                  title: Text(appLocalizations.clipboard),
                  subtitle: Text(appLocalizations.clipboardDesc),
                  onTap: _handleAddProfileFromClipboard,
                ),
                Divider(
                  height: 1,
                  thickness: 1,
                  color: context.colorScheme.outlineVariant.withValues(
                    alpha: context.colorScheme.brightness == Brightness.light
                        ? 0.6
                        : 0.45,
                  ),
                  indent: 16,
                  endIndent: 16,
                ),
                ListItem(
                  leading: const Icon(Icons.upload_file_sharp),
                  title: Text(appLocalizations.file),
                  subtitle: Text(appLocalizations.fileDesc),
                  onTap: _handleAddProfileFormFile,
                ),
                Divider(
                  height: 1,
                  thickness: 1,
                  color: context.colorScheme.outlineVariant.withValues(
                    alpha: context.colorScheme.brightness == Brightness.light
                        ? 0.6
                        : 0.45,
                  ),
                  indent: 16,
                  endIndent: 16,
                ),
                ListItem(
                  leading: const Icon(Icons.cloud_download_sharp),
                  title: Text(appLocalizations.url),
                  subtitle: Text(appLocalizations.urlDesc),
                  onTap: _toAdd,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
