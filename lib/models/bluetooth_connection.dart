import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/services.dart';

/// Representa una conexión activa con un dispositivo Bluetooth remoto.
/// Permite la lectura y escritura de datos a través de streams.
class BluetoothConnection {
  final MethodChannel _methodChannel =
      const MethodChannel('flutter_bluetooth_modern/methods');

  /// El identificador único de la conexión, asignado por la capa nativa.
  final String connectionId;

  /// Stream de datos entrantes desde el dispositivo remoto.
  final Stream<Uint8List> input;

  /// Un callback que se ejecuta cuando la conexión se cierra.
  final VoidCallback? onDone;

  bool _isOpen = true;

  /// Devuelve `true` si la conexión sigue activa.
  bool get isOpen => _isOpen;

  BluetoothConnection._({
    required this.connectionId,
    required this.input,
    this.onDone,
  }) {
    // Escuchamos el stream para saber cuándo se cierra
    input.listen(
      (_) {}, // No hacemos nada con los datos aquí, solo nos interesa el estado.
      onDone: () {
        _isOpen = false;
        onDone?.call();
      },
      // El onError es manejado por el consumidor del stream.
    );
  }

  /// Fábrica para crear y gestionar una conexión.
  /// Usado internamente por la librería.
  factory BluetoothConnection.create({
    required String connectionId,
    required EventChannel readChannel,
    VoidCallback? onDone,
  }) {
    // Pasamos el `connectionId` como argumento al stream.
    // La capa nativa usará este argumento para saber de qué socket leer.
    final stream = readChannel
        .receiveBroadcastStream(connectionId)
        .map((data) => data as Uint8List);

    return BluetoothConnection._(
      connectionId: connectionId,
      input: stream,
      onDone: onDone,
    );
  }

  /// Envía datos al dispositivo remoto.
  ///
  /// Los datos se deben enviar como una lista de enteros sin signo de 8 bits.
  /// Para enviar texto, puedes usar `ascii.encode('tu texto')`.
  Future<void> write(Uint8List data) async {
    if (!isOpen) {
      throw StateError('La conexión está cerrada.');
    }
    await _methodChannel.invokeMethod('write', {
      'connectionId': connectionId,
      'data': data,
    });
  }

  /// Cierra la conexión.
  ///
  /// Esto notificará al `onDone` callback y cerrará el `input` stream.
  Future<void> close() async {
    if (isOpen) {
      await _methodChannel.invokeMethod('disconnect', {
        'connectionId': connectionId,
      });
    }
  }
}
