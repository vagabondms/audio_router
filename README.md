# Audio Router

A Flutter plugin for managing audio output in VoIP and communication apps. Switch between speaker, receiver, Bluetooth, and other audio devices with native UI.

> **Note:** This plugin was created for my personal projects, but feel free to use it if it fits your needs. If you encounter any issues, please report them in the [Issues](https://github.com/vagabondms/audio_router/issues) section and I'll take a look when I have time.

## Quick Start

```dart
import 'package:audio_router/audio_router.dart';

final audioRouter = AudioRouter();

// Show audio device picker
await audioRouter.showAudioRoutePicker(context);

// Listen to device changes
audioRouter.currentDeviceStream.listen((device) {
  print('Now using: ${device?.type}');
});
```

## What is Audio Router?

This plugin helps you **manage audio output devices during calls**. It provides:

- **Native UI** for choosing audio devices (iOS system picker, Android Material Design dialog)
- **Real-time monitoring** of which device is currently active
- **Automatic detection** when devices are connected or disconnected

### Important: You Setup Audio Session, We Handle Routing

This plugin **does NOT configure audio sessions**. Your app must first set up the audio session:

- **Android**: Set `AudioManager.MODE_IN_COMMUNICATION` for VoIP calls
- **iOS**: Set `AVAudioSession` category to `.playAndRecord` with `.voiceChat` mode

Think of it this way: You tell the system "I'm making a call" (audio session), then this plugin lets users choose "where the sound comes out" (audio routing).

## Features

- **Native device picker UI** that matches each platform's design
- **Real-time device monitoring** via streams
- **Automatic device detection** when plugging/unplugging devices
- **Smart filtering** on Android (shows only call-compatible devices by default)

### Platform-Specific

**iOS**
- Uses Apple's system picker (`AVRoutePickerView`)
- Supports AirPlay and CarPlay
- Automatic device management by the system

**Android**
- Material Design 3 dialog
- Filters devices for communication by default (SCO Bluetooth, USB headsets)
- Can switch to media mode for A2DP Bluetooth if needed

## Best Used For

✅ **VoIP and Communication Apps (Default)**
- VoIP calls (Zoom, WhatsApp, etc.)
- Voice/video chat apps
- Real-time communication
- Uses `communication` mode by default (filters for call-compatible devices)

✅ **Media Playback Apps (Use `.media()` option)**
- Music players, games, video apps
- Any app that needs A2DP Bluetooth or all USB devices
- Use `AndroidAudioOptions.media()` to include all audio devices

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  audio_router: ^1.0.1
```

Run:
```bash
flutter pub get
```

## Usage

### Step 1: Setup Audio Session (Required First!)

Before using the plugin, configure your audio session. This tells the OS "we're making a call".

#### Android Setup

**Option A: Via Platform Channel (Recommended)**

```dart
// Dart code
import 'package:flutter/services.dart';
import 'dart:io';

Future<void> setupAudioForCall() async {
  if (Platform.isAndroid) {
    const platform = MethodChannel('your_app/audio');
    await platform.invokeMethod('setAudioMode');
  }
}
```

```kotlin
// MainActivity.kt
import android.media.AudioManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
  override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)

    MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "your_app/audio")
      .setMethodCallHandler { call, result ->
        if (call.method == "setAudioMode") {
          val audioManager = getSystemService(AUDIO_SERVICE) as AudioManager
          audioManager.mode = AudioManager.MODE_IN_COMMUNICATION
          result.success(null)
        }
      }
  }
}
```

#### iOS Setup

**Option A: Via Platform Channel (Recommended)**

```dart
// Dart code
import 'package:flutter/services.dart';
import 'dart:io';

Future<void> setupAudioForCall() async {
  if (Platform.isIOS) {
    const platform = MethodChannel('your_app/audio');
    await platform.invokeMethod('setupAudioSession');
  }
}
```

```swift
// AppDelegate.swift
import AVFoundation
import Flutter

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller = window?.rootViewController as! FlutterViewController
    let channel = FlutterMethodChannel(
      name: "your_app/audio",
      binaryMessenger: controller.binaryMessenger
    )

    channel.setMethodCallHandler { (call, result) in
      if call.method == "setupAudioSession" {
        do {
          let session = AVAudioSession.sharedInstance()
          try session.setCategory(.playAndRecord, mode: .voiceChat, options: [.allowBluetooth])
          try session.setActive(true)
          result(nil)
        } catch {
          result(FlutterError(code: "ERROR", message: error.localizedDescription, details: nil))
        }
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```

### Step 2: Use Audio Router

```dart
import 'package:audio_router/audio_router.dart';

final audioRouter = AudioRouter();

// Show device picker
await audioRouter.showAudioRoutePicker(context);

// Monitor current device
audioRouter.currentDeviceStream.listen((device) {
  print('Current device: ${device?.type}');
});
```

### Step 3: (Android Only) Customize Device Filtering

By default, Android shows only communication devices. For music apps, use media mode:

```dart
// For VoIP/calls (default)
await audioRouter.showAudioRoutePicker(context);

// For music/media playback
await audioRouter.showAudioRoutePicker(
  context,
  androidOptions: AndroidAudioOptions.media(),
);

// Show all devices
await audioRouter.showAudioRoutePicker(
  context,
  androidOptions: AndroidAudioOptions.all(),
);
```

**Note:** `androidOptions` is ignored on iOS.

### Complete Example

```dart
import 'package:flutter/material.dart';
import 'package:audio_router/audio_router.dart';
import 'dart:async';

class CallScreen extends StatefulWidget {
  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  final _audioRouter = AudioRouter();
  StreamSubscription<AudioDevice?>? _subscription;
  AudioDevice? _currentDevice;

  @override
  void initState() {
    super.initState();
    _subscription = _audioRouter.currentDeviceStream.listen((device) {
      setState(() => _currentDevice = device);
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Call')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Audio output: ${_deviceName(_currentDevice?.type)}',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => _audioRouter.showAudioRoutePicker(context),
              icon: Icon(Icons.volume_up),
              label: Text('Change Audio Output'),
            ),
          ],
        ),
      ),
    );
  }

  String _deviceName(AudioSourceType? type) {
    switch (type) {
      case AudioSourceType.builtinSpeaker: return 'Speaker';
      case AudioSourceType.builtinReceiver: return 'Phone';
      case AudioSourceType.bluetooth: return 'Bluetooth';
      case AudioSourceType.wiredHeadset: return 'Headset';
      case AudioSourceType.usb: return 'USB';
      case AudioSourceType.carAudio: return 'Car';
      case AudioSourceType.airplay: return 'AirPlay';
      default: return 'Unknown';
    }
  }
}
```

## API Reference

### AudioRouter

Main class for managing audio routing.

#### Methods

**`showAudioRoutePicker(BuildContext context, {AndroidAudioOptions? androidOptions})`**

Shows the native audio device picker UI only. This method does not perform any automatic toggle logic.

- **iOS**: Displays native AVRoutePickerView
- **Android**: Shows Material Design 3 dialog with available devices

```dart
// Basic
await audioRouter.showAudioRoutePicker(context);

// Android: Show media devices
await audioRouter.showAudioRoutePicker(
  context,
  androidOptions: AndroidAudioOptions.media(),
);
```

**`tryChangeAudioRoute(BuildContext context, {AndroidAudioOptions? androidOptions})`**

Tries to change the audio route. Automatically shows picker if external devices are available, otherwise toggles between built-in devices.

- **iOS**: Shows picker if external devices available, otherwise toggles speaker/receiver
- **Android**: Shows dialog if external devices available, otherwise toggles speaker/receiver

```dart
// Basic
await audioRouter.tryChangeAudioRoute(context);

// Android: Show media devices
await audioRouter.tryChangeAudioRoute(
  context,
  androidOptions: AndroidAudioOptions.media(),
);
```

**`toggleSpeakerMode()`**

Toggles between built-in speaker and receiver only. Does not show any picker UI.

- **iOS**: Toggles between speaker and receiver
- **Android**: Toggles between built-in speaker and receiver

```dart
await audioRouter.toggleSpeakerMode();
```

#### Properties

**`currentDeviceStream`** → `Stream<AudioDevice?>`

Emits the current audio device whenever it changes.

```dart
audioRouter.currentDeviceStream.listen((device) {
  print('Device: ${device?.type}');
});
```

### AudioDevice

Represents an audio device.

```dart
class AudioDevice {
  final String id;              // Unique ID
  final AudioSourceType type;   // Device type
}
```

### AudioSourceType

Available device types:

```dart
enum AudioSourceType {
  builtinSpeaker,   // Phone speaker
  builtinReceiver,  // Phone earpiece
  bluetooth,        // Bluetooth devices
  wiredHeadset,     // Wired headphones
  usb,              // USB audio
  carAudio,         // Car audio (iOS only)
  airplay,          // AirPlay (iOS only)
  unknown,
}
```

### AndroidAudioOptions

Android device filtering options.

```dart
// For VoIP calls (default)
AndroidAudioOptions.communication()

// For music playback
AndroidAudioOptions.media()

// All devices
AndroidAudioOptions.all()

// Custom
AndroidAudioOptions(filter: AndroidAudioDeviceFilter.media)
```

## Supported Devices

| Device Type | iOS | Android | Notes |
|-------------|-----|---------|-------|
| Built-in Speaker | ✅ | ✅ | |
| Built-in Receiver/Earpiece | ✅ | ✅ | |
| Bluetooth | ✅ | ✅ | Android: SCO for calls, A2DP for media |
| Wired Headset | ✅ | ✅ | |
| USB Headset | ✅ | ⚠️ | Android: Limited support, may not work for calls |
| Car Audio | ✅ | ❌ | iOS only |
| AirPlay | ✅ | ❌ | iOS only |

### Android USB Limitations

USB headsets have limited support on Android:
- Only `TYPE_USB_HEADSET` is shown (not general USB devices)
- May not work for VoIP calls depending on hardware/manufacturer
- Some devices (especially Samsung) can't use USB for calls
- If USB fails, you'll get an error event

**Recommendation:** Don't rely on USB for Android call audio. Wired 3.5mm headsets work fine.

## Platform Implementation Details

### iOS
- Uses Apple's native `AVRoutePickerView`
- System automatically manages device switching
- Monitors `AVAudioSession.routeChangeNotification`
- Supports all Apple audio devices

### Android (API 29+)
- Custom Material Design 3 dialog
- Uses `AudioManager.setCommunicationDevice()` for switching
- Monitors `AudioDeviceCallback` for device changes
- **Device Filtering:**
  - `communication` mode: SCO Bluetooth, USB headsets only
  - `media` mode: A2DP Bluetooth, all USB devices
- Verifies device switches (100ms delay to confirm)
- Special error handling for USB devices

## Important Notes

1. **Audio session setup is required** - The plugin won't work without proper audio session configuration
2. **Optimized for calls** - Default settings filter devices for communication, not music playback
3. **BuildContext needed** - Pass a valid context to `showAudioRoutePicker()`
4. **USB on Android is tricky** - Don't depend on it for VoIP calls
5. **No auto-switching** - Devices aren't automatically selected when connected; users must choose

## Example App

For a complete working example, see the example app in the [GitHub repository](https://github.com/vagabondms/audio_router).

## Troubleshooting

**Audio routing doesn't work**
- ✅ Did you set up the audio session first?
- ✅ Is audio mode set to `MODE_IN_COMMUNICATION` (Android) or `.voiceChat` (iOS)?

**Bluetooth device not showing (Android)**
- ✅ Is Bluetooth connected?
- ✅ Are you using default `communication` mode? (Only SCO Bluetooth shown, not A2DP music devices)
- ✅ Try `AndroidAudioOptions.media()` if you need A2DP devices

**USB doesn't work (Android)**
- ✅ This is expected - USB support for calls is limited on Android
- ✅ Use wired 3.5mm headsets instead

## License

MIT License - See [LICENSE](./LICENSE) file for details.
