import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'audio_router.dart';
import 'audio_router_platform_interface.dart';

/// An implementation of [AudioRouterPlatform] that uses method channels.
class MethodChannelAudioRouter extends AudioRouterPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('audio_router');

  /// The event channel used to receive audio state changes from the native platform.
  @visibleForTesting
  final eventChannel = const EventChannel('audio_router/events');

  late final Stream<AudioState> _audioStateStream;

  /// Constructor
  MethodChannelAudioRouter() {
    _audioStateStream = eventChannel
        .receiveBroadcastStream()
        .map(_toAudioState)
        .where((state) => state != null)
        .cast<AudioState>()
        .handleError(_onError);
  }

  AudioState? _toAudioState(dynamic event) {
    final data = event as Map?;
    if (data == null) {
      return null;
    }

    // Parse available devices
    final availableDevices = _parseAvailableDevices(data);

    // Parse selected device
    final selectedDevice = _parseSelectedDevice(data);

    return AudioState(
      availableDevices: availableDevices,
      selectedDevice: selectedDevice,
    );
  }

  /// Parses available devices from the event data.
  List<AudioDevice> _parseAvailableDevices(Map data) {
    final devicesData = data['availableDevices'] as List?;
    if (devicesData == null) {
      return [];
    }

    final devices = <AudioDevice>[];
    for (final deviceData in devicesData) {
      if (deviceData is Map) {
        devices.add(AudioDevice.fromMap(deviceData));
      }
    }
    return devices;
  }

  /// Parses selected device from the event data.
  AudioDevice? _parseSelectedDevice(Map data) {
    final deviceData = data['selectedDevice'] as Map?;
    if (deviceData == null) {
      return null;
    }
    return AudioDevice.fromMap(deviceData);
  }

  void _onError(Object error) {
    debugPrint('Audio state stream error: $error');
  }

  @override
  Future<void> showAudioRoutePicker() async {
    await methodChannel.invokeMethod<void>('showAudioRoutePicker');
  }

  @override
  Future<List<AudioDevice>> getAvailableDevices({
    AndroidAudioOptions androidAudioOptions = const AndroidAudioOptions(),
  }) async {
    try {
      final result = await methodChannel.invokeMethod<List>(
        'getAvailableDevices',
        androidAudioOptions.toMap(),
      );
      if (result == null) return [];

      return result.map((data) => AudioDevice.fromMap(data as Map)).toList();
    } catch (e) {
      // Query operations can fail silently and return empty list
      debugPrint('getAvailableDevices error: $e');
      return [];
    }
  }

  @override
  Future<void> setAudioDevice(String deviceId) async {
    try {
      await methodChannel.invokeMethod<void>(
        'setAudioDevice',
        {'deviceId': deviceId},
      );
    } catch (e) {
      debugPrint('setAudioDevice error: $e');
      // Device switching is important, but we don't want to break the app
      // if it fails. Log the error and continue silently.
    }
  }

  @override
  Future<AudioDevice?> getCurrentDevice() async {
    try {
      final result = await methodChannel.invokeMethod<Map>('getCurrentDevice');
      if (result == null) return null;
      return AudioDevice.fromMap(result);
    } catch (e) {
      // Query operations can fail silently and return null
      debugPrint('getCurrentDevice error: $e');
      return null;
    }
  }

  @override
  Stream<AudioState> get audioStateStream => _audioStateStream;

  @override
  Future<bool> hasExternalDevices() async {
    try {
      final result =
          await methodChannel.invokeMethod<bool>('hasExternalDevices');
      return result ?? false;
    } catch (e) {
      // Query operations can fail silently and return false
      debugPrint('hasExternalDevices error: $e');
      return false;
    }
  }

  @override
  Future<void> toggleSpeakerReceiver() async {
    try {
      await methodChannel.invokeMethod<void>('toggleSpeakerReceiver');
    } catch (e) {
      // Device switching is important, but we don't want to break the app
      // if it fails. Log the error and continue silently.
      debugPrint('toggleSpeakerReceiver error: $e');
    }
  }
}
