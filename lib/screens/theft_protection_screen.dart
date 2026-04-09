import 'package:flutter/material.dart';
import 'package:ocsafe_cyberguard/core/theme/app_theme.dart';
import 'package:ocsafe_cyberguard/security/theft_detection/theft_constants.dart';
import 'package:ocsafe_cyberguard/security/theft_detection/theft_state_manager.dart';
import 'dart:ui';

/// Smart Theft Shield — dedicated UI screen.
///
/// Connected to [TheftStateManager] — rebuilds automatically on state changes.
/// No business logic lives here; it purely reflects and mutates manager state.
class TheftProtectionScreen extends StatefulWidget {
  const TheftProtectionScreen({super.key});

  @override
  State<TheftProtectionScreen> createState() => _TheftProtectionScreenState();
}

class _TheftProtectionScreenState extends State<TheftProtectionScreen>
    with TickerProviderStateMixin {
  final TheftStateManager _manager = TheftStateManager.instance;

  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Refresh admin status each time screen is opened.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _manager.initialize();
      await _manager.refreshAdminStatus();
      if (mounted) setState(() {});
    });

    _manager.addListener(_onManagerChanged);
  }

  void _onManagerChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _manager.removeListener(_onManagerChanged);
    _pulseController.dispose();
    super.dispose();
  }

  // ── UI build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Background gradient matching app palette
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFFFFD1DF),
                Color(0xFFEAE2FF),
                Color(0xFFC9D8FF),
              ],
              stops: [0.0, 0.4, 1.0],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: const Text('Theft Shield'),
            backgroundColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeroCard(),
                  const SizedBox(height: 20),
                  if (!_manager.isAdminActive && _manager.isEnabled)
                    _buildPermissionBanner(),
                  if (!_manager.isAdminActive && _manager.isEnabled)
                    const SizedBox(height: 20),
                  _buildSensitivityCard(),
                  const SizedBox(height: 20),
                  _buildHowItWorksCard(),
                  const SizedBox(height: 20),
                  _buildSafetyNotesCard(),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Hero card (toggle + pulse animation) ────────────────────────────────────

  Widget _buildHeroCard() {
    final isOn = _manager.isEnabled;
    final isReady = isOn && _manager.isAdminActive;

    return _GlassCard(
      child: Column(
        children: [
          const SizedBox(height: 8),
          // Animated shield icon
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (_, child) {
              return Transform.scale(
                scale: isReady ? _pulseAnimation.value : 1.0,
                child: child,
              );
            },
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: isOn
                    ? AppColors.primaryGradient
                    : const LinearGradient(
                        colors: [Color(0xFFCBD5E1), Color(0xFF94A3B8)],
                      ),
                boxShadow: isOn
                    ? [
                        BoxShadow(
                          color: AppColors.accentGlow,
                          blurRadius: 24,
                          spreadRadius: 4,
                        )
                      ]
                    : [],
              ),
              child: Icon(
                isOn ? Icons.shield_rounded : Icons.shield_outlined,
                size: 50,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isOn
                ? (isReady ? 'Active & Protecting' : 'Enabled — Action Needed')
                : 'Smart Theft Shield',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isOn
                ? (isReady
                    ? 'Monitoring motion — your device is guarded'
                    : 'Grant Device Admin permission below to activate')
                : 'Detects snatching & locks your device instantly',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          // Status badge
          _StatusBadge(isOn: isOn, isReady: isReady),
          const SizedBox(height: 24),
          // Toggle row
          _GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                Icon(
                  Icons.sensors_rounded,
                  color: isOn ? AppColors.primary : AppColors.textSecondary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Theft Protection',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        isOn ? 'Tap to disable' : 'Tap to enable',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: isOn,
                  onChanged: (v) => _manager.setEnabled(v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ── Permission banner ──────────────────────────────────────────────────────

  Widget _buildPermissionBanner() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.error.withValues(alpha: 0.35),
          width: 1.5,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Device Admin Required',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.error,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Without this, the screen lock will not work.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => _manager.requestAdminPermission(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Grant',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  // ── Sensitivity card ───────────────────────────────────────────────────────

  Widget _buildSensitivityCard() {
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.tune_rounded, color: AppColors.primary, size: 22),
              SizedBox(width: 8),
              Text(
                'Detection Sensitivity',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Higher sensitivity triggers faster but may have more false alarms.',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          ...TheftSensitivity.values.map((s) => _SensitivityTile(
                sensitivity: s,
                isSelected: _manager.sensitivity == s,
                onTap: () => _manager.setSensitivity(s),
              )),
        ],
      ),
    );
  }

  // ── How it works card ──────────────────────────────────────────────────────

  Widget _buildHowItWorksCard() {
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 22),
              SizedBox(width: 8),
              Text(
                'How Detection Works',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _Step(number: '1', icon: Icons.bolt_rounded, color: AppColors.warning,
              label: 'Jerk Detected', desc: 'Sudden acceleration spike is registered'),
          _Step(number: '2', icon: Icons.timeline_rounded, color: AppColors.primary,
              label: 'Motion Window Opens', desc: '5-second window tracks continuous movement'),
          _Step(number: '3', icon: Icons.lock_rounded, color: AppColors.error,
              label: 'Device Locks', desc: 'Screen locks after 1.5 s confirmation delay'),
        ],
      ),
    );
  }

  // ── Safety notes card ──────────────────────────────────────────────────────

  Widget _buildSafetyNotesCard() {
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.checklist_rounded, color: AppColors.success, size: 22),
              SizedBox(width: 8),
              Text(
                'Safety Notes',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _Note(
            icon: Icons.do_not_touch_outlined,
            text: 'Single drops or bumps will NOT trigger a lock',
          ),
          _Note(
            icon: Icons.screen_lock_portrait_outlined,
            text: 'Detection pauses when screen is off (no pocket-locks)',
          ),
          _Note(
            icon: Icons.timer_outlined,
            text: '5-second cooldown after each lock event',
          ),
          _Note(
            icon: Icons.battery_saver_outlined,
            text: 'Low battery impact — normal sampling rate used',
          ),
        ],
      ),
    );
  }
}

// ── Reusable widgets ─────────────────────────────────────────────────────────

class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: double.infinity,
          padding: padding ?? const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.45),
              width: 1.5,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.isOn, required this.isReady});

  final bool isOn;
  final bool isReady;

  @override
  Widget build(BuildContext context) {
    final Color color = isReady
        ? AppColors.success
        : (isOn ? AppColors.warning : AppColors.textSecondary);
    final String label = isReady
        ? '✓  ACTIVE & PROTECTED'
        : (isOn ? '⚠  PERMISSION NEEDED' : '○  INACTIVE');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 13,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _SensitivityTile extends StatelessWidget {
  const _SensitivityTile({
    required this.sensitivity,
    required this.isSelected,
    required this.onTap,
  });

  final TheftSensitivity sensitivity;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.1)
              : Colors.white.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.4),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sensitivity.label,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    sensitivity.description,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
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
}

class _Step extends StatelessWidget {
  const _Step({
    required this.number,
    required this.icon,
    required this.color,
    required this.label,
    required this.desc,
  });

  final String number;
  final IconData icon;
  final Color color;
  final String label;
  final String desc;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  desc,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.success, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textPrimary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
