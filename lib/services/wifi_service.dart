// lib/services/wifi_service.dart
import 'package:wifi_iot/wifi_iot.dart';

class WifiService {
  Future<bool> connectToEsp32() async {
    return await WiFiForIoTPlugin.connect(
      'ESP32_SSID',
      password: 'password',
      joinOnce: false,
      security: NetworkSecurity.WPA,
    );
  }

  Future<String?> getCurrentSSID() async {
    return await WiFiForIoTPlugin.getSSID();
  }

  Future<String?> getCurrentIP() async {
    return await WiFiForIoTPlugin.getIP();
  }
}