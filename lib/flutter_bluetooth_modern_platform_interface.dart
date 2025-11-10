import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'flutter_bluetooth_modern_method_channel.dart';

abstract class FlutterBluetoothModernPlatform extends PlatformInterface {
  /// Constructs a FlutterBluetoothModernPlatform.
  FlutterBluetoothModernPlatform() : super(token: _token);

  static final Object _token = Object();

  static FlutterBluetoothModernPlatform _instance = MethodChannelFlutterBluetoothModern();

  /// The default instance of [FlutterBluetoothModernPlatform] to use.
  ///
  /// Defaults to [MethodChannelFlutterBluetoothModern].
  static FlutterBluetoothModernPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [FlutterBluetoothModernPlatform] when
  /// they register themselves.
  static set instance(FlutterBluetoothModernPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
