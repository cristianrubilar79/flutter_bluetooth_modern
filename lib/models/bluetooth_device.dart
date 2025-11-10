/// Representa un dispositivo Bluetooth y su información básica.
class BluetoothDevice {
  /// El nombre de transmisión (broadcast name) del dispositivo. Puede ser nulo.
  final String? name;

  /// La dirección MAC única del dispositivo.
  final String address;

  /// Constructor para un dispositivo Bluetooth.
  const BluetoothDevice({
    this.name,
    required this.address,
  });

  /// Crea una instancia de [BluetoothDevice] desde un mapa.
  /// Usado internamente para decodificar datos desde la capa nativa.
  factory BluetoothDevice.fromMap(Map<dynamic, dynamic> map) {
    return BluetoothDevice(
      name: map['name'],
      address: map['address']!,
    );
  }

  /// Convierte el objeto a un mapa.
  Map<String, dynamic> toMap() => {
        'name': name,
        'address': address,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BluetoothDevice &&
          runtimeType == other.runtimeType &&
          address == other.address;

  @override
  int get hashCode => address.hashCode;
}
