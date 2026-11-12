import 'package:bett_box/clash/clash.dart';
import 'package:bett_box/common/common.dart';
import 'package:bett_box/models/models.dart';
import 'package:bett_box/widgets/widgets.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'common.dart';

enum _AgeKeyType {
  x25519('X25519'),
  hybrid('MLKEM768-X25519');

  final String label;

  const _AgeKeyType(this.label);
}

class AgeToolPage extends ConsumerStatefulWidget {
  const AgeToolPage({super.key});

  @override
  ConsumerState<AgeToolPage> createState() => _AgeToolPageState();
}

class _AgeToolPageState extends ConsumerState<AgeToolPage> {
  _AgeKeyType _keyType = _AgeKeyType.x25519;
  final _secretController = TextEditingController();
  final _publicController = TextEditingController();
  String _error = '';
  bool _showSecret = false;

  @override
  void dispose() {
    _secretController.dispose();
    _publicController.dispose();
    super.dispose();
  }

  void _copy(String text) {
    if (text.isEmpty) return;
    Clipboard.setData(ClipboardData(text: text));
    context.showNotifier(appLocalizations.copySuccess);
  }

  Future<void> _generate() async {
    final pair = await clashCore.generateAgeKeyPair(
      hybrid: _keyType == _AgeKeyType.hybrid,
    );
    if (!mounted) return;
    setState(() {
      _secretController.text = pair['secret-key'] ?? '';
      _publicController.text = pair['public-key'] ?? '';
      _error = '';
    });
  }

  Future<void> _derive() async {
    final secret = _secretController.text.trim();
    if (secret.isEmpty) {
      setState(() => _error = appLocalizations.agePrivateKeyRequired);
      return;
    }
    final result = await clashCore.convertAgeSecretKeyToPublicKey(secret);
    if (!mounted) return;
    setState(() {
      if (result.isError) {
        _error = appLocalizations.agePrivateKeyRequired;
      } else {
        _publicController.text = result.data ?? '';
        _keyType = secret.startsWith('AGE-SECRET-KEY-PQ-')
            ? _AgeKeyType.hybrid
            : _AgeKeyType.x25519;
        _error = '';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return CommonScaffold(
      title: appLocalizations.ageTool,
      body: ToolPageBody(
        children: [
          ToolSurface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  appLocalizations.ageKeyType,
                  style: context.textTheme.labelMedium?.copyWith(
                    color: context.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                ToolSegmented<_AgeKeyType>(
                  values: _AgeKeyType.values,
                  value: _keyType,
                  labelOf: (type) => type.label,
                  onChanged: (type) => setState(() => _keyType = type),
                ),
                if (_keyType == _AgeKeyType.hybrid) ...[
                  const SizedBox(height: 10),
                  ToolNote(
                    icon: Icons.info_outline_rounded,
                    text: appLocalizations.ageKeyHybridTip,
                    color: context.colorScheme.tertiary,
                  ),
                ],
                const SizedBox(height: 16),
                ToolTvField(
                  controller: _secretController,
                  child: TextField(
                    controller: _secretController,
                    obscureText: !_showSecret,
                    autocorrect: false,
                    decoration: InputDecoration(
                      labelText: appLocalizations.agePrivateKeyLabel,
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: () =>
                                setState(() => _showSecret = !_showSecret),
                            icon: Icon(
                              _showSecret
                                  ? Icons.visibility_off_rounded
                                  : Icons.visibility_rounded,
                              size: 18,
                            ),
                          ),
                          _copyButton(() => _secretController.text),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ToolTvField(
                  controller: _publicController,
                  child: TextField(
                    controller: _publicController,
                    readOnly: true,
                    minLines: 1,
                    maxLines: 4,
                    style: _keyType == _AgeKeyType.hybrid
                        ? context.textTheme.bodySmall?.copyWith(
                            fontFamily: 'monospace',
                          )
                        : null,
                    decoration: InputDecoration(
                      labelText: appLocalizations.agePublicKeyLabel,
                      suffixIcon: _copyButton(() => _publicController.text),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.icon(
                      onPressed: _generate,
                      icon: const Icon(Icons.key_rounded, size: 18),
                      label: Text(appLocalizations.ageGenerateKeyPair),
                    ),
                    OutlinedButton.icon(
                      onPressed: _derive,
                      icon: const Icon(Icons.sync_alt_rounded, size: 18),
                      label: Text(appLocalizations.generateFromPrivateKey),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (_error.isNotEmpty) ...[
            const SizedBox(height: 12),
            ToolNote(
              icon: Icons.error_outline_rounded,
              text: _error,
              color: context.colorScheme.error,
            ),
          ],
          const SizedBox(height: 12),
          ToolNote(
            icon: Icons.shield_outlined,
            text: appLocalizations.ageToolTip,
          ),
        ],
      ),
    );
  }

  Widget _copyButton(String Function() text) => IconButton(
    tooltip: appLocalizations.copy,
    onPressed: () => _copy(text()),
    icon: const Icon(Icons.copy_rounded, size: 18),
  );
}
