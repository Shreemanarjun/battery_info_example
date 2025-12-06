import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'widgets/benchmark_widgets.dart';
import 'providers.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nativeApproach = ref.watch(nativeApproachProvider);

    return Scaffold(
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
                  const HeaderSection(),
                  const SizedBox(height: 32),

                  // Refresh Button
                  const RefreshButton(),
                  const SizedBox(height: 16),

                  // Timing Mode Toggle
                  const TimingModeToggle(),
                  const SizedBox(height: 16),

                  // Auto Benchmark Toggle
                  const AutoBenchmarkToggle(),
                  const SizedBox(height: 16),

                  // Refresh Charging & Temperature Button
                  const RefreshChargingButton(),
                  const SizedBox(height: 16),

                  // Combined Platform Channel vs JNI Section
                  _buildSectionHeader(
                    context,
                    'Platform Channel vs $nativeApproach',
                  ),
                  const SizedBox(height: 16),
                  const CombinedResultCard(),
                  const SizedBox(height: 12),
                  const NativeDetailsCard(),
                  const SizedBox(height: 32),

                  // Performance Comparison
                  const PerformanceComparison(),
                  const SizedBox(height: 24),

                  // Average Benchmark Results
                  const AverageBenchmarkCard(),
                  const SizedBox(height: 40), // Extra space at bottom
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
    );
  }
}

// Additional stateless widgets that need Riverpod
class RefreshChargingButton extends ConsumerWidget {
  const RefreshChargingButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.teal.shade400,
            Colors.teal.shade600,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.shade200.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: () => ref.read(batteryProvider.notifier).refreshChargingAndTemperature(),
        icon: const Icon(Icons.thermostat, size: 24, color: Colors.white),
        label: const Text(
          'Refresh Charging & Temperature',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}

class NativeDetailsCard extends ConsumerWidget {
  const NativeDetailsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final batteryState = ref.watch(batteryProvider);
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
            batteryState.isCharging ? Icons.battery_charging_full : Icons.battery_std,
            batteryState.isCharging ? Colors.green : Colors.grey,
            batteryState.isCharging ? 'Charging' : 'Not Charging',
          ),
          if (batteryState.temperature >= 0) ...[
            Container(
              width: 1,
              height: 40,
              color: Colors.green.withValues(alpha: 0.3),
            ),
            _buildDetailItem(
              context,
              Icons.thermostat,
              Colors.orange,
              '${batteryState.temperature}°C',
            ),
          ],
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
}

class PerformanceComparison extends ConsumerWidget {
  const PerformanceComparison({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final batteryState = ref.watch(batteryProvider);
    final showInMilliseconds = ref.watch(showInMillisecondsProvider);
    final nativeApproach = ref.watch(nativeApproachProvider);

    final platformTime = int.tryParse(batteryState.platformTime.replaceAll(RegExp(r'[^\d]'), '')) ?? 0;
    final nativeTime = int.tryParse(batteryState.nativeTime.replaceAll(RegExp(r'[^\d]'), '')) ?? 0;

    String speedup = '';
    String fasterMethod = '';
    if (platformTime > 0 && nativeTime > 0) {
      if (nativeTime < platformTime) {
        // Native (JNI/FFI) is faster
        final ratio = (platformTime / nativeTime).toStringAsFixed(1);
        speedup = '${ratio}x faster';
        fasterMethod = nativeApproach;
      } else if (platformTime < nativeTime) {
        // Platform Channel is faster
        final ratio = (nativeTime / platformTime).toStringAsFixed(1);
        speedup = '${ratio}x faster';
        fasterMethod = 'Platform Channel';
      } else {
        // They are equal
        speedup = 'Equal performance';
        fasterMethod = 'Both methods';
      }
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
                        '$fasterMethod $speedup',
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
                _formatTime(batteryState.platformTime, showInMilliseconds),
                Colors.blue,
              ),
              Container(
                width: 1,
                height: 35,
                color: Colors.orange.withValues(alpha: 0.3),
              ),
              _buildCompactTimeItem(
                context,
                'JNI',
                _formatTime(batteryState.nativeTime, showInMilliseconds),
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

  String _formatTime(String timeString, bool showInMilliseconds) {
    final microseconds = int.tryParse(timeString.replaceAll(RegExp(r'[^\d]'), '')) ?? 0;
    if (showInMilliseconds) {
      final milliseconds = microseconds / 1000.0;
      return '${milliseconds.toStringAsFixed(2)} ms';
    } else {
      return '$microseconds μs';
    }
  }
}

class AverageBenchmarkCard extends ConsumerWidget {
  const AverageBenchmarkCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(benchmarkStatisticsProvider);
    final showInMilliseconds = ref.watch(showInMillisecondsProvider);
    final nativeApproach = ref.watch(nativeApproachProvider);

    if (stats.runCount == 0) {
      return const SizedBox.shrink();
    }

    String avgSpeedup = '';
    String fasterMethod = '';
    if (stats.avgPlatformTime > 0 && stats.avgNativeTime > 0) {
      if (stats.avgNativeTime < stats.avgPlatformTime) {
        // Native (JNI/FFI) is faster
        final ratio = (stats.avgPlatformTime / stats.avgNativeTime).toStringAsFixed(1);
        avgSpeedup = '${ratio}x faster';
        fasterMethod = nativeApproach;
      } else if (stats.avgPlatformTime < stats.avgNativeTime) {
        // Platform Channel is faster
        final ratio = (stats.avgNativeTime / stats.avgPlatformTime).toStringAsFixed(1);
        avgSpeedup = '${ratio}x faster';
        fasterMethod = 'Platform Channel';
      } else {
        // They are equal
        avgSpeedup = 'Equal performance';
        fasterMethod = 'Both methods';
      }
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
                      '${stats.runCount} runs',
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
                    '$fasterMethod $avgSpeedup (avg)',
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
                _formatTime(stats.avgPlatformTime.round(), showInMilliseconds),
                Colors.blue,
              ),
              Container(
                width: 1,
                height: 30,
                color: Colors.purple.withValues(alpha: 0.3),
              ),
              _buildCompactTimeItem(
                context,
                'JNI',
                _formatTime(stats.avgNativeTime.round(), showInMilliseconds),
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

  String _formatTime(int microseconds, bool showInMilliseconds) {
    if (showInMilliseconds) {
      final milliseconds = microseconds / 1000.0;
      return '${milliseconds.toStringAsFixed(2)} ms';
    } else {
      return '$microseconds μs';
    }
  }
}
