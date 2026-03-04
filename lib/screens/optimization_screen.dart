import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ocsafe_cyberguard/core/theme/app_theme.dart';
import 'package:ocsafe_cyberguard/providers/security_provider.dart';
import 'package:ocsafe_cyberguard/widgets/simple_card.dart';

/// Displays device health and optimization info.
class OptimizationScreen extends StatefulWidget {
  const OptimizationScreen({super.key});

  @override
  State<OptimizationScreen> createState() => _OptimizationScreenState();
}

class _OptimizationScreenState extends State<OptimizationScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SecurityProvider>().loadDeviceInfo();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Device Health')),
      body: Consumer<SecurityProvider>(
        builder: (context, provider, _) {
          final device = provider.deviceData;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Battery
              _buildSectionTitle(context, 'Battery'),
              SimpleCard(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _batteryColor(device?.batteryLevel ?? -1).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _batteryIcon(device?.batteryLevel ?? -1),
                        color: _batteryColor(device?.batteryLevel ?? -1),
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            (device != null && device.batteryLevel >= 0) ? '${device.batteryLevel}%' : 'Unknown',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  color: _batteryColor(device?.batteryLevel ?? -1),
                                ),
                          ),
                          Text('Battery Level',
                              style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                    ),
                    if (device != null && device.batteryLevel >= 0)
                      SizedBox(
                        width: 60,
                        height: 60,
                        child: CircularProgressIndicator(
                          value: device.batteryLevel / 100,
                          strokeWidth: 6,
                          backgroundColor: AppColors.surfaceLight,
                          valueColor: AlwaysStoppedAnimation(_batteryColor(device.batteryLevel)),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Device Info
              _buildSectionTitle(context, 'Device Information'),
              if (device != null) ...[
                _infoTile(context, 'Model', device.deviceModel, Icons.smartphone),
                _infoTile(context, 'Android Version', device.androidVersion, Icons.android),
                _infoTile(context, 'Storage Used', '${device.storageUsedPercentage}%', Icons.storage),
              ] else
                const SimpleCard(
                  child: Center(
                     child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(title, style: Theme.of(context).textTheme.titleLarge),
    );
  }

  Widget _infoTile(BuildContext context, String label, String value, IconData icon) {
    return SimpleCard(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 20),
          const SizedBox(width: 12),
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          const Spacer(),
          Text(value, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }

  Color _batteryColor(int level) {
    if (level < 0) return AppColors.textSecondary;
    if (level <= 20) return AppColors.error;
    if (level <= 50) return AppColors.warning;
    return AppColors.primary;
  }

  IconData _batteryIcon(int level) {
    if (level < 0) return Icons.battery_unknown;
    if (level <= 20) return Icons.battery_alert;
    if (level <= 50) return Icons.battery_3_bar;
    return Icons.battery_full;
  }
}
