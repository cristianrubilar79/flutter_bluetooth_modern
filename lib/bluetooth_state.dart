/// Representa el estado del adaptador Bluetooth del dispositivo.
enum BluetoothState {
  UNKNOWN,
  OFF,
  TURNING_ON,
  ON,
  TURNING_OFF,
  BLE_TURNING_ON,
  BLE_ON,
  BLE_TURNING_OFF;

  /// Convierte el valor entero del estado nativo de Android a un [BluetoothState].
  factory BluetoothState.fromUnderlyingValue(int value) {
    switch (value) {
      case 10:
        return BluetoothState.OFF;
      case 11:
        return BluetoothState.TURNING_ON;
      case 12:
        return BluetoothState.ON;
      case 13:
        return BluetoothState.TURNING_OFF;
      // Los valores para BLE no son directamente equivalentes en la API clásica,
      // pero se pueden añadir si se implementa lógica para BLE en el futuro.
      default:
        return BluetoothState.UNKNOWN;
    }
  }

  String get stringValue {
    switch (this) {
      case BluetoothState.OFF:
        return 'off';
      case BluetoothState.TURNING_ON:
        return 'turning_on';
      case BluetoothState.ON:
        return 'on';
      case BluetoothState.TURNING_OFF:
        return 'turning_off';
      default:
        return 'unknown';
    }
  }

  bool get isEnabled => this == BluetoothState.ON;
}
