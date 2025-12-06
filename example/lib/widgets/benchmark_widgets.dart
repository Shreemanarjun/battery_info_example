import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers.dart';

// Stateless widget for the header section
class HeaderSection extends ConsumerWidget {
  const HeaderSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final version = ref.watch(flutterVersionProvider);
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
          if (version.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Flutter $version',
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
}

// Stateless widget for the refresh button
class RefreshButton extends ConsumerWidget {
  const RefreshButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
        onPressed: () => ref.read(batteryProvider.notifier).refreshBatteryInfo(),
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
}

// Stateless widget for timing mode toggle
class TimingModeToggle extends ConsumerWidget {
  const TimingModeToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showInMilliseconds = ref.watch(showInMillisecondsProvider);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.access_time,
            size: 20,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Text(
            'Display in:',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: showInMilliseconds
                    ? Colors.teal.withValues(alpha: 0.3)
                    : Colors.blue.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                _buildTimingOption(context, ref, 'μs', false, showInMilliseconds),
                _buildTimingOption(context, ref, 'ms', true, showInMilliseconds),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimingOption(BuildContext context, WidgetRef ref, String label, bool isMilliseconds, bool currentValue) {
    final isSelected = currentValue == isMilliseconds;
    return GestureDetector(
      onTap: () {
        ref.read(showInMillisecondsProvider.notifier).setValue(isMilliseconds);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? (isMilliseconds ? Colors.teal.withValues(alpha: 0.1) : Colors.blue.withValues(alpha: 0.1))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? (isMilliseconds ? Colors.teal.shade700 : Colors.blue.shade700)
                : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

// Stateless widget for auto benchmark toggle
class AutoBenchmarkToggle extends ConsumerWidget {
  const AutoBenchmarkToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isEnabled = ref.watch(autoBenchmarkEnabledProvider);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isEnabled ? Icons.play_circle : Icons.pause_circle,
            size: 20,
            color: isEnabled ? Colors.green.shade600 : Colors.grey.shade600,
          ),
          const SizedBox(width: 8),
          Text(
            'Auto Benchmark:',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 12),
          Switch(
            value: isEnabled,
            onChanged: (_) => ref.read(batteryProvider.notifier).toggleAutoBenchmark(),
            activeThumbColor: Colors.green.shade600,
            activeTrackColor: Colors.green.shade200,
          ),
          const SizedBox(width: 8),
          Text(
            isEnabled ? 'ON (5s)' : 'OFF',
            style: TextStyle(
              color: isEnabled ? Colors.green.shade700 : Colors.grey.shade600,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

// Stateless widget for combined result card
class CombinedResultCard extends ConsumerWidget {
  const CombinedResultCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final batteryState = ref.watch(batteryProvider);
    final showInMilliseconds = ref.watch(showInMillisecondsProvider);
    final nativeApproach = ref.watch(nativeApproachProvider);

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
              batteryState.platformLevel >= 0 ? '${batteryState.platformLevel}%' : 'N/A',
              batteryState.platformTime,
              Colors.blue,
              showInMilliseconds,
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
              nativeApproach,
              batteryState.nativeLevel >= 0 ? '${batteryState.nativeLevel}%' : 'N/A',
              batteryState.nativeTime,
              Colors.green,
              showInMilliseconds,
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
    bool showInMilliseconds,
  ) {
    // Parse microseconds from time string
    final microseconds = int.tryParse(time.replaceAll(RegExp(r'[^\d]'), '')) ?? 0;
    final formattedTime = _formatTime(microseconds, showInMilliseconds);

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
            formattedTime,
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

  String _formatTime(int microseconds, bool showInMilliseconds) {
    if (showInMilliseconds) {
      final milliseconds = microseconds / 1000.0;
      return '${milliseconds.toStringAsFixed(2)} ms';
    } else {
      return '$microseconds μs';
    }
  }
}
