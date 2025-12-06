import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io' show Platform;

import 'package:battery_info_example/battery_info_example.dart';
import 'package:battery_info_example/battery_info_jni_wrapper.dart';
import 'package:battery_info_example/battery_info_ffi_wrapper.dart';
import 'package:flutter/services.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // Platform Channel approach
  int _batteryLevelPlatform = -1;
  String _batteryTimePlatform = '';

  // Native approach (JNI for Android, FFI for iOS)
  int _batteryLevelNative = -1;
  String _batteryTimeNative = '';
  bool _isChargingNative = false;
  int _temperatureNative = -1;

  // Average benchmark tracking
  final List<int> _platformTimes = [];
  final List<int> _nativeTimes = [];
  double _avgPlatformTime = 0.0;
  double _avgNativeTime = 0.0;
  int _benchmarkRuns = 0;

  final _batteryInfoPlugin = BatteryInfoExample();

  // Singleton instances for native wrappers - initialized once and reused
  static BatteryInfoJniWrapper? _batteryInfoJniInstance;
  static BatteryInfoFfiWrapper? _batteryInfoFfiInstance;

  BatteryInfoJniWrapper? get _batteryInfoJni {
    if (Platform.isAndroid && _batteryInfoJniInstance == null) {
      _batteryInfoJniInstance = BatteryInfoJniWrapper();
    }
    return _batteryInfoJniInstance;
  }

  BatteryInfoFfiWrapper? get _batteryInfoFfi {
    if (Platform.isIOS && _batteryInfoFfiInstance == null) {
      _batteryInfoFfiInstance = BatteryInfoFfiWrapper();
    }
    return _batteryInfoFfiInstance;
  }

  String _flutterVersion = "";
  String _nativeApproach = "";

  @override
  void initState() {
    super.initState();

    // Set native approach label
    if (Platform.isAndroid) {
      _nativeApproach = "JNI (Direct FFI)";
    } else if (Platform.isIOS) {
      _nativeApproach = "FFI (C Functions)";
    }

    _getBatteryLevelPlatform();
    _getBatteryLevelNative();
    _fetchFlutterVersion();
  }

  void _fetchFlutterVersion() async {
    try {
      setState(() {
        _flutterVersion = FlutterVersion.version ?? "";
      });
    } catch (e) {
      _flutterVersion = 'unknown';
      setState(() {});
    }
  }

  @override
  void dispose() {
    _batteryInfoJni?.dispose();
    super.dispose();
  }

  Future<void> _getBatteryLevelPlatform() async {
    final Stopwatch stopwatch = Stopwatch()..start();
    try {
      final batteryLevel = await _batteryInfoPlugin.getBatteryLevel();
      final elapsed = stopwatch.elapsedMicroseconds;
      stopwatch.stop();
      setState(() {
        _batteryLevelPlatform = batteryLevel;
        _batteryTimePlatform = '$elapsed μs';
      });
    } catch (e) {
      setState(() {
        _batteryLevelPlatform = -1;
        _batteryTimePlatform = 'Error: $e';
      });
    }
  }

  Future<void> _getBatteryLevelNative() async {
    final Stopwatch stopwatch = Stopwatch()..start();
    try {
      int batteryLevel = -1;
      bool isCharging = false;
      int temperature = -1;

      if (Platform.isAndroid && _batteryInfoJni != null) {
        batteryLevel = _batteryInfoJni!.getBatteryLevel();
        isCharging = _batteryInfoJni!.isCharging();
        temperature = _batteryInfoJni!.getTemperature();
      } else if (Platform.isIOS && _batteryInfoFfi != null) {
        batteryLevel = _batteryInfoFfi!.getBatteryLevel();
        isCharging = _batteryInfoFfi!.isCharging();
        temperature = -1; // Temperature not available via iOS FFI
      }

      final elapsed = stopwatch.elapsedMicroseconds;
      stopwatch.stop();
      setState(() {
        _batteryLevelNative = batteryLevel;
        _isChargingNative = isCharging;
        _temperatureNative = temperature;
        _batteryTimeNative = '$elapsed μs';
      });
    } catch (e) {
      setState(() {
        _batteryLevelNative = -1;
        _batteryTimeNative = 'Error: $e';
      });
    }
  }

  Future<void> _refreshBatteryInfo() async {
    await Future.wait([_getBatteryLevelPlatform(), _getBatteryLevelNative()]);

    // Track benchmark times for averages
    final platformTime =
        int.tryParse(_batteryTimePlatform.replaceAll(RegExp(r'[^\d]'), '')) ??
        0;
    final nativeTime =
        int.tryParse(_batteryTimeNative.replaceAll(RegExp(r'[^\d]'), '')) ?? 0;

    if (platformTime > 0 && nativeTime > 0) {
      setState(() {
        _platformTimes.add(platformTime);
        _nativeTimes.add(nativeTime);
        _benchmarkRuns++;

        // Calculate averages
        _avgPlatformTime =
            _platformTimes.reduce((a, b) => a + b) / _platformTimes.length;
        _avgNativeTime =
            _nativeTimes.reduce((a, b) => a + b) / _nativeTimes.length;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Flutter: Platform Channel vs JNI'),
          centerTitle: true,
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          elevation: 0,
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Theme.of(context).colorScheme.surface,
                Theme.of(context).colorScheme.surface.withValues(alpha: 0.95),
              ],
            ),
          ),
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Header Section
                    _buildHeaderSection(context),
                    const SizedBox(height: 32),

                    // Refresh Button
                    _buildRefreshButton(context),
                    const SizedBox(height: 32),

                    // Combined Platform Channel vs JNI Section
                    _buildSectionHeader(
                      context,
                      'Platform Channel vs $_nativeApproach',
                    ),
                    const SizedBox(height: 16),
                    _buildCombinedResultCard(context),
                    const SizedBox(height: 12),
                    _buildNativeDetailsCard(context),
                    const SizedBox(height: 32),

                    // Performance Comparison
                    _buildPerformanceComparison(context),
                    const SizedBox(height: 24),

                    // Average Benchmark Results
                    if (_benchmarkRuns > 0) _buildAverageBenchmarkCard(context),
                    const SizedBox(height: 40), // Extra space at bottom
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primaryContainer,
            Theme.of(context).colorScheme.secondaryContainer,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            Icons.battery_full,
            size: 48,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'Performance Benchmark',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
            textAlign: TextAlign.center,
          ),
          if (_flutterVersion.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.surface.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Flutter $_flutterVersion',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontFamily: 'monospace',
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRefreshButton(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.secondary,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: _refreshBatteryInfo,
        icon: const Icon(Icons.refresh, size: 28, color: Colors.white),
        label: const Text(
          'Run Benchmark',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          minimumSize: const Size(double.infinity, 60),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
    );
  }

  Widget _buildCombinedResultCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.grey.withValues(alpha: 0.05),
            Colors.grey.withValues(alpha: 0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.withValues(alpha: 0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Platform Channel (Left)
          Expanded(
            child: _buildSideResultCard(
              context,
              'Platform Channel',
              _batteryLevelPlatform >= 0 ? '$_batteryLevelPlatform%' : 'N/A',
              _batteryTimePlatform,
              Colors.blue,
            ),
          ),
          // Divider
          Container(
            width: 1,
            height: 80,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            color: Colors.grey.withValues(alpha: 0.3),
          ),
          // JNI/FFI (Right)
          Expanded(
            child: _buildSideResultCard(
              context,
              _nativeApproach,
              _batteryLevelNative >= 0 ? '$_batteryLevelNative%' : 'N/A',
              _batteryTimeNative,
              Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSideResultCard(
    BuildContext context,
    String title,
    String value,
    String time,
    Color color,
  ) {
    return Column(
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: color.withValues(alpha: 0.8),
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.battery_std, size: 28, color: color),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
          ),
          child: Text(
            time,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontFamily: 'monospace',
              color: color.withValues(alpha: 0.9),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResultCard(
    BuildContext context,
    String value,
    String time,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.1), color.withValues(alpha: 0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.battery_std, size: 32, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: color.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    time,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontFamily: 'monospace',
                      color: color.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNativeDetailsCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.green.withValues(alpha: 0.1),
            Colors.green.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.green.withValues(alpha: 0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildDetailItem(
            context,
            _isChargingNative ? Icons.battery_charging_full : Icons.battery_std,
            _isChargingNative ? Colors.green : Colors.grey,
            _isChargingNative ? 'Charging' : 'Not Charging',
          ),
          if (Platform.isAndroid)
            Container(
              width: 1,
              height: 40,
              color: Colors.green.withValues(alpha: 0.3),
            ),
          if (Platform.isAndroid)
            _buildDetailItem(
              context,
              Icons.thermostat,
              Colors.orange,
              _temperatureNative >= 0 ? '$_temperatureNative°C' : 'N/A',
            ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(
    BuildContext context,
    IconData icon,
    Color color,
    String label,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 32),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: color.withValues(alpha: 0.9),
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildPerformanceComparison(BuildContext context) {
    final platformTime =
        int.tryParse(_batteryTimePlatform.replaceAll(RegExp(r'[^\d]'), '')) ??
        0;
    final nativeTime =
        int.tryParse(_batteryTimeNative.replaceAll(RegExp(r'[^\d]'), '')) ?? 0;

    String speedup = '';
    String nativeLabel = Platform.isAndroid ? 'JNI' : 'FFI';
    if (platformTime > 0 && nativeTime > 0) {
      final ratio = (platformTime / nativeTime).toStringAsFixed(1);
      speedup = '${ratio}x faster';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.orange.withValues(alpha: 0.1),
            Colors.orange.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.orange.withValues(alpha: 0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.speed,
                  color: Colors.orange.shade700,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Benchmark Results',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.orange.shade900,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (speedup.isNotEmpty)
                      Text(
                        '$nativeLabel is $speedup',
                        style: TextStyle(
                          color: Colors.orange.shade700,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildCompactTimeItem(
                context,
                'Platform',
                _batteryTimePlatform,
                Colors.blue,
              ),
              Container(
                width: 1,
                height: 35,
                color: Colors.orange.withValues(alpha: 0.3),
              ),
              _buildCompactTimeItem(
                context,
                nativeLabel,
                _batteryTimeNative,
                Colors.green,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeComparisonItem(
    BuildContext context,
    String label,
    String time,
    Color color,
  ) {
    return Column(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: color.withValues(alpha: 0.8),
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
          ),
          child: Text(
            time,
            style: TextStyle(
              color: color.withValues(alpha: 0.9),
              fontFamily: 'monospace',
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAverageBenchmarkCard(BuildContext context) {
    final nativeLabel = Platform.isAndroid ? 'JNI' : 'FFI';
    String avgSpeedup = '';
    if (_avgPlatformTime > 0 && _avgNativeTime > 0) {
      final ratio = (_avgPlatformTime / _avgNativeTime).toStringAsFixed(1);
      avgSpeedup = '${ratio}x faster';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.purple.withValues(alpha: 0.1),
            Colors.purple.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.purple.withValues(alpha: 0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.purple.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.analytics,
                  color: Colors.purple.shade700,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Average Benchmark',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.purple.shade900,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '$_benchmarkRuns runs',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.purple.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (avgSpeedup.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.purple.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.trending_up,
                    color: Colors.purple.shade900,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$nativeLabel is $avgSpeedup (avg)',
                    style: TextStyle(
                      color: Colors.purple.shade900,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildCompactTimeItem(
                context,
                'Platform',
                '${_avgPlatformTime.toStringAsFixed(0)} μs',
                Colors.blue,
              ),
              Container(
                width: 1,
                height: 30,
                color: Colors.purple.withValues(alpha: 0.3),
              ),
              _buildCompactTimeItem(
                context,
                nativeLabel,
                '${_avgNativeTime.toStringAsFixed(0)} μs',
                Colors.green,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompactTimeItem(
    BuildContext context,
    String label,
    String time,
    Color color,
  ) {
    return Column(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: color.withValues(alpha: 0.8),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          time,
          style: TextStyle(
            color: color.withValues(alpha: 0.9),
            fontFamily: 'monospace',
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
