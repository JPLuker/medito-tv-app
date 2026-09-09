import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';

/// Runtime capabilities that can vary by Android form factor.
///
/// Keep feature detection centralized here instead of spreading model checks,
/// screen-size heuristics, or `Platform.isAndroid` branches through the UI.
class DeviceCapabilities {
  const DeviceCapabilities({
    required this.isAndroidTv,
    required this.hasTouchscreen,
    required this.hasFakeTouch,
  });

  const DeviceCapabilities.nonAndroid()
    : isAndroidTv = false,
      hasTouchscreen = true,
      hasFakeTouch = true;

  /// True when Android reports the Leanback system feature.
  final bool isAndroidTv;

  /// Whether the device reports a physical touchscreen.
  final bool hasTouchscreen;

  /// Whether the device reports a fake-touch pointing input device.
  final bool hasFakeTouch;

  /// TV layouts should be fully operable with focus + D-pad input.
  bool get requiresRemoteNavigation => isAndroidTv;
}

class DeviceCapabilitiesService {
  DeviceCapabilitiesService({DeviceInfoPlugin? deviceInfoPlugin})
    : _deviceInfoPlugin = deviceInfoPlugin ?? DeviceInfoPlugin();

  static const _leanbackFeature = 'android.software.leanback';
  static const _touchscreenFeature = 'android.hardware.touchscreen';
  static const _fakeTouchFeature = 'android.hardware.faketouch';

  final DeviceInfoPlugin _deviceInfoPlugin;

  Future<DeviceCapabilities> detect() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return const DeviceCapabilities.nonAndroid();
    }

    final androidInfo = await _deviceInfoPlugin.androidInfo;
    final features = androidInfo.systemFeatures.toSet();

    return DeviceCapabilities(
      isAndroidTv: features.contains(_leanbackFeature),
      hasTouchscreen: features.contains(_touchscreenFeature),
      hasFakeTouch: features.contains(_fakeTouchFeature),
    );
  }
}
