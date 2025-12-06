import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';


class BatteryInfoExample {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('battery_info_example');

  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }

  Future<int> getBatteryLevel() async {
    try {
      final result = await methodChannel.invokeMethod('getBatteryLevel');
      if (result == null) {
        // Method channel returned null - plugin not responding
        throw Exception('Platform channel returned null - plugin may not be registered');
      }
      return result as int;
    } catch (e) {
      // Check if it's a MissingPluginException (plugin not registered)
      if (e is MissingPluginException) {
        throw Exception('Plugin not registered: ${e.message}');
      }
      // Re-throw as Exception to be caught in main.dart
      throw Exception('Failed to get battery level: ${e.toString()}');
    }
  }
}
