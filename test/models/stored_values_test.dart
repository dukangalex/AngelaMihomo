import 'dart:convert';

import 'package:angelamihomo/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

/// Fresh-app doctrine (T260): stored config values are read as-is.
/// There is no migration layer rewriting stored URLs to new defaults;
/// the app's own defaults apply only when a value is absent.
Map<String, Object?> _configJson(void Function(Map<String, Object?>) edit) {
  final json =
      jsonDecode(jsonEncode(Config(themeProps: defaultThemeProps).toJson()))
          as Map<String, Object?>;
  edit(json['patchClashConfig'] as Map<String, Object?>);
  return json;
}

void main() {
  group('stored geo URLs are read as-is', () {
    test('stored values pass through unchanged, whatever they hold', () {
      final config = Config.compatibleFromJson(
        _configJson((patch) {
          patch['geox-url'] = {
            'mmdb': 'https://example.com/geoip.metadb',
            'asn':
                'https://github.com/appshubcc/bett-rules/releases/download/latest/GeoLite2-ASN.mmdb',
            'geosite':
                'https://github.com/MetaCubeX/meta-rules-dat/releases/download/latest/geosite.dat',
          };
        }),
      );
      final geo = config.patchClashConfig.geoXUrl;
      expect(geo.mmdb, 'https://example.com/geoip.metadb');
      expect(
        geo.asn,
        'https://github.com/appshubcc/bett-rules/releases/download/latest/GeoLite2-ASN.mmdb',
      );
      expect(
        geo.geosite,
        'https://github.com/MetaCubeX/meta-rules-dat/releases/download/latest/geosite.dat',
      );
    });

    test('absent values fall back to the own data repository defaults', () {
      final config = Config.compatibleFromJson(
        _configJson((patch) => patch.remove('geox-url')),
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
  });

  group('stored external-ui URL is read as-is', () {
    test('a stored value passes through unchanged', () {
      final config = Config.compatibleFromJson(
        _configJson((patch) {
          patch['external-ui-url'] =
              'https://github.com/dukangalex/angelamihomo-geo/releases/download/core-bundle-2026.11/zash.zip';
        }),
      );
      expect(
        config.patchClashConfig.externalUiUrl,
        'https://github.com/dukangalex/angelamihomo-geo/releases/download/core-bundle-2026.11/zash.zip',
      );
    });

    test('an absent external-ui URL stays unset at the model layer', () {
      // The model carries no default of its own (nullable field); the
      // current core-bundle-2026.12 default is applied at assembly
      // time. Nothing at this layer rewrites or invents a value.
      final config = Config.compatibleFromJson(
        _configJson((patch) => patch.remove('external-ui-url')),
      );
      expect(config.patchClashConfig.externalUiUrl, isNull);
    });
  });
}
