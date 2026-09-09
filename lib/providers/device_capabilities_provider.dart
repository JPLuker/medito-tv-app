import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medito/services/device_capabilities_service.dart';

final deviceCapabilitiesProvider = FutureProvider<DeviceCapabilities>((ref) async {
  return DeviceCapabilitiesService().detect();
});
