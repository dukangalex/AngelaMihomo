import 'package:bett_box/models/common.dart';
import 'package:bett_box/views/dashboard/widgets/network_detection.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('T103 卡面归属行', () {
    test('本地查得城市时：国家 · 城市，ASN 在后', () {
      final info = IpInfo(
        ip: '203.0.113.7',
        countryCode: 'US',
        country: 'United States',
        province: 'Colorado',
        city: 'Boulder (Downtown)',
        asn: 'AS8796',
        asName: 'FASTNET DATA INC',
      );
      expect(
        networkDetectionLocationText(info),
        'United States · Boulder (Downtown)',
      );
      expect(networkDetectionOperatorText(info), 'AS8796 FASTNET DATA INC');
    });

    test('无城市数据时不留空位：只有国家', () {
      final info = IpInfo(ip: '203.0.113.7', countryCode: 'US');
      expect(networkDetectionLocationText(info), '');
      expect(networkDetectionOperatorText(info), '');
    });

    test('城市与国家同名不重复显示', () {
      final info = IpInfo(
        ip: '203.0.113.7',
        countryCode: 'SG',
        country: 'Singapore',
        city: 'Singapore',
      );
      expect(networkDetectionLocationText(info), 'Singapore');
    });
  });
}
