import 'package:flutter/material.dart';
import 'audio_source.dart';

/// Localized strings for the audio device picker dialog.
///
/// These strings are currently hardcoded in Korean. In the future, these can be
/// replaced with proper internationalization (i18n) support.
class AudioDevicePickerStrings {
  /// Dialog title
  static const String dialogTitle = '오디오 출력';

  /// Device type display names
  static const String builtinSpeaker = '스피커';
  static const String builtinReceiver = '휴대폰';
  static const String bluetooth = 'Bluetooth';
  static const String wiredHeadset = '이어폰';
  static const String carAudio = '차량 오디오';
  static const String airplay = 'AirPlay';
  static const String unknown = '알 수 없음';

  const AudioDevicePickerStrings._();
}

/// Material Design 3 오디오 디바이스 선택 다이얼로그
/// iOS AVRoutePickerView 스타일을 Material로 구현
class AudioDevicePickerDialog extends StatelessWidget {
  final List<AudioDevice> devices;
  final AudioDevice? currentDevice;

  const AudioDevicePickerDialog({
    super.key,
    required this.devices,
    this.currentDevice,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(AudioDevicePickerStrings.dialogTitle),
      contentPadding: const EdgeInsets.symmetric(vertical: 8),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.separated(
          shrinkWrap: true,
          itemCount: devices.length,
          separatorBuilder: (context, index) => const Divider(
            height: 1,
            indent: 56, // 아이콘 너비만큼 들여쓰기
          ),
          itemBuilder: (context, index) {
            final device = devices[index];
            final isSelected = device.id == currentDevice?.id;

            return ListTile(
              leading: Icon(
                _getDeviceIcon(device.type),
                size: 24,
              ),
              title: Text(_getDeviceDisplayName(device.type)),
              trailing: isSelected
                  ? Icon(
                      Icons.check,
                      color: Theme.of(context).colorScheme.primary,
                      size: 24,
                    )
                  : const SizedBox(width: 24), // 정렬 유지
              onTap: () => Navigator.pop(context, device),
            );
          },
        ),
      ),
    );
  }

  IconData _getDeviceIcon(AudioSourceType type) {
    switch (type) {
      case AudioSourceType.builtinSpeaker:
        return Icons.volume_up;
      case AudioSourceType.builtinReceiver:
        return Icons.phone_android;
      case AudioSourceType.bluetooth:
        return Icons.bluetooth_audio;
      case AudioSourceType.wiredHeadset:
        return Icons.headset;
      case AudioSourceType.carAudio:
        return Icons.directions_car;
      case AudioSourceType.airplay:
        return Icons.airplay;
      case AudioSourceType.unknown:
        return Icons.speaker;
    }
  }

  String _getDeviceDisplayName(AudioSourceType type) {
    switch (type) {
      case AudioSourceType.builtinSpeaker:
        return AudioDevicePickerStrings.builtinSpeaker;
      case AudioSourceType.builtinReceiver:
        return AudioDevicePickerStrings.builtinReceiver;
      case AudioSourceType.bluetooth:
        return AudioDevicePickerStrings.bluetooth;
      case AudioSourceType.wiredHeadset:
        return AudioDevicePickerStrings.wiredHeadset;
      case AudioSourceType.carAudio:
        return AudioDevicePickerStrings.carAudio;
      case AudioSourceType.airplay:
        return AudioDevicePickerStrings.airplay;
      case AudioSourceType.unknown:
        return AudioDevicePickerStrings.unknown;
    }
  }
}
