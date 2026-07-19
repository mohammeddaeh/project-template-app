import 'package:flutter_test/flutter_test.dart';
import 'package:app_template/core/platform/config/app_settings.dart';

void main() {
  test('bloc observer logger is disabled by default', () {
    expect(AppSettings.enableBlocObserverLogger, isFalse);
  });
}
