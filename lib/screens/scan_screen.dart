import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ocsafe_cyberguard/core/theme/app_theme.dart';
import 'package:ocsafe_cyberguard/providers/security_provider.dart';
import 'package:ocsafe_cyberguard/screens/report_detail_screen.dart';
import 'package:ocsafe_cyberguard/widgets/glass_container.dart';

/// Dedicated scan page — starts the scan on mount and auto-transitions to the
/// detailed report when scanning completes. Incorporates premium glassmorphism
/// and deep gradient layouts mimicking high-end UI concepts.
class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> with SingleTickerProviderStateMixin {
  // Guard so we navigate exactly once.
  bool _navigated = false;
  late AnimationController _pulseController;
  
  // Local list to store live scan events
  final List<String> _scanLogs = [];
  String _lastStage = "";
  
  // Guard so we do not instantly auto-navigate to report on fresh launch
  bool _scanSessionActive = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    
    // Kick off the scan *after* the first frame so Provider is ready.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<SecurityProvider>();
      if (!provider.isScanning) {
        provider.runScan();
      }
      if (mounted) {
        setState(() {
          _scanSessionActive = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }
  
  void _updateLogs(String newStage) {
    if (newStage != _lastStage && newStage.isNotEmpty) {
      _lastStage = newStage;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _scanLogs.insert(0, newStage);
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFFFFD1DF), // Soft pink (top left)
            Color(0xFFEAE2FF), // Soft purple (center)
            Color(0xFFC9D8FF), // Soft light blue (bottom right)
          ],
          stops: [0.0, 0.4, 1.0],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent, // Let gradient show through
        appBar: AppBar(
          title: const Text('Smart Scan', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Consumer<SecurityProvider>(
          builder: (context, provider, _) {
            // Track logs locally for the UI timeline
            _updateLogs(provider.scanStage);

            // ── Auto-navigate to report once scan finishes ──
            if (_scanSessionActive && !provider.isScanning && provider.lastScanResult != null && !_navigated) {
              _navigated = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ReportDetailScreen(result: provider.lastScanResult!),
                    ),
                  );
                }
              });
            }

            // Brief "complete" state shown while navigation callback fires.
            if (_scanSessionActive && !provider.isScanning && provider.lastScanResult != null) {
              return _buildCompleteState(provider);
            }

            // ── Scanning in-progress UI ──
            return ListView(
              padding: const EdgeInsets.only(bottom: 40),
              children: [
                const SizedBox(height: 16),
                
                // Hero Glass Box
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: GlassContainer(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        _buildScanModeBadge(provider),
                        const SizedBox(height: 32),
                        
                        // Dual-ring radar animation with pulsing center icon
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 160,
                              height: 160,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    AppColors.primary.withValues(alpha: 0.25)),
                                strokeCap: StrokeCap.round,
                              ),
                            ),
                            SizedBox(
                              width: 110,
                              height: 110,
                              child: CircularProgressIndicator(
                                strokeWidth: 4,
                                backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                                strokeCap: StrokeCap.round,
                              ),
                            ),
                            ScaleTransition(
                              scale: Tween<double>(begin: 0.85, end: 1.15).animate(CurvedAnimation(
                                parent: _pulseController,
                                curve: Curves.easeInOut,
                              )),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.radar_rounded, size: 40, color: AppColors.primary),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        
                        // Main stage title
                        Text(
                          provider.scanStage.isNotEmpty ? provider.scanStage : 'Initializing...',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Keep app open',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                        
                        // Vibrant gradient "Risk Score" bar inspired by the screenshot
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Risk Score',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              height: 48,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF6344FF), // Deep purple
                                    Color(0xFFFF2E93), // Hot pink
                                  ],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                              ),
                              alignment: Alignment.centerLeft,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    provider.scanStage.isNotEmpty ? 'Analyzing...' : 'Safe',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Container(
                                    width: 2,
                                    height: 20,
                                    color: Colors.white.withValues(alpha: 0.5),
                                  )
                                ],
                              ),
                            ),
                          ],
                        ),
                        
                        // Deep Black Accent Box representing 'Vulnerability' card in screenshot
                        Container(
                          margin: const EdgeInsets.only(top: 24),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.black, // Stark black like the screenshot
                            borderRadius: BorderRadius.circular(24), // Heavy rounding
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Vulnerability Scan',
                                    style: TextStyle(
                                      color: Colors.white60,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Status: In Progress',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFDDF6), // Soft pink badge background
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  provider.isFullScan ? 'Deep' : 'Quick',
                                  style: const TextStyle(
                                    color: Color(0xFFFF33DD), // Vibrant pink text
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12,
                                  ),
                                ),
                              )
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Top level section details mirroring 'Services' from requested design
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'Modules',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Horizontally scrollable target pills
                SizedBox(
                  height: 44,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: [
                      _buildModulePill('Apps', Icons.grid_view_rounded, true),
                      _buildModulePill('Files', Icons.folder_rounded, null),
                      _buildModulePill('Network', Icons.wifi_rounded, null),
                      _buildModulePill('Privacy', Icons.shield_rounded, null),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Event timeline mimicking 'Events' logs from requested design
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'Scan Timeline',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                ..._scanLogs.asMap().entries.map((entry) {
                  return _buildLogCard(entry.value, entry.key == 0);
                }),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildScanModeBadge(SecurityProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: provider.isFullScan
            ? AppColors.primary.withValues(alpha: 0.12)
            : AppColors.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: provider.isFullScan ? AppColors.primary : AppColors.warning,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            provider.isFullScan ? Icons.security_rounded : Icons.info_outline_rounded,
            size: 14,
            color: provider.isFullScan ? AppColors.primary : AppColors.warning,
          ),
          const SizedBox(width: 6),
          Text(
            provider.isFullScan ? 'Full Scan Mode' : 'Limited Scan',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: provider.isFullScan ? AppColors.primary : AppColors.warning,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModulePill(String title, IconData icon, bool? isActive) {
    final bool active = isActive == true;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: active ? const Color(0xFFE5EDFF) : Colors.white.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(24),
        border: active ? null : Border.all(color: Colors.white70, width: 1),
        boxShadow: active
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ]
            : [],
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: active ? AppColors.primary : AppColors.textSecondary),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: active ? AppColors.textPrimary : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogCard(String text, bool isRecent) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      margin: const EdgeInsets.only(bottom: 12, left: 24, right: 24),
      child: GlassContainer(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isRecent ? AppColors.primary.withValues(alpha: 0.15) : AppColors.surface,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isRecent ? Icons.sync_rounded : Icons.check_circle_rounded,
                color: isRecent ? AppColors.primary : AppColors.success,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    text,
                    style: TextStyle(
                      fontWeight: isRecent ? FontWeight.w700 : FontWeight.w500,
                      color: isRecent ? AppColors.textPrimary : AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isRecent ? 'Analyzing...' : 'Clear',
                    style: TextStyle(
                      fontSize: 12,
                      color: isRecent ? AppColors.primary : AppColors.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompleteState(SecurityProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.verified_rounded, color: AppColors.success, size: 64),
          ),
          const SizedBox(height: 24),
          const Text(
            'Scan Complete!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${provider.lastScanResult!.threatCount} threat(s) found',
            style: TextStyle(
              fontSize: 16,
              color: provider.lastScanResult!.threatCount > 0
                  ? AppColors.error
                  : AppColors.success,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Opening report…',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
