import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ocsafe_cyberguard/theme/app_theme.dart';
import 'package:ocsafe_cyberguard/providers/security_provider.dart';

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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Device Health', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22, letterSpacing: -0.5)),
        backgroundColor: AppColors.background,
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: Consumer<SecurityProvider>(
        builder: (context, provider, _) {
          final device = provider.deviceData;

          if (device == null) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            physics: const BouncingScrollPhysics(),
            children: [
              _buildSectionHeader('Hardware Status'),
              _buildBatteryCard(device),
              const SizedBox(height: 48),

              _buildSectionHeader('System Information'),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                  border: Border.all(color: AppColors.primary.withOpacity(0.05)),
                ),
                child: Column(
                  children: [
                    _infoTile(Icons.smartphone_rounded, 'Device Model', device.deviceModel),
                    _divider(),
                    _infoTile(Icons.android_rounded, 'Android Version', 'v${device.androidVersion}'),
                    _divider(),
                    _infoTile(Icons.storage_rounded, 'Storage Usage', '${device.storageUsedPercentage}% Used'),
                    _divider(),
                    _infoTile(Icons.memory_rounded, 'Security Patch', 'Latest Patch Applied'),
                  ],
                ),
              ),
              const SizedBox(height: 48),

              _buildSectionHeader('Health Summary'),
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.primary.withOpacity(0.1)),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.verified_rounded, color: AppColors.primary, size: 40),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'System Optimized',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Your hardware is performing optimally.\nNo immediate actions required.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 15, color: AppColors.textSecondary, height: 1.5, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 16),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w900,
          color: AppColors.textSecondary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildBatteryCard(dynamic device) {
    final level = (device.batteryLevel as num).toInt();
    final color = _batteryColor(level);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(color: AppColors.primary.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 72,
                height: 72,
                child: CircularProgressIndicator(
                  value: level / 100,
                  strokeWidth: 8,
                  backgroundColor: color.withOpacity(0.1),
                  valueColor: AlwaysStoppedAnimation(color),
                  strokeCap: StrokeCap.round,
                ),
              ),
              Icon(_batteryIcon(level), color: color, size: 28),
            ],
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$level% Charged',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
                ),
                Text(
                  level > 20 ? 'Battery healthy' : 'Low battery warning',
                  style: TextStyle(fontSize: 14, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoTile(IconData icon, String label, String value) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.05),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      title: Text(
        label,
        style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
      ),
      trailing: Text(
        value,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
    );
  }

  Widget _divider() => Divider(height: 1, color: AppColors.primary.withOpacity(0.05), indent: 64);

  Color _batteryColor(int level) {
    if (level <= 20) return AppColors.error;
    if (level <= 50) return AppColors.warning;
    return AppColors.success;
  }

  IconData _batteryIcon(int level) {
    if (level <= 20) return Icons.battery_alert_rounded;
    if (level <= 50) return Icons.battery_3_bar_rounded;
    return Icons.battery_full_rounded;
  }
}
