"""Static policy checks for the Android network config and build inputs.

These guard the 2026-11 security remediation decisions:
- Android trusts system CAs only; cleartext is loopback-only.
- TempActivity stays non-exported.
- IP geo enrichment is fully local (on-device mmdb databases via the
  queryIpGeo bridge). No online geo service may be referenced anywhere
  in the lookup path; exit IP discovery is limited to Cloudflare's
  official trace echo, which sees nothing beyond the exit IP itself.
- Dead telemetry/token build defines (SENTRY_DSN, IPINFO_TOKEN) stay removed:
  nothing in the app consumed them, so they must not be embedded in artifacts.
"""
import re
import unittest
import xml.etree.ElementTree as ET
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
ANDROID_NS = '{http://schemas.android.com/apk/res/android}'


def read(rel):
    return (ROOT / rel).read_text(encoding='utf-8')


class NetworkSecurityConfigTest(unittest.TestCase):
    def setUp(self):
        self.config = ET.parse(
            ROOT / 'android/app/src/main/res/xml/network_security_config.xml'
        ).getroot()

    def test_base_config_trusts_system_ca_only(self):
        base = self.config.find('base-config')
        self.assertIsNotNone(base)
        sources = {
            cert.get('src')
            for cert in base.iter('certificates')
        }
        self.assertEqual(sources, {'system'})

    def test_cleartext_only_for_loopback(self):
        domains = set()
        for domain_config in self.config.iter('domain-config'):
            self.assertEqual(
                domain_config.get('cleartextTrafficPermitted'), 'true'
            )
            domains.update(d.text.strip() for d in domain_config.iter('domain'))
        self.assertLessEqual(domains, {'localhost', '127.0.0.1'})
        self.assertNotIn('ip-api.com', domains)


class ManifestPolicyTest(unittest.TestCase):
    def test_temp_activity_not_exported(self):
        manifest = ET.parse(
            ROOT / 'android/app/src/main/AndroidManifest.xml'
        ).getroot()
        for activity in manifest.iter('activity'):
            if activity.get(f'{ANDROID_NS}name') == '.TempActivity':
                self.assertEqual(
                    activity.get(f'{ANDROID_NS}exported'), 'false'
                )
                return
        self.fail('TempActivity not found in manifest')


class IpLookupTransportTest(unittest.TestCase):
    # Every file that participates in IP detection / geo display. Online
    # geo providers must not reappear in any of them.
    GEO_SURFACE_FILES = (
        'lib/common/request.dart',
        'lib/models/common.dart',
        'lib/pages/speed_test.dart',
        'lib/widgets/ip_detail_dialog.dart',
        'lib/views/dashboard/widgets/network_detection.dart',
        'core/toolbox/speedtest.go',
        'core/hub.go',
    )
    FORBIDDEN_GEO_ENDPOINTS = (
        'geojs.io',
        'ip.sb',
        'ip-api',
        'ipip.net',
        'uapis.cn',
        'ip2location',
        'qualcomm.cn',
        'teamviewer.cn',
    )

    def test_no_online_geo_endpoints(self):
        for rel in self.GEO_SURFACE_FILES:
            text = read(rel)
            for endpoint in self.FORBIDDEN_GEO_ENDPOINTS:
                self.assertNotIn(endpoint, text, f'{endpoint} in {rel}')
            self.assertIsNone(
                re.search(r'http://[^\s"\']*(?:ip|geo)', text), rel
            )

    def test_exit_ip_echo_is_cloudflare_trace_only(self):
        for rel in ('lib/common/request.dart', 'core/toolbox/speedtest.go'):
            text = read(rel)
            self.assertIn('https://cloudflare.com/cdn-cgi/trace', text, rel)

    def test_local_geo_lookup_path_exists(self):
        # Dart bridge -> Go bridge -> local mmdb assembly -> resources UI.
        self.assertIn('queryIpGeo', read('lib/common/request.dart'))
        self.assertIn('queryIpGeo', read('lib/clash/core.dart'))
        self.assertIn('handleQueryIpGeo', read('core/hub.go'))
        self.assertIn('LookupGeo', read('core/toolbox/speedtest.go'))
        self.assertIn('"CITY"', read('core/hub.go'))
        self.assertIn("key: 'city'", read('lib/views/resources.dart'))
        self.assertIn('DB-IP', read('lib/views/resources.dart'))


class DeadTelemetryDefineTest(unittest.TestCase):
    def test_dead_defines_not_injected(self):
        for rel in (
            '.github/workflows/build.yaml',
            'setup.dart',
            'lib/common/constant.dart',
        ):
            text = read(rel)
            self.assertNotIn('SENTRY_DSN', text, rel)
            self.assertNotIn('IPINFO_TOKEN', text, rel)
            self.assertNotIn('ipInfoToken', text, rel)


if __name__ == '__main__':
    unittest.main()
