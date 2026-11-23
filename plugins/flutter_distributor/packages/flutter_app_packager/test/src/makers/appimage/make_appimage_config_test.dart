import 'package:flutter_app_packager/src/makers/appimage/make_appimage_config.dart';
import 'package:test/test.dart';

void main() {
  group('MakeAppImageConfig desktop file', () {
    test('string list keys end with a trailing semicolon', () {
      final config = MakeAppImageConfig(
        displayName: 'Angela Mihomo',
        icon: './assets/images/icon.png',
        categories: ['Network'],
        keywords: ['AngelaMihomo', 'Proxy'],
        supportedMimeTypes: ['x-scheme-handler/clash'],
        actions: [
          AppImageAction(label: 'open', name: 'Open', arguments: []),
        ],
      );
      final content = config.desktopFileContent;
      // freedesktop Desktop Entry spec: string list values must end
      // with ';'. appimagetool validates the generated file and aborts
      // the AppImage build when a list key lacks the trailing ';'.
      expect(content, contains('Categories=Network;'));
      expect(content, contains('Keywords=AngelaMihomo;Proxy;'));
      expect(content, contains('MimeType=x-scheme-handler/clash;'));
      expect(content, contains('Actions=open;'));
    });

    test('multi-value categories are semicolon joined and terminated', () {
      final config = MakeAppImageConfig(
        displayName: 'Angela Mihomo',
        icon: './assets/images/icon.png',
        categories: ['Network', 'Utility'],
      );
      expect(
        config.desktopFileContent,
        contains('Categories=Network;Utility;'),
      );
    });
  });
}
