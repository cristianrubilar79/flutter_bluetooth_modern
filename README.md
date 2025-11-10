# Flutter Bluetooth Modern

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Platform: Android](https://img.shields.io/badge/Platform-Android-green.svg)](#)

**Languages:**
[English](#-english) | [Español](#-español) | [Français](#-français)

---

## 🇬🇧 English

A modern Flutter plugin for Classic Bluetooth (RFCOMM/SPP) communication on Android, built from the ground up with current best practices.

This package provides a clean, safe, and easy-to-use API to interact with Classic Bluetooth devices. It was created as a modern alternative to older libraries, with a focus on stability, null safety, and a robust architecture based on Kotlin and Streams.

### ✨ Features

- **Modern and Safe API:** 100% null-safe.
- **Native Kotlin Backend:** Uses Kotlin and coroutines for efficient and safe performance on the Android side.
- **Reactive State Management:** Listen to Bluetooth adapter state changes in real-time.
- **Stream-Based Discovery:** Receive discovered devices through an easy-to-consume `Stream`.
- **Explicit Connection Management:** Robustly handles multiple connections, where each connection is an independent `BluetoothConnection` object.
- **Bidirectional Communication:** Read and write data through standard Dart `Streams` and `Sinks`.

### Platform Support

| Android | iOS | Web | macOS | Windows | Linux |
| :-----: | :-: | :-: | :---: | :-----: | :---: |
|   ✔️    | ❌  | ❌  |  ❌   |   ❌    |  ❌   |

Currently, this library is **Android only**.

### ⚙️ Setup

#### 1. Add Dependency

Add the library to your `pubspec.yaml` file:

```yaml
dependencies:
  flutter_bluetooth_modern: ^1.0.0 # Replace with the latest version
```

#### 2. Android Setup

Open your `android/app/src/main/AndroidManifest.xml` file and add the following permissions before the `<application>` tag:

```xml
<!-- Permission for Classic Bluetooth (required up to Android 11) -->
<uses-permission android:name="android.permission.BLUETOOTH" />
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN" />

<!-- Location permission, required for device scanning on Android 6.0+ -->
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />

<!-- New permissions for Android 12 (API 31) and higher -->
<uses-permission android:name="android.permission.BLUETOOTH_SCAN" android:usesPermissionFlags="neverForLocation" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
```

#### 3. Request Permissions at Runtime

On Android 6.0 and higher, permissions must be requested at runtime. We recommend using the `permission_handler` package.

Add the dependency:
```yaml
dependencies:
  permission_handler: ^11.0.0 # Or the latest version
```

And request the permissions in your code before scanning:
```dart
import 'package:permission_handler/permission_handler.dart';

Future<void> requestPermissions() async {
  await [
    Permission.bluetoothScan,
    Permission.bluetoothConnect,
    Permission.locationWhenInUse,
  ].request();
}
```

### 🚀 Usage

#### Getting the Instance

```dart
import 'package:flutter_bluetooth_modern/flutter_bluetooth_modern.dart';

final FlutterBluetoothModern bluetooth = FlutterBluetoothModern.instance;
```

#### State Management

```dart
bool isEnabled = await bluetooth.isEnabled;

bluetooth.onStateChanged().listen((BluetoothState state) {
  print("Bluetooth state is now: ${state.stringValue}");
});
```

#### Device Discovery

```dart
StreamSubscription<BluetoothDiscoveryResult> discoverySubscription = bluetooth.startDiscovery().listen((result) {
  print('Device found: ${result.device.name ?? 'unknown'} (${result.device.address})');
});

discoverySubscription.onDone(() {
  print('Discovery finished.');
});

await bluetooth.cancelDiscovery();
```

#### Connection and Communication

```dart
import 'dart:convert';
import 'dart:typed_data';

BluetoothConnection? connection;

try {
  connection = await bluetooth.connect('00:11:22:33:44:55'); // Replace with the device address
  
  connection!.input.listen((Uint8List data) {
    print('Data received: ${ascii.decode(data, allowInvalid: true)}');
  }).onDone(() {
    print('Disconnected by remote device.');
  });

  connection!.write(ascii.encode('Hello World!') as Uint8List);

} catch (e) {
  print('Connection error: $e');
}

await connection?.close();
```

### 📖 Complete Example

A complete example application can be found in the `example` folder.

### 📄 License

This project is licensed under the MIT License.

---

## 🇪🇸 Español

Un plugin de Flutter moderno para la comunicación por Bluetooth Clásico (RFCOMM/SPP) en Android, construido desde cero con las mejores prácticas actuales.

Este paquete proporciona una API limpia, segura y fácil de usar para interactuar con dispositivos Bluetooth Clásico. Fue creado como una alternativa moderna a librerías más antiguas, con un enfoque en la estabilidad, la seguridad de nulos y una arquitectura robusta basada en Kotlin y Streams.

### ✨ Características

- **API Moderna y Segura:** 100% compatible con null safety.
- **Nativo en Kotlin:** Utiliza Kotlin y corrutinas para un rendimiento eficiente y seguro en el lado de Android.
- **Gestión de Estado Reactiva:** Escucha cambios en el estado del adaptador Bluetooth en tiempo real.
- **Descubrimiento Basado en Streams:** Recibe los dispositivos descubiertos a través de un `Stream` fácil de consumir.
- **Gestión de Conexiones Explícita:** Maneja múltiples conexiones de forma robusta, donde cada conexión es un objeto `BluetoothConnection` independiente.
- **Comunicación Bidireccional:** Lee y escribe datos a través de `Streams` y `Sinks` estándar de Dart.

### 平台支持

| Android | iOS | Web | macOS | Windows | Linux |
| :-----: | :-: | :-: | :---: | :-----: | :---: |
|   ✔️    | ❌  | ❌  |  ❌   |   ❌    |  ❌   |

Actualmente, esta librería **solo es compatible con Android**.

### ⚙️ Configuración

#### 1. Añadir Dependencia

Añade la librería a tu archivo `pubspec.yaml`:

```yaml
dependencies:
  flutter_bluetooth_modern: ^1.0.0 # Reemplaza con la última versión
```

#### 2. Configuración de Android

Abre tu archivo `android/app/src/main/AndroidManifest.xml` y añade los siguientes permisos antes de la etiqueta `<application>`:

```xml
<!-- Permiso para Bluetooth Clásico (necesario hasta Android 11) -->
<uses-permission android:name="android.permission.BLUETOOTH" />
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN" />

<!-- Permiso de ubicación, requerido para el escaneo de dispositivos en Android 6.0+ -->
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />

<!-- Nuevos permisos para Android 12 (API 31) y superior -->
<uses-permission android:name="android.permission.BLUETOOTH_SCAN" android:usesPermissionFlags="neverForLocation" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
```

#### 3. Solicitar Permisos en Tiempo de Ejecución

En Android 6.0 y superior, los permisos deben solicitarse en tiempo de ejecución. Recomendamos usar el paquete `permission_handler`.

Añade la dependencia:
```yaml
dependencies:
  permission_handler: ^11.0.0 # O la última versión
```

Y solicita los permisos en tu código antes de escanear:
```dart
import 'package:permission_handler/permission_handler.dart';

Future<void> requestPermissions() async {
  await [
    Permission.bluetoothScan,
    Permission.bluetoothConnect,
    Permission.locationWhenInUse,
  ].request();
}
```

### 🚀 Uso

#### Obtener la Instancia

```dart
import 'package:flutter_bluetooth_modern/flutter_bluetooth_modern.dart';

final FlutterBluetoothModern bluetooth = FlutterBluetoothModern.instance;
```

#### Gestión de Estado

```dart
bool isEnabled = await bluetooth.isEnabled;

bluetooth.onStateChanged().listen((BluetoothState state) {
  print("El estado del Bluetooth ahora es: ${state.stringValue}");
});
```

#### Descubrimiento de Dispositivos

```dart
StreamSubscription<BluetoothDiscoveryResult> discoverySubscription = bluetooth.startDiscovery().listen((result) {
  print('Dispositivo encontrado: ${result.device.name ?? 'desconocido'} (${result.device.address})');
});

discoverySubscription.onDone(() {
  print('Descubrimiento finalizado.');
});

await bluetooth.cancelDiscovery();
```

#### Conexión y Comunicación

```dart
import 'dart:convert';
import 'dart:typed_data';

BluetoothConnection? connection;

try {
  connection = await bluetooth.connect('00:11:22:33:44:55'); 
  
  connection!.input.listen((Uint8List data) {
    print('Dato recibido: ${ascii.decode(data, allowInvalid: true)}');
  }).onDone(() {
    print('Desconectado por el dispositivo remoto.');
  });

  connection!.write(ascii.encode('Hola Mundo!') as Uint8List);

} catch (e) {
  print('Error de conexión: $e');
}

await connection?.close();
```

### 📖 Ejemplo Completo

Puedes encontrar un ejemplo de aplicación completo en la carpeta `example`.

### 📄 Licencia

Este proyecto está licenciado bajo la Licencia MIT.

---

## 🇫🇷 Français

Un plugin Flutter moderne pour la communication Bluetooth Classique (RFCOMM/SPP) sur Android, entièrement reconstruit en suivant les meilleures pratiques actuelles.

Ce paquet fournit une API propre, sûre et simple à utiliser pour interagir avec les appareils Bluetooth Classique. Il a été créé comme une alternative moderne aux anciennes bibliothèques, en mettant l'accent sur la stabilité, la null-safety et une architecture robuste basée sur Kotlin et les Streams.

### ✨ Fonctionnalités

- **API Moderne et Sûre :** 100% compatible null-safety.
- **Natif en Kotlin :** Utilise Kotlin et les coroutines pour des performances efficaces et sûres côté Android.
- **Gestion d'État Réactive :** Écoutez les changements d'état de l'adaptateur Bluetooth en temps réel.
- **Découverte Basée sur les Streams :** Recevez les appareils découverts via un `Stream` facile à consommer.
- **Gestion Explicite des Connexions :** Gère de manière robuste plusieurs connexions, où chaque connexion est un objet `BluetoothConnection` indépendant.
- **Communication Bidirectionnelle :** Lisez et écrivez des données via les `Streams` et `Sinks` standards de Dart.

### Support Plateforme

| Android | iOS | Web | macOS | Windows | Linux |
| :-----: | :-: | :-: | :---: | :-----: | :---: |
|   ✔️    | ❌  | ❌  |  ❌   |   ❌    |  ❌   |

Actuellement, cette bibliothèque est **uniquement compatible avec Android**.

### ⚙️ Installation

#### 1. Ajouter la Dépendance

Ajoutez la bibliothèque à votre fichier `pubspec.yaml` :

```yaml
dependencies:
  flutter_bluetooth_modern: ^1.0.0 # Remplacez par la dernière version
```

#### 2. Configuration Android

Ouvrez votre fichier `android/app/src/main/AndroidManifest.xml` et ajoutez les permissions suivantes avant la balise `<application>` :

```xml
<!-- Permission pour le Bluetooth Classique (requise jusqu'à Android 11) -->
<uses-permission android:name="android.permission.BLUETOOTH" />
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN" />

<!-- Permission de localisation, requise pour le scan d'appareils sur Android 6.0+ -->
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />

<!-- Nouvelles permissions pour Android 12 (API 31) et supérieur -->
<uses-permission android:name="android.permission.BLUETOOTH_SCAN" android:usesPermissionFlags="neverForLocation" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
```

#### 3. Demander les Permissions à l'Exécution

Sur Android 6.0 et supérieur, les permissions doivent être demandées à l'exécution. Nous recommandons d'utiliser le paquet `permission_handler`.

Ajoutez la dépendance :
```yaml
dependencies:
  permission_handler: ^11.0.0 # Ou la dernière version
```

Et demandez les permissions dans votre code avant de scanner :
```dart
import 'package:permission_handler/permission_handler.dart';

Future<void> requestPermissions() async {
  await [
    Permission.bluetoothScan,
    Permission.bluetoothConnect,
    Permission.locationWhenInUse,
  ].request();
}
```

### 🚀 Utilisation

#### Obtenir l'Instance

```dart
import 'package:flutter_bluetooth_modern/flutter_bluetooth_modern.dart';

final FlutterBluetoothModern bluetooth = FlutterBluetoothModern.instance;
```

#### Gestion d'État

```dart
bool isEnabled = await bluetooth.isEnabled;

bluetooth.onStateChanged().listen((BluetoothState state) {
  print("L'état du Bluetooth est maintenant : ${state.stringValue}");
});
```

#### Découverte d'Appareils

```dart
StreamSubscription<BluetoothDiscoveryResult> discoverySubscription = bluetooth.startDiscovery().listen((result) {
  print('Appareil trouvé : ${result.device.name ?? 'inconnu'} (${result.device.address})');
});

discoverySubscription.onDone(() {
  print('Découverte terminée.');
});

await bluetooth.cancelDiscovery();
```

#### Connexion et Communication

```dart
import 'dart:convert';
import 'dart:typed_data';

BluetoothConnection? connection;

try {
  connection = await bluetooth.connect('00:11:22:33:44:55'); // Remplacez par l'adresse de l'appareil
  
  connection!.input.listen((Uint8List data) {
    print('Données reçues : ${ascii.decode(data, allowInvalid: true)}');
  }).onDone(() {
    print('Déconnecté par l'appareil distant.');
  });

  connection!.write(ascii.encode('Bonjour le Monde !') as Uint8List);

} catch (e) {
  print('Erreur de connexion : $e');
}

await connection?.close();
```

### 📖 Exemple Complet

Un exemple d'application complet se trouve dans le dossier `example`.

### 📄 Licence

Ce projet est sous licence MIT.