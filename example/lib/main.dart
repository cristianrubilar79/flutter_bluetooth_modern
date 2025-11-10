import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_modern/flutter_bluetooth_modern.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: BluetoothExamplePage(),
    );
  }
}

class BluetoothExamplePage extends StatefulWidget {
  const BluetoothExamplePage({super.key});

  @override
  State<BluetoothExamplePage> createState() => _BluetoothExamplePageState();
}

class _BluetoothExamplePageState extends State<BluetoothExamplePage> {
  // Instancia de nuestra nueva librería
  final FlutterBluetoothModern _bluetooth = FlutterBluetoothModern.instance;

  // Variables de estado
  BluetoothState _bluetoothState = BluetoothState.UNKNOWN;
  StreamSubscription<BluetoothState>? _stateSubscription;
  StreamSubscription<BluetoothDiscoveryResult>? _discoverySubscription;

  bool _isDiscovering = false;
  final List<BluetoothDiscoveryResult> _discoveryResults = [];

  BluetoothConnection? _connection;
  bool get _isConnected => _connection?.isOpen ?? false;
  final List<String> _receivedData = [];
  final TextEditingController _sendTextController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    // Solicitar permisos al iniciar
    await _requestPermissions();

    // Obtener estado inicial
    _bluetooth.state.then((state) {
      setState(() => _bluetoothState = state);
    });

    // Escuchar cambios de estado
    _stateSubscription = _bluetooth.onStateChanged().listen((state) {
      setState(() => _bluetoothState = state);
    });
  }

  /// Solicita los permisos de Bluetooth necesarios para Android 12+
  Future<void> _requestPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse, // Requerido para el escaneo
    ].request();

    if (statuses[Permission.bluetoothScan] != PermissionStatus.granted ||
        statuses[Permission.bluetoothConnect] != PermissionStatus.granted ||
        statuses[Permission.locationWhenInUse] != PermissionStatus.granted) {
      // Mostrar un diálogo o un snackbar informando al usuario
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Los permisos de Bluetooth son necesarios para usar esta función.')),
        );
      }
    }
  }

  @override
  void dispose() {
    _stateSubscription?.cancel();
    _discoverySubscription?.cancel();
    _connection?.close();
    super.dispose();
  }

  void _startDiscovery() {
    setState(() {
      _isDiscovering = true;
      _discoveryResults.clear();
    });

    _discoverySubscription = _bluetooth.startDiscovery().listen(
      (result) {
        setState(() {
          // Evitar duplicados
          final existingIndex = _discoveryResults.indexWhere((r) => r.device.address == result.device.address);
          if (existingIndex < 0) {
            _discoveryResults.add(result);
          }
        });
      },
      onDone: () {
        setState(() => _isDiscovering = false);
      },
      onError: (error) {
        print('Error en el descubrimiento: $error');
        setState(() => _isDiscovering = false);
      },
    );
  }

  void _cancelDiscovery() {
    _bluetooth.cancelDiscovery();
    setState(() => _isDiscovering = false);
  }

  void _connectToDevice(BluetoothDevice device) async {
    try {
      final connection = await _bluetooth.connect(device.address);
      setState(() {
        _connection = connection;
        _receivedData.clear();
      });

      // Escuchar datos entrantes
      _connection!.input.listen((Uint8List data) {
        final message = ascii.decode(data, allowInvalid: true);
        setState(() {
          _receivedData.add('RECIBIDO: $message');
        });
      }).onDone(() {
        // Conexión cerrada por el dispositivo remoto
        if (mounted) {
          setState(() {});
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Desconectado por el dispositivo.')));
        }
      });
    } catch (e) {
      print('Error de conexión: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error de conexión: $e')));
    }
  }

  void _disconnect() {
    _connection?.close();
    setState(() {}); // Actualiza la UI para reflejar la desconexión
  }

  void _sendMessage() {
    if (_sendTextController.text.isEmpty) return;

    try {
      final message = _sendTextController.text;
      _connection?.write(ascii.encode(message) as Uint8List);
      setState(() {
        _receivedData.add('ENVIADO: $message');
        _sendTextController.clear();
      });
    } catch (e) {
      print('Error al enviar: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al enviar: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ejemplo Bluetooth Moderno'),
      ),
      body: _isConnected ? _buildChatView() : _buildDiscoveryView(),
    );
  }

  Widget _buildDiscoveryView() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Estado de Bluetooth: ${_bluetoothState.stringValue.toUpperCase()}'),
              ElevatedButton(
                onPressed: _isDiscovering ? _cancelDiscovery : _startDiscovery,
                child: Text(_isDiscovering ? 'Detener' : 'Escanear'),
              ),
            ],
          ),
        ),
        if (_isDiscovering) const LinearProgressIndicator(),
        Expanded(
          child: ListView.builder(
            itemCount: _discoveryResults.length,
            itemBuilder: (context, index) {
              final result = _discoveryResults[index];
              return ListTile(
                title: Text(result.device.name ?? 'Dispositivo Desconocido'),
                subtitle: Text(result.device.address),
                trailing: ElevatedButton(
                  onPressed: () => _connectToDevice(result.device),
                  child: const Text('Conectar'),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildChatView() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Text('Conectado a: ${_connection?.connectionId ?? 'N/A'}', style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
              itemCount: _receivedData.length,
              itemBuilder: (context, index) => Text(_receivedData[index]),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _sendTextController,
                  decoration: const InputDecoration(labelText: 'Mensaje'),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send),
                onPressed: _sendMessage,
              ),
            ],
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: _disconnect,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Desconectar'),
          )
        ],
      ),
    );
  }
}