
import 'dart:async';



import 'package:flutter/services.dart';

import 'package:flutter_bluetooth_modern/models/bluetooth_connection.dart';

import 'package:flutter_bluetooth_modern/models/bluetooth_discovery_result.dart';

import 'package:flutter_bluetooth_modern/models/bluetooth_device.dart';

import 'package:flutter_bluetooth_modern/bluetooth_state.dart';



export 'package:flutter_bluetooth_modern/bluetooth_state.dart';

export 'package:flutter_bluetooth_modern/models/bluetooth_device.dart';

export 'package:flutter_bluetooth_modern/models/bluetooth_discovery_result.dart';

export 'package:flutter_bluetooth_modern/models/bluetooth_connection.dart';





class FlutterBluetoothModern {

  /// Instancia singleton para acceder a la API.

  static final FlutterBluetoothModern _instance = FlutterBluetoothModern._();

  static FlutterBluetoothModern get instance => _instance;



  // Canales de comunicación con el código nativo.

  final MethodChannel _methodChannel =

      const MethodChannel('flutter_bluetooth_modern/methods');

  final EventChannel _stateChannel =

      const EventChannel('flutter_bluetooth_modern/state');

  final EventChannel _discoveryChannel =

      const EventChannel('flutter_bluetooth_modern/discovery');

  final EventChannel _readChannel =

      const EventChannel('flutter_bluetooth_modern/read');



  /// Constructor privado para el patrón singleton.

  FlutterBluetoothModern._();



  /// Comprueba si el hardware de Bluetooth está disponible en el dispositivo.

  Future<bool> get isAvailable async =>

      await _methodChannel.invokeMethod('isAvailable').then((value) => value ?? false);



  /// Comprueba si el adaptador Bluetooth está actualmente activado.

  Future<bool> get isEnabled async =>

      await _methodChannel.invokeMethod('isEnabled').then((value) => value ?? false);



  /// Devuelve el estado actual del adaptador Bluetooth.

  Future<BluetoothState> get state async {

    if (await isEnabled) {

      return BluetoothState.ON;

    } else {

      return BluetoothState.OFF;

    }

  }



    /// Emite un evento cada vez que el estado del adaptador Bluetooth cambia.



    Stream<BluetoothState> onStateChanged() {



      return _stateChannel



          .receiveBroadcastStream()



          .map((value) => BluetoothState.fromUnderlyingValue(value));



    }



  



    /// --- Funcionalidad de Dispositivos Vinculados ---



  



    /// Devuelve la lista de dispositivos que han sido previamente vinculados al dispositivo.



    Future<List<BluetoothDevice>> getBondedDevices() async {



      final List<dynamic>? devices = await _methodChannel.invokeMethod('getBondedDevices');



      return devices?.map((device) => BluetoothDevice.fromMap(device)).toList() ?? [];



    }



  



    /// --- Funcionalidad de Descubrimiento ---



  



    /// Comprueba si el dispositivo está actualmente buscando otros dispositivos.



    Future<bool> get isDiscovering async =>



        await _methodChannel.invokeMethod('isDiscovering').then((value) => value ?? false);



  /// Inicia el proceso de descubrimiento de dispositivos.

  Stream<BluetoothDiscoveryResult> startDiscovery() {

    _methodChannel.invokeMethod('startDiscovery');

    return _discoveryChannel

        .receiveBroadcastStream()

        .map((data) => BluetoothDiscoveryResult.fromMap(data));

  }



  /// Cancela un proceso de descubrimiento de dispositivos en curso.

  Future<void> cancelDiscovery() async {

    await _methodChannel.invokeMethod('cancelDiscovery');

  }



  /// --- Funcionalidad de Conexión ---



    /// Se conecta a un dispositivo dada su [address].



    ///



    /// Devuelve un objeto [BluetoothConnection] si la conexión es exitosa.



    /// Lanza una [PlatformException] si la conexión falla.



    Future<BluetoothConnection> connect(String address) async {



      final connectionId = await _methodChannel.invokeMethod('connect', {'address': address});



      if (connectionId == null || connectionId is! String) {



        throw PlatformException(code: 'connection_error', message: 'La conexión devolvió un ID nulo o inválido.');



      }



      



      return BluetoothConnection.create(



        connectionId: connectionId,



        readChannel: _readChannel, // Usamos el canal de lectura principal



      );



    }

}
