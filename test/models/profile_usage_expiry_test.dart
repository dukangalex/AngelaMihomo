import 'package:angelamihomo/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

/// T334 batch 2: the frozen expiry threshold table the home
/// readouts colour by — more than 30 days is a plain fact, the
/// last month is a reminder, the last week is a warning.
void main() {
  test('expiryWarningLevel thresholds', () {
    expect(expiryWarningLevel(365), ExpiryWarningLevel.normal);
    expect(expiryWarningLevel(31), ExpiryWarningLevel.normal);
    expect(expiryWarningLevel(30), ExpiryWarningLevel.reminder);
    expect(expiryWarningLevel(8), ExpiryWarningLevel.reminder);
    expect(expiryWarningLevel(7), ExpiryWarningLevel.warning);
    expect(expiryWarningLevel(1), ExpiryWarningLevel.warning);
    expect(expiryWarningLevel(0), ExpiryWarningLevel.warning);
  });
}
