abstract class SystemInfoAPI {
  // final String platform = '';
  // final String platformVersion = '';
  // final String architecture = '';
  // final String model = '';
  // final String brand = '';
  // final String version = '';
  // final bool mobile = false;
  // final String device = '';

  bool get hasNotch;
  bool get isPWAOnIOSWithNotch;
  String get userAgent;
}
