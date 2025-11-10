// This is a basic Flutter integration test.
//
// Since integration tests run in a full Flutter application, they can interact
// with the host side of a plugin implementation, unlike Dart unit tests.
//
// For more information about Flutter integration tests, please see
// https://flutter.dev/to/integration-testing


import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:flutter_bluetooth_modern/flutter_bluetooth_modern.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('isAvailable test', (WidgetTester tester) async {
    // Obtenemos la instancia singleton en lugar de crear una nueva.
    final FlutterBluetoothModern plugin = FlutterBluetoothModern.instance;
    
    // Llamamos a un método que sí existe en nuestra nueva API.
    final bool isAvailable = await plugin.isAvailable;
    
    // Verificamos que obtenemos una respuesta booleana, lo que confirma
    // que el canal de comunicación con el código nativo funciona.
    expect(isAvailable, isNotNull);
  });
}
