import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../providers/app_lock_provider.dart';
import '../services/biometric_service.dart';
import '../theme/app_colors.dart';

class AppLockGate extends ConsumerStatefulWidget {
  final Widget child;

  const AppLockGate({super.key, required this.child});

  @override
  ConsumerState<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends ConsumerState<AppLockGate>
    with WidgetsBindingObserver {
  bool _isAuthenticating = false;
  bool _canAuthenticate = false;
  DateTime? _pausedAt;

  static const _gracePeriod = Duration(seconds: 60);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _init();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _init() async {
    _canAuthenticate = await BiometricService.canAuthenticate();
    if (!mounted) return;
    if (!_canAuthenticate) {
      ref.read(appLockProvider.notifier).unlock();
    } else {
      await _authenticate();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      if (!ref.read(appLockProvider)) {
        _pausedAt = DateTime.now();
      }
    } else if (state == AppLifecycleState.resumed) {
      final wasLong = _pausedAt != null &&
          DateTime.now().difference(_pausedAt!) > _gracePeriod;
      _pausedAt = null;

      final alreadyLocked = ref.read(appLockProvider);
      if (alreadyLocked || wasLong) {
        ref.read(appLockProvider.notifier).lock();
        _authenticate();
      }
    }
  }

  Future<void> _authenticate() async {
    if (!_canAuthenticate || _isAuthenticating) return;
    _isAuthenticating = true;
    final success = await BiometricService.authenticate(
      'Odemkněte aplikaci Czech BMX',
    );
    _isAuthenticating = false;
    if (success && mounted) {
      ref.read(appLockProvider.notifier).unlock();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLocked = ref.watch(appLockProvider);
    return Stack(
      children: [
        widget.child,
        if (isLocked) _AppLockScreen(onUnlock: _authenticate),
      ],
    );
  }
}

class _AppLockScreen extends StatelessWidget {
  final VoidCallback onUnlock;

  const _AppLockScreen({required this.onUnlock});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF0D0F1A),
      child: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_rounded,
                  size: 40,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                'Czech BMX',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Odemkněte aplikaci',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.55),
                ),
              ),
              const SizedBox(height: 48),
              FilledButton.icon(
                onPressed: onUnlock,
                icon: const Icon(Icons.fingerprint, size: 22),
                label: const Text('Biometrika'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: const Size(220, 50),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 36,
                    vertical: 14,
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: onUnlock,
                icon: const Icon(Icons.pin_outlined, size: 20),
                label: const Text('Zadat PIN / heslo'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.25)),
                  minimumSize: const Size(220, 50),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 36,
                    vertical: 14,
                  ),
                  textStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
