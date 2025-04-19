// lib/services/bluetooth_service.dart
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BluetoothService {
  List<BluetoothDevice> _devicesList = [];
  BluetoothDevice? _connectedDevice;
  bool _isScanning = false;

  List<BluetoothDevice> get devicesList => _devicesList;
  BluetoothDevice? get connectedDevice => _connectedDevice;
  bool get isScanning => _isScanning;

  Future<void> scanDevices() async {
    _isScanning = true;
    _devicesList.clear();

    FlutterBluePlus.scanResults.listen((results) {
      for (var result in results) {
        if (!_devicesList.any((device) => device.id == result.device.id)) {
          _devicesList.add(result.device);
        }
      }
    });

    await FlutterBluePlus.startScan(timeout: Duration(seconds: 4));
    _isScanning = false;
  }

  Future<void> connectToDevice(BluetoothDevice device) async {
    await device.connect(autoConnect: false);
    _connectedDevice = device;
  }

  Future<void> disconnectDevice() async {
    if (_connectedDevice != null) {
      await _connectedDevice!.disconnect();
      _connectedDevice = null;
    }
  }
}