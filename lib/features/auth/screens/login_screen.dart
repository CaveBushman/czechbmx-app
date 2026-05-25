import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends HookConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final emailCtrl = useTextEditingController();
    final passwordCtrl = useTextEditingController();
    final obscure = useState(true);
    final isLoading = useState(false);
    final errorMsg = useState<String?>(null);

    Future<void> submit() async {
      final email = emailCtrl.text.trim();
      final password = passwordCtrl.text;
      if (email.isEmpty || password.isEmpty) {
        errorMsg.value = 'Vyplňte e-mail a heslo.';
        return;
      }
      isLoading.value = true;
      errorMsg.value = null;
      try {
        await ref.read(authProvider.notifier).login(
              email: email,
              password: password,
            );
        final authState = ref.read(authProvider).valueOrNull;
        if (authState is AuthAuthenticated && context.mounted) {
          context.go('/news');
        }
      } catch (e) {
        errorMsg.value = e.toString();
      } finally {
        isLoading.value = false;
      }
    }

    final colors = context.colors;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.4),
                        blurRadius: 24,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      'BMX',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text('Czech BMX', style: Theme.of(context).textTheme.displayMedium),
                const SizedBox(height: 6),
                Text(
                  'Přihlašte se ke svému účtu',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 40),

                // Error banner
                if (errorMsg.value != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.error.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: AppColors.error, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            errorMsg.value!,
                            style: const TextStyle(color: AppColors.error, fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Email
                _Field(
                  controller: emailCtrl,
                  label: 'E-mail',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  colors: colors,
                  onSubmitted: (_) => submit(),
                ),
                const SizedBox(height: 14),

                // Password
                TextField(
                  controller: passwordCtrl,
                  obscureText: obscure.value,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => submit(),
                  decoration: _fieldDecoration(
                    label: 'Heslo',
                    icon: Icons.lock_outline,
                    colors: colors,
                  ).copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscure.value
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: colors.textMuted,
                      ),
                      onPressed: () => obscure.value = !obscure.value,
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // Submit
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: isLoading.value ? null : submit,
                    child: isLoading.value
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Přihlásit se'),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => context.go('/news'),
                  child: Text(
                    'Pokračovat bez přihlášení',
                    style: TextStyle(color: colors.textMuted),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

InputDecoration _fieldDecoration({
  required String label,
  required IconData icon,
  required AppColorPalette colors,
}) {
  return InputDecoration(
    labelText: label,
    labelStyle: TextStyle(color: colors.textMuted),
    prefixIcon: Icon(icon, color: colors.textMuted, size: 20),
    filled: true,
    fillColor: colors.surfaceVariant,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: colors.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
    ),
  );
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final AppColorPalette colors;
  final TextInputType keyboardType;
  final ValueChanged<String>? onSubmitted;

  const _Field({
    required this.controller,
    required this.label,
    required this.icon,
    required this.colors,
    this.keyboardType = TextInputType.text,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: TextInputAction.next,
      onSubmitted: onSubmitted,
      decoration: _fieldDecoration(label: label, icon: icon, colors: colors),
    );
  }
}
