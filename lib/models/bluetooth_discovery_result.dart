import 'package:flutter_bluetooth_modern/models/bluetooth_device.dart';

/// Representa un único resultado encontrado durante el proceso de descubrimiento.
class BluetoothDiscoveryResult {
  /// El dispositivo que fue encontrado.
  final BluetoothDevice device;

  /// La fuerza de la señal del dispositivo (RSSI - Received Signal Strength Indication).
  /// Un valor más cercano a 0 indica una señal más fuerte.
  final int rssi;

  const BluetoothDiscoveryResult({
    required this.device,
    this.rssi = 0,
  });

  /// Crea una instancia desde un mapa (usado para la comunicación nativa).
  factory BluetoothDiscoveryResult.fromMap(Map<dynamic, dynamic> map) {
    return BluetoothDiscoveryResult(
      device: BluetoothDevice.fromMap(map['device']),
      rssi: map['rssi'] ?? 0,
    );
  }
}
