"""Static policy checks for the Android network config and build inputs.

These guard the 2026-11 security remediation decisions:
- Android trusts system CAs only; cleartext is loopback-only.
- TempActivity stays non-exported.
- IP lookups never use plaintext HTTP endpoints.
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
    def test_no_plaintext_ip_lookup_endpoints(self):
        for rel in ('lib/common/request.dart', 'core/toolbox/speedtest.go'):
            text = read(rel)
            self.assertNotIn('ip-api.com', text, rel)
            self.assertIsNone(
                re.search(r'http://[^\s"\']*(?:ip|geo)', text), rel
            )

    def test_ip_lookup_endpoints_are_https(self):
        dart = read('lib/common/request.dart')
        for url in (
            'https://get.geojs.io/v1/ip/geo.json',
            'https://api.ip.sb/geoip',
            'https://get.geojs.io/v1/ip/geo/$ip.json',
        ):
            self.assertIn(url, dart)
        go = read('core/toolbox/speedtest.go')
        self.assertIn('https://get.geojs.io/v1/ip/geo.json', go)


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
