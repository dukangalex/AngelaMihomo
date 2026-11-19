import 'dart:convert';

import 'package:angelamihomo/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, Object?> _configJsonWithGeo(Map<String, String> geoXUrl) {
  final json =
      jsonDecode(
            jsonEncode(Config(themeProps: defaultThemeProps).toJson()),
          )
          as Map<String, Object?>;
  final patch = json['patchClashConfig'] as Map<String, Object?>;
  patch['geox-url'] = geoXUrl;
  return json;
}

void main() {
  group('stored geo URL migration', () {
    test('legacy mirror URLs migrate to the own data repository', () {
      final config = Config.compatibleFromJson(
        _configJsonWithGeo({
          'mmdb':
              'https://github.com/appshubcc/bett-rules/releases/download/latest/geoip.metadb',
          'asn':
              'https://github.com/appshubcc/bett-rules/releases/download/latest/GeoLite2-ASN.mmdb',
          'geosite':
              'https://github.com/appshubcc/bett-rules/releases/download/latest/geosite.dat',
        }),
      );
      final geo = config.patchClashConfig.geoXUrl;
      expect(
        geo.mmdb,
        'https://github.com/dukangalex/angelamihomo-geo/releases/download/geo-data-2026.11/geoip.metadb',
      );
      expect(
        geo.asn,
        'https://github.com/dukangalex/angelamihomo-geo/releases/download/geo-data-2026.11/ASN.mmdb',
      );
      expect(
        geo.geosite,
        'https://github.com/dukangalex/angelamihomo-geo/releases/download/geo-data-2026.11/geosite.dat',
      );
    });

    test('MetaCubeX URLs migrate to the own data repository', () {
      final config = Config.compatibleFromJson(
        _configJsonWithGeo({
          'mmdb':
              'https://github.com/MetaCubeX/meta-rules-dat/releases/download/latest/geoip.metadb',
          'asn':
              'https://github.com/MetaCubeX/meta-rules-dat/releases/download/latest/GeoLite2-ASN.mmdb',
          'geosite':
              'https://github.com/MetaCubeX/meta-rules-dat/releases/download/latest/geosite.dat',
        }),
      );
      final geo = config.patchClashConfig.geoXUrl;
      expect(
        geo.mmdb,
        'https://github.com/dukangalex/angelamihomo-geo/releases/download/geo-data-2026.11/geoip.metadb',
      );
      expect(
        geo.asn,
        'https://github.com/dukangalex/angelamihomo-geo/releases/download/geo-data-2026.11/ASN.mmdb',
      );
      expect(
        geo.geosite,
        'https://github.com/dukangalex/angelamihomo-geo/releases/download/geo-data-2026.11/geosite.dat',
      );
    });

    test('custom URLs are left untouched', () {
      final config = Config.compatibleFromJson(
        _configJsonWithGeo({
          'mmdb': 'https://example.com/geoip.metadb',
          'asn':
              'https://github.com/appshubcc/bett-rules/releases/download/latest/GeoLite2-ASN.mmdb',
          'geosite': 'https://example.com/geosite.dat',
        }),
      );
      final geo = config.patchClashConfig.geoXUrl;
      expect(geo.mmdb, 'https://example.com/geoip.metadb');
      expect(
        geo.asn,
        'https://github.com/dukangalex/angelamihomo-geo/releases/download/geo-data-2026.11/ASN.mmdb',
      );
      expect(geo.geosite, 'https://example.com/geosite.dat');
    });
  });

  group('stored external-ui URL migration', () {
    const previousDefault =
        'https://github.com/dukangalex/angelamihomo-geo/releases/download/core-bundle-2026.11/zash.zip';
    const currentDefault =
        'https://github.com/dukangalex/angelamihomo-geo/releases/download/core-bundle-2026.12/zash.zip';

    Map<String, Object?> configJsonWithUi(String url) {
      final json =
          jsonDecode(
                jsonEncode(Config(themeProps: defaultThemeProps).toJson()),
              )
              as Map<String, Object?>;
      final patch = json['patchClashConfig'] as Map<String, Object?>;
      patch['external-ui-url'] = url;
      return json;
    }

    test('the previous bundle default migrates to the current one', () {
      final config = Config.compatibleFromJson(
        configJsonWithUi(previousDefault),
      );
      expect(config.patchClashConfig.externalUiUrl, currentDefault);
    });

    test('the current default is stable', () {
      final config = Config.compatibleFromJson(
        configJsonWithUi(currentDefault),
      );
      expect(config.patchClashConfig.externalUiUrl, currentDefault);
    });

    test('a custom URL is left untouched', () {
      final config = Config.compatibleFromJson(
        configJsonWithUi('https://example.com/zash.zip'),
      );
      expect(
        config.patchClashConfig.externalUiUrl,
        'https://example.com/zash.zip',
      );
    });
  });
}
