import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'android_audio_options.dart';
import 'audio_device_picker_dialog.dart';
import 'audio_router_platform_interface.dart';
import 'audio_source.dart';

// Export public API
export 'android_audio_options.dart';
export 'audio_source.dart';

/// Audio routing plugin for VoIP and communication apps.
///
/// This plugin manages audio output device selection within an existing audio session.
/// **Important**: The host app is responsible for setting up the audio session
/// (e.g., AudioManager.MODE_IN_COMMUNICATION on Android, AVAudioSession on iOS)
/// before using this plugin.
///
/// This plugin only handles:
/// - Audio output device selection UI
/// - Real-time device monitoring
/// - Route switching within the current audio session
///
/// This plugin does NOT handle:
/// - Audio session setup or configuration
/// - Audio mode management
/// - Recording device selection

/// Class containing audio state information
@immutable
class AudioState {
  /// List of available audio devices
  final List<AudioDevice> availableDevices;

  /// Currently selected audio device
  final AudioDevice? selectedDevice;

  const AudioState({
    this.availableDevices = const [],
    this.selectedDevice,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AudioState &&
        listEquals(other.availableDevices, availableDevices) &&
        other.selectedDevice == selectedDevice;
  }

  @override
  int get hashCode => Object.hash(
        Object.hashAll(availableDevices),
        selectedDevice,
      );

  @override
  String toString() =>
      'AudioState(availableDevices: ${availableDevices.length}, selectedDevice: $selectedDevice)';

  /// Create a copy of AudioState
  AudioState copyWith({
    List<AudioDevice>? availableDevices,
    AudioDevice? selectedDevice,
  }) {
    return AudioState(
      availableDevices: availableDevices ?? this.availableDevices,
      selectedDevice: selectedDevice ?? this.selectedDevice,
    );
  }
}

/// Main class for managing audio output routing.
///
/// **Important**: Before using this class, ensure the host app has configured
/// the audio session appropriately for your use case.
class AudioRouter {
  /// Creates an [AudioRouter] instance.
  const AudioRouter();

  /// Shows the audio route picker UI.
  ///
  /// This method only displays the picker UI without any automatic toggle logic.
  /// - **iOS**: Displays native AVRoutePickerView (system UI)
  /// - **Android**: Shows Material Design 3 dialog with available devices
  ///
  /// **Important**: The audio session must be configured by the host app
  /// before calling this method. Otherwise, device routing may not work correctly.
  ///
  /// [androidOptions] allows you to customize the device filtering on Android.
  /// By default, only communication devices are shown. For media apps, use
  /// `AndroidAudioOptions.media()`. This parameter is ignored on iOS.
  ///
  /// [deviceNames] is an optional map of custom device display names.
  /// If not provided, default English names will be used.
  ///
  /// [dialogTitle] is an optional custom dialog title.
  /// If not provided, default English title will be used.
  ///
  /// Example:
  /// ```dart
  /// // VoIP/Communication app (default)
  /// final audioRouter = AudioRouter();
  /// await audioRouter.showAudioRoutePicker(context);
  ///
  /// // Media playback app (includes A2DP Bluetooth)
  /// await audioRouter.showAudioRoutePicker(
  ///   context,
  ///   androidOptions: AndroidAudioOptions.media(),
  /// );
  ///
  /// // With custom names and title
  /// await audioRouter.showAudioRoutePicker(
  ///   context,
  ///   deviceNames: {
  ///     AudioSourceType.builtinSpeaker: 'Speaker',
  ///     AudioSourceType.builtinReceiver: 'Phone',
  ///   },
  ///   dialogTitle: 'Select Audio Output',
  /// );
  /// ```
  Future<void> showAudioRoutePicker(
    BuildContext context, {
    AndroidAudioOptions? androidOptions,
    Map<AudioSourceType, String>? deviceNames,
    String? dialogTitle,
  }) async {
    if (Platform.isIOS) {
      await AudioRouterPlatform.instance.showAudioRoutePicker();
    } else if (Platform.isAndroid) {
      await _showAndroidPickerOnly(
          context, androidOptions, deviceNames, dialogTitle);
    }
  }

  /// Tries to change the audio route.
  ///
  /// Depending on available devices, this method will either:
  /// - **iOS**: Show native AVRoutePickerView (if external devices available) or toggle between speaker/receiver
  /// - **Android**: Show Material Design 3 dialog (if external devices available) or toggle between speaker/receiver
  ///
  /// **Important**: The audio session must be configured by the host app
  /// before calling this method. Otherwise, device routing may not work correctly.
  ///
  /// [androidOptions] allows you to customize the device filtering on Android.
  /// By default, only communication devices are shown. For media apps, use
  /// `AndroidAudioOptions.media()`. This parameter is ignored on iOS.
  ///
  /// [deviceNames] is an optional map of custom device display names.
  /// If not provided, default English names will be used.
  ///
  /// [dialogTitle] is an optional custom dialog title.
  /// If not provided, default English title will be used.
  ///
  /// Example:
  /// ```dart
  /// // VoIP/Communication app (default)
  /// final audioRouter = AudioRouter();
  /// await audioRouter.tryChangeAudioRoute(context);
  ///
  /// // Media playback app (includes A2DP Bluetooth)
  /// await audioRouter.tryChangeAudioRoute(
  ///   context,
  ///   androidOptions: AndroidAudioOptions.media(),
  /// );
  ///
  /// // With custom names and title
  /// await audioRouter.tryChangeAudioRoute(
  ///   context,
  ///   deviceNames: {
  ///     AudioSourceType.builtinSpeaker: 'Speaker',
  ///     AudioSourceType.builtinReceiver: 'Phone',
  ///   },
  ///   dialogTitle: 'Select Audio Output',
  /// );
  /// ```
  Future<void> tryChangeAudioRoute(
    BuildContext context, {
    AndroidAudioOptions? androidOptions,
    Map<AudioSourceType, String>? deviceNames,
    String? dialogTitle,
  }) async {
    if (Platform.isIOS) {
      await _tryChangeIOSAudioRoute();
    } else if (Platform.isAndroid) {
      await _tryChangeAndroidAudioRoute(
          context, androidOptions, deviceNames, dialogTitle);
    }
  }

  /// Toggles between built-in speaker and receiver.
  ///
  /// This method only toggles between built-in devices (speaker and receiver).
  /// It does not show any picker UI or handle external devices.
  ///
  /// - **iOS**: Toggles between speaker and receiver
  /// - **Android**: Toggles between built-in speaker and receiver
  ///
  /// Example:
  /// ```dart
  /// final audioRouter = AudioRouter();
  /// await audioRouter.toggleSpeakerMode();
  /// ```
  Future<void> toggleSpeakerMode() async {
    if (Platform.isIOS) {
      await AudioRouterPlatform.instance.toggleSpeakerReceiver();
    } else if (Platform.isAndroid) {
      await _toggleAndroidBuiltInDevices();
    }
  }

  /// Shows the Android picker dialog only (no toggle logic).
  Future<void> _showAndroidPickerOnly(
    BuildContext context,
    AndroidAudioOptions? androidOptions,
    Map<AudioSourceType, String>? deviceNames,
    String? dialogTitle,
  ) async {
    if (!context.mounted) return;

    try {
      final devices = await AudioRouterPlatform.instance.getAvailableDevices(
        androidAudioOptions: androidOptions ?? const AndroidAudioOptions(),
      );

      await _showDevicePickerDialog(context, devices, deviceNames, dialogTitle);
    } catch (e) {
      debugPrint('Failed to show audio route picker: $e');
      rethrow;
    }
  }

  /// Tries to change audio route on iOS (picker or toggle based on external devices).
  Future<void> _tryChangeIOSAudioRoute() async {
    try {
      final hasExternal =
          await AudioRouterPlatform.instance.hasExternalDevices();

      if (hasExternal) {
        // External devices available: show native picker
        await AudioRouterPlatform.instance.showAudioRoutePicker();
      } else {
        // No external devices: toggle between speaker and receiver
        await AudioRouterPlatform.instance.toggleSpeakerReceiver();
      }
    } catch (e) {
      // If the initial attempt fails, try fallback to showing picker
      debugPrint('Failed to change audio route: $e');
      try {
        await AudioRouterPlatform.instance.showAudioRoutePicker();
      } catch (fallbackError) {
        // If fallback also fails, log and continue silently
        debugPrint('Fallback audio route change also failed: $fallbackError');
      }
    }
  }

  /// Tries to change audio route on Android (dialog or toggle based on available devices).
  Future<void> _tryChangeAndroidAudioRoute(
    BuildContext context,
    AndroidAudioOptions? androidOptions,
    Map<AudioSourceType, String>? deviceNames,
    String? dialogTitle,
  ) async {
    if (!context.mounted) return;

    try {
      final devices = await AudioRouterPlatform.instance.getAvailableDevices(
        androidAudioOptions: androidOptions ?? const AndroidAudioOptions(),
      );

      // Check if only built-in devices are available
      final hasOnlyBuiltInDevices = devices.every((device) =>
          device.type == AudioSourceType.builtinSpeaker ||
          device.type == AudioSourceType.builtinReceiver);

      if (hasOnlyBuiltInDevices) {
        // Only built-in devices: toggle between speaker and receiver
        await _toggleBuiltInDevices(devices);
      } else {
        // External devices available: show dialog
        await _showDevicePickerDialog(
            context, devices, deviceNames, dialogTitle);
      }
    } catch (e) {
      // Android route change is a critical user-facing operation.
      // Re-throw to allow the caller to handle the error appropriately.
      debugPrint('Failed to change audio route: $e');
      rethrow;
    }
  }

  /// Toggles between built-in speaker and receiver on Android.
  Future<void> _toggleBuiltInDevices(List<AudioDevice> devices) async {
    final currentDevice = await AudioRouterPlatform.instance.getCurrentDevice();

    if (currentDevice != null) {
      // Determine target device type (toggle)
      final targetType = currentDevice.type == AudioSourceType.builtinSpeaker
          ? AudioSourceType.builtinReceiver
          : AudioSourceType.builtinSpeaker;

      // Find the target device by type
      final targetDevice = devices.firstWhere(
        (device) => device.type == targetType,
        orElse: () => devices.first,
      );

      // Use the device ID directly, or use special IDs for built-in devices
      final targetDeviceId = targetDevice.type == AudioSourceType.builtinSpeaker
          ? AudioDeviceIds.builtinSpeaker
          : AudioDeviceIds.builtinReceiver;

      await AudioRouterPlatform.instance.setAudioDevice(targetDeviceId);
    }
  }

  /// Toggles between built-in speaker and receiver on Android.
  Future<void> _toggleAndroidBuiltInDevices() async {
    try {
      final devices = await AudioRouterPlatform.instance.getAvailableDevices();
      await _toggleBuiltInDevices(devices);
    } catch (e) {
      debugPrint('Failed to toggle speaker mode: $e');
      rethrow;
    }
  }

  /// Shows the device picker dialog and handles device selection.
  Future<void> _showDevicePickerDialog(
    BuildContext context,
    List<AudioDevice> devices,
    Map<AudioSourceType, String>? deviceNames,
    String? dialogTitle,
  ) async {
    // Get current device
    final currentDevice = await AudioRouterPlatform.instance.getCurrentDevice();

    if (!context.mounted) return;

    final selected = await showDialog<AudioDevice>(
      context: context,
      barrierDismissible: true,
      builder: (context) => AudioDevicePickerDialog(
        devices: devices,
        currentDevice: currentDevice,
        deviceNames: deviceNames,
        dialogTitle: dialogTitle,
      ),
    );

    if (selected != null && context.mounted) {
      await AudioRouterPlatform.instance.setAudioDevice(selected.id);
    }
  }

  /// Stream of current audio device changes.
  ///
  /// Emits the currently selected audio device whenever it changes.
  /// This includes both user-initiated changes and system-initiated changes
  /// (e.g., when a Bluetooth device is connected/disconnected).
  ///
  /// Example:
  /// ```dart
  /// final audioRouter = AudioRouter();
  /// audioRouter.currentDeviceStream.listen((device) {
  ///   print('Current device: ${device?.type}');
  /// });
  /// ```
  Stream<AudioDevice?> get currentDeviceStream =>
      AudioRouterPlatform.instance.audioStateStream
          .map((state) => state.selectedDevice);
}
