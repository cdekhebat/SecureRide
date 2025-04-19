// lib/controllers/esp32_controller.dart
import 'package:flutter/material.dart';
import '../services/bluetooth_service.dart';
import '../services/wifi_service.dart';

class ESP32Controller with ChangeNotifier {
  final BluetoothService _bluetoothService = BluetoothService();
  final WifiService _wifiService = WifiService();

  bool _isConnected = false;
  String _connectionStatus = 'Disconnected';
  String _wifiName = '';
  String _wifiIP = '';
  bool _isConnecting = false;

  // Getters
  bool get isConnected => _isConnected;
  String get connectionStatus => _connectionStatus;
  String get wifiName => _wifiName;
  String get wifiIP => _wifiIP;
  bool get isConnecting => _isConnecting;

  Future<void> connectViaWifi() async {
    _isConnecting = true;
    _connectionStatus = 'Connecting...';
    notifyListeners();

    try {
      bool result = await _wifiService.connectToEsp32();
      if (result) {
        _isConnected = true;
        _connectionStatus = 'Connected via WiFi';
        _wifiName = await _wifiService.getCurrentSSID() ?? 'Unknown';
        _wifiIP = await _wifiService.getCurrentIP() ?? 'Unknown';
      } else {
        _connectionStatus = 'Connection failed';
      }
    } catch (e) {
      _connectionStatus = 'Error: ${e.toString()}';
    } finally {
      _isConnecting = false;
      notifyListeners();
    }
  }

  void disconnect() {
    _isConnected = false;
    _connectionStatus = 'Disconnected';
    notifyListeners();
  }
}