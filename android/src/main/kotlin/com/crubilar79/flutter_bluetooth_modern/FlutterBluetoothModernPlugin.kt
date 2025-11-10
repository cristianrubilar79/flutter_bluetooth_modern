package com.crubilar79.flutter_bluetooth_modern

import android.Manifest
import android.annotation.SuppressLint
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothManager
import android.bluetooth.BluetoothSocket
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.content.ContextCompat
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import kotlinx.coroutines.*
import java.io.IOException
import java.util.*
import java.util.concurrent.ConcurrentHashMap

class FlutterBluetoothModernPlugin : FlutterPlugin, MethodCallHandler {
    private lateinit var methodChannel: MethodChannel
    private lateinit var stateChannel: EventChannel
    private lateinit var discoveryChannel: EventChannel
    private lateinit var readChannel: EventChannel
    private var context: Context? = null

    private val bluetoothManager: BluetoothManager? by lazy {
        context?.getSystemService(Context.BLUETOOTH_SERVICE) as? BluetoothManager
    }
    private val bluetoothAdapter: BluetoothAdapter? by lazy {
        bluetoothManager?.adapter
    }

    // Mapa para gestionar conexiones activas y sus corrutinas de lectura
    private val activeConnections = ConcurrentHashMap<String, Job>()
    private val activeSockets = ConcurrentHashMap<String, BluetoothSocket>()

    // Coroutine scope para las operaciones de larga duración
    private val pluginScope = CoroutineScope(Dispatchers.IO + SupervisorJob())

    // Receptores de Broadcast
    private var stateReceiver: StateReceiver? = null
    private var discoveryReceiver: DiscoveryReceiver? = null

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        this.context = flutterPluginBinding.applicationContext
        methodChannel = MethodChannel(flutterPluginBinding.binaryMessenger, "flutter_bluetooth_modern/methods")
        stateChannel = EventChannel(flutterPluginBinding.binaryMessenger, "flutter_bluetooth_modern/state")
        discoveryChannel = EventChannel(flutterPluginBinding.binaryMessenger, "flutter_bluetooth_modern/discovery")
        readChannel = EventChannel(flutterPluginBinding.binaryMessenger, "flutter_bluetooth_modern/read")

        methodChannel.setMethodCallHandler(this)
        stateChannel.setStreamHandler(StateStreamHandler(this))
        discoveryChannel.setStreamHandler(DiscoveryStreamHandler(this))
        readChannel.setStreamHandler(ReadStreamHandler(this))
    }

    @SuppressLint("MissingPermission")
    override fun onMethodCall(call: MethodCall, result: Result) {
        if (bluetoothAdapter == null && call.method != "isAvailable") {
            return result.error("bluetooth_unavailable", "Bluetooth no disponible", null)
        }

        when (call.method) {
            "isAvailable" -> result.success(bluetoothAdapter != null)
            "isEnabled" -> result.success(bluetoothAdapter?.isEnabled == true)
            "isDiscovering" -> result.success(bluetoothAdapter?.isDiscovering == true)
            "startDiscovery" -> {
                if (!checkPermissions()) return result.error("no_permissions", "Faltan permisos", null)
                bluetoothAdapter?.startDiscovery()
                result.success(true)
            }
            "cancelDiscovery" -> {
                if (!checkPermissions()) return result.error("no_permissions", "Faltan permisos", null)
                bluetoothAdapter?.cancelDiscovery()
                result.success(true)
            }
            "getBondedDevices" -> {
                if (!checkPermissions()) return result.error("no_permissions", "Faltan permisos de BLUETOOTH_CONNECT", null)
                try {
                    val bondedDevices = bluetoothAdapter?.bondedDevices
                    val deviceList = bondedDevices?.map { device ->
                        mapOf(
                            "name" to device.name,
                            "address" to device.address
                        )
                    }
                    result.success(deviceList)
                } catch (e: SecurityException) {
                    result.error("security_exception", "Error de seguridad al obtener dispositivos vinculados", e.message)
                }
            }
            "connect" -> {
                val address = call.argument<String>("address")
                if (address == null) {
                    result.error("invalid_argument", "La dirección no puede ser nula", null)
                    return
                }
                connectToDevice(address, result)
            }
            "disconnect" -> {
                val connectionId = call.argument<String>("connectionId")!!
                disconnectFromDevice(connectionId)
                result.success(null)
            }
            "write" -> {
                val connectionId = call.argument<String>("connectionId")!!
                val data = call.argument<ByteArray>("data")!!
                pluginScope.launch {
                    try {
                        activeSockets[connectionId]?.outputStream?.write(data)
                        withContext(Dispatchers.Main) { result.success(null) }
                    } catch (e: IOException) {
                        withContext(Dispatchers.Main) { result.error("write_error", e.message, null) }
                        disconnectFromDevice(connectionId)
                    }
                }
            }
            else -> result.notImplemented()
        }
    }

    @SuppressLint("MissingPermission")
    private fun connectToDevice(address: String, result: Result) {
        pluginScope.launch {
            try {
                val device = bluetoothAdapter!!.getRemoteDevice(address)
                val socket = device.createRfcommSocketToServiceRecord(UUID.fromString("00001101-0000-1000-8000-00805F9B34FB"))
                socket.connect() // Operación de bloqueo

                val connectionId = address // Usamos la dirección como ID de conexión por simplicidad
                activeSockets[connectionId] = socket
                withContext(Dispatchers.Main) { result.success(connectionId) }
            } catch (e: IOException) {
                withContext(Dispatchers.Main) { result.error("connection_error", "No se pudo conectar: ${e.message}", null) }
            }
        }
    }

    private fun disconnectFromDevice(connectionId: String) {
        activeConnections[connectionId]?.cancel()
        activeConnections.remove(connectionId)
        try {
            activeSockets[connectionId]?.close()
        } catch (_: IOException) {}
        activeSockets.remove(connectionId)
    }

    // --- Clases internas para manejar los streams ---

    private class StateStreamHandler(private val plugin: FlutterBluetoothModernPlugin) : EventChannel.StreamHandler {
        override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
            plugin.stateReceiver = StateReceiver(events)
            plugin.context?.registerReceiver(plugin.stateReceiver, IntentFilter(BluetoothAdapter.ACTION_STATE_CHANGED))
        }
        override fun onCancel(arguments: Any?) {
            plugin.context?.unregisterReceiver(plugin.stateReceiver)
            plugin.stateReceiver = null
        }
    }

    private class DiscoveryStreamHandler(private val plugin: FlutterBluetoothModernPlugin) : EventChannel.StreamHandler {
        override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
            plugin.discoveryReceiver = DiscoveryReceiver(events)
            val filter = IntentFilter().apply {
                addAction(BluetoothDevice.ACTION_FOUND)
                addAction(BluetoothAdapter.ACTION_DISCOVERY_FINISHED)
            }
            plugin.context?.registerReceiver(plugin.discoveryReceiver, filter)
        }
        override fun onCancel(arguments: Any?) {
            plugin.context?.unregisterReceiver(plugin.discoveryReceiver)
            plugin.discoveryReceiver = null
        }
    }

    private class ReadStreamHandler(private val plugin: FlutterBluetoothModernPlugin) : EventChannel.StreamHandler {
        override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
            val connectionId = arguments as String
            val socket = plugin.activeSockets[connectionId]
            if (socket == null) {
                events.error("invalid_connection", "La conexión no existe", null)
                return
            }

            val job = plugin.pluginScope.launch {
                val inputStream = socket.inputStream
                val buffer = ByteArray(1024)
                while (isActive) {
                    try {
                        val bytes = inputStream.read(buffer)
                        val data = buffer.copyOf(bytes)
                        launch(Dispatchers.Main) {
                            events.success(data)
                        }
                    } catch (e: IOException) {
                        launch(Dispatchers.Main) {
                            events.endOfStream()
                        }
                        plugin.disconnectFromDevice(connectionId)
                        break
                    }
                }
            }
            plugin.activeConnections[connectionId] = job
        }

        override fun onCancel(arguments: Any?) {
            val connectionId = arguments as String
            plugin.disconnectFromDevice(connectionId)
        }
    }

    // --- Receptores de Broadcast ---

    private class StateReceiver(private val events: EventChannel.EventSink) : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            if (intent.action == BluetoothAdapter.ACTION_STATE_CHANGED) {
                events.success(intent.getIntExtra(BluetoothAdapter.EXTRA_STATE, BluetoothAdapter.ERROR))
            }
        }
    }

    private class DiscoveryReceiver(private val events: EventChannel.EventSink) : BroadcastReceiver() {
        @SuppressLint("MissingPermission")
        override fun onReceive(context: Context, intent: Intent) {
            when (intent.action) {
                BluetoothDevice.ACTION_FOUND -> {
                    val device: BluetoothDevice? = intent.getParcelableExtra(BluetoothDevice.EXTRA_DEVICE)
                    if (device != null) {
                        val rssi = intent.getShortExtra(BluetoothDevice.EXTRA_RSSI, Short.MIN_VALUE)
                        events.success(mapOf(
                            "device" to mapOf("name" to device.name, "address" to device.address),
                            "rssi" to rssi.toInt()
                        ))
                    }
                }
                BluetoothAdapter.ACTION_DISCOVERY_FINISHED -> events.endOfStream()
            }
        }
    }

    private fun checkPermissions(): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            return ContextCompat.checkSelfPermission(context!!, Manifest.permission.BLUETOOTH_SCAN) == PackageManager.PERMISSION_GRANTED &&
                   ContextCompat.checkSelfPermission(context!!, Manifest.permission.BLUETOOTH_CONNECT) == PackageManager.PERMISSION_GRANTED
        }
        return true
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        pluginScope.cancel()
        context = null
        methodChannel.setMethodCallHandler(null)
        stateChannel.setStreamHandler(null)
        discoveryChannel.setStreamHandler(null)
        readChannel.setStreamHandler(null)
    }
}
