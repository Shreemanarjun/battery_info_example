import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:battery_info_example/battery_info_example.dart';
import 'package:battery_info_example/battery_info_jni_wrapper.dart';
import 'package:battery_info_example/battery_info_ffi_wrapper.dart';

// Plugin instance provider
final batteryInfoPluginProvider = Provider<BatteryInfoExample>((ref) {
  return BatteryInfoExample();
});

// Native wrapper providers (singleton instances)
final batteryInfoJniProvider = Provider<BatteryInfoJniWrapper?>((ref) {
  if (Platform.isAndroid) {
    return BatteryInfoJniWrapper();
  }
  return null;
});

final batteryInfoFfiProvider = Provider<BatteryInfoFfiWrapper?>((ref) {
  if (Platform.isIOS) {
    return BatteryInfoFfiWrapper();
  }
  return null;
});

// Native approach label provider
final nativeApproachProvider = Provider<String>((ref) {
  if (Platform.isAndroid) {
    return "JNI (Direct FFI)";
  } else if (Platform.isIOS) {
    return "FFI (C Functions)";
  }
  return "Unknown";
});

// State providers using StateNotifier
class BatteryState {
  final int platformLevel;
  final String platformTime;
  final int nativeLevel;
  final String nativeTime;
  final bool isCharging;
  final int temperature;

  const BatteryState({
    this.platformLevel = -1,
    this.platformTime = '',
    this.nativeLevel = -1,
    this.nativeTime = '',
    this.isCharging = false,
    this.temperature = -1,
  });

  BatteryState copyWith({
    int? platformLevel,
    String? platformTime,
    int? nativeLevel,
    String? nativeTime,
    bool? isCharging,
    int? temperature,
  }) {
    return BatteryState(
      platformLevel: platformLevel ?? this.platformLevel,
      platformTime: platformTime ?? this.platformTime,
      nativeLevel: nativeLevel ?? this.nativeLevel,
      nativeTime: nativeTime ?? this.nativeTime,
      isCharging: isCharging ?? this.isCharging,
      temperature: temperature ?? this.temperature,
    );
  }
}

class BatteryNotifier extends StateNotifier<BatteryState> {
  BatteryNotifier(this.ref) : super(const BatteryState()) {
    _initializeBatteryInfo();
  }

  final Ref ref;
  Timer? _autoBenchmarkTimer;

  void _initializeBatteryInfo() {
    // Delay initial battery level calls until after the first frame
    Future.microtask(() {
      _getBatteryLevelPlatform();
      _getBatteryLevelNative();
    });
  }

  Future<void> _getBatteryLevelPlatform() async {
    final plugin = ref.read(batteryInfoPluginProvider);
    final Stopwatch stopwatch = Stopwatch()..start();
    try {
      final batteryLevel = await plugin.getBatteryLevel();
      final elapsed = stopwatch.elapsedMicroseconds;
      stopwatch.stop();
      state = state.copyWith(
        platformLevel: batteryLevel,
        platformTime: '$elapsed μs',
      );
    } catch (e) {
      final elapsed = stopwatch.elapsedMicroseconds;
      stopwatch.stop();
      state = state.copyWith(
        platformLevel: -1,
        platformTime: '$elapsed μs (Error)',
      );
    }
  }

  Future<void> _getBatteryLevelNative() async {
    final Stopwatch stopwatch = Stopwatch()..start();
    try {
      int batteryLevel = -1;
      bool isCharging = false;
      int temperature = -1;

      if (Platform.isAndroid) {
        final jni = ref.read(batteryInfoJniProvider);
        if (jni != null) {
          batteryLevel = jni.getBatteryLevel();
          isCharging = jni.isCharging();
          temperature = jni.getTemperature();
        }
      } else if (Platform.isIOS) {
        final ffi = ref.read(batteryInfoFfiProvider);
        if (ffi != null) {
          batteryLevel = ffi.getBatteryLevel();
          isCharging = ffi.isCharging();
          temperature = -1; // Temperature not available via iOS FFI
        }
      }

      final elapsed = stopwatch.elapsedMicroseconds;
      stopwatch.stop();
      state = state.copyWith(
        nativeLevel: batteryLevel,
        nativeTime: '$elapsed μs',
        isCharging: isCharging,
        temperature: temperature,
      );
    } catch (e) {
      state = state.copyWith(
        nativeLevel: -1,
        nativeTime: 'Error: $e',
      );
    }
  }

  Future<void> refreshBatteryInfo() async {
    // Run benchmarks sequentially for more accurate timing
    await _getBatteryLevelPlatform();
    await _getBatteryLevelNative();

    // Update benchmark statistics
    ref.read(benchmarkStatisticsProvider.notifier).addBenchmarkRun(
      platformTime: int.tryParse(state.platformTime.replaceAll(RegExp(r'[^\d]'), '')) ?? 0,
      nativeTime: int.tryParse(state.nativeTime.replaceAll(RegExp(r'[^\d]'), '')) ?? 0,
    );
  }

  Future<void> refreshChargingAndTemperature() async {
    if (Platform.isAndroid) {
      final jni = ref.read(batteryInfoJniProvider);
      if (jni != null) {
        final isCharging = jni.isCharging();
        final temperature = jni.getTemperature();
        state = state.copyWith(
          isCharging: isCharging,
          temperature: temperature,
        );
      }
    } else if (Platform.isIOS) {
      final ffi = ref.read(batteryInfoFfiProvider);
      if (ffi != null) {
        final isCharging = ffi.isCharging();
        state = state.copyWith(
          isCharging: isCharging,
          temperature: -1, // Temperature not available via iOS FFI
        );
      }
    }
  }

  void toggleAutoBenchmark() {
    final currentEnabled = ref.read(autoBenchmarkEnabledProvider);
    ref.read(autoBenchmarkEnabledProvider.notifier).state = !currentEnabled;

    if (!currentEnabled) {
      // Start auto benchmarking
      _autoBenchmarkTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
        refreshBatteryInfo();
      });
    } else {
      // Stop auto benchmarking
      _autoBenchmarkTimer?.cancel();
      _autoBenchmarkTimer = null;
    }
  }

  @override
  void dispose() {
    _autoBenchmarkTimer?.cancel();
    super.dispose();
  }
}

final batteryProvider = StateNotifierProvider<BatteryNotifier, BatteryState>((ref) {
  return BatteryNotifier(ref);
});

// Benchmark statistics provider
class BenchmarkStatistics {
  final List<int> platformTimes;
  final List<int> nativeTimes;
  final int runCount;

  const BenchmarkStatistics({
    this.platformTimes = const [],
    this.nativeTimes = const [],
    this.runCount = 0,
  });

  double get avgPlatformTime => platformTimes.isEmpty ? 0.0 :
    platformTimes.reduce((a, b) => a + b) / platformTimes.length;

  double get avgNativeTime => nativeTimes.isEmpty ? 0.0 :
    nativeTimes.reduce((a, b) => a + b) / nativeTimes.length;

  BenchmarkStatistics copyWith({
    List<int>? platformTimes,
    List<int>? nativeTimes,
    int? runCount,
  }) {
    return BenchmarkStatistics(
      platformTimes: platformTimes ?? this.platformTimes,
      nativeTimes: nativeTimes ?? this.nativeTimes,
      runCount: runCount ?? this.runCount,
    );
  }
}

class BenchmarkStatisticsNotifier extends StateNotifier<BenchmarkStatistics> {
  BenchmarkStatisticsNotifier() : super(const BenchmarkStatistics());

  void addBenchmarkRun({required int platformTime, required int nativeTime}) {
    if (platformTime > 0 && nativeTime > 0) {
      state = state.copyWith(
        platformTimes: [...state.platformTimes, platformTime],
        nativeTimes: [...state.nativeTimes, nativeTime],
        runCount: state.runCount + 1,
      );
    }
  }

  void reset() {
    state = const BenchmarkStatistics();
  }
}

final benchmarkStatisticsProvider = StateNotifierProvider<BenchmarkStatisticsNotifier, BenchmarkStatistics>((ref) {
  return BenchmarkStatisticsNotifier();
});

// UI state providers
final showInMillisecondsProvider = StateNotifierProvider<ShowInMillisecondsNotifier, bool>((ref) {
  return ShowInMillisecondsNotifier();
});

class ShowInMillisecondsNotifier extends StateNotifier<bool> {
  ShowInMillisecondsNotifier() : super(false);

  void toggle() {
    state = !state;
  }

  void setValue(bool value) {
    state = value;
  }
}

final autoBenchmarkEnabledProvider = StateNotifierProvider<AutoBenchmarkEnabledNotifier, bool>((ref) {
  return AutoBenchmarkEnabledNotifier();
});

class AutoBenchmarkEnabledNotifier extends StateNotifier<bool> {
  AutoBenchmarkEnabledNotifier() : super(false);
}

// Flutter version provider
final flutterVersionProvider = StateNotifierProvider<FlutterVersionNotifier, String>((ref) {
  return FlutterVersionNotifier();
});

class FlutterVersionNotifier extends StateNotifier<String> {
  FlutterVersionNotifier() : super("") {
    _fetchVersion();
  }

  void _fetchVersion() async {
    try {
      // Import the version package
      // This would need to be imported at the top of the file
      // import 'package:flutter/foundation.dart' show kIsWeb;
      // For now, we'll use a placeholder
      state = "3.x.x"; // This would be replaced with actual version fetching
    } catch (e) {
      state = 'unknown';
    }
  }
}
