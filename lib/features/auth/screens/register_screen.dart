import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/auth_provider.dart';

class RegisterScreen extends HookConsumerWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final emailCtrl = useTextEditingController();
    final firstNameCtrl = useTextEditingController();
    final lastNameCtrl = useTextEditingController();
    final passwordCtrl = useTextEditingController();
    final isLoading = useState(false);
    final errorMsg = useState<String?>(null);
    final success = useState(false);
    final obscure = useState(true);

    Future<void> submit() async {
      final email = emailCtrl.text.trim();
      final firstName = firstNameCtrl.text.trim();
      final lastName = lastNameCtrl.text.trim();
      final password = passwordCtrl.text;

      if (email.isEmpty || firstName.isEmpty || lastName.isEmpty || password.isEmpty) {
        errorMsg.value = context.l10n.fillAllFields;
        return;
      }
      if (password.length < 8) {
        errorMsg.value = context.l10n.passwordTooShort;
        return;
      }

      isLoading.value = true;
      errorMsg.value = null;
      try {
        await ref.read(authProvider.notifier).register(
              email: email,
              firstName: firstName,
              lastName: lastName,
              password: password,
            );
        success.value = true;
      } catch (e) {
        errorMsg.value = e.toString();
      } finally {
        isLoading.value = false;
      }
    }

    if (success.value) {
      return Scaffold(
        appBar: AppBar(title: Text(context.l10n.registerTitle)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.mark_email_unread_outlined,
                    size: 72, color: AppColors.primary),
                const SizedBox(height: 24),
                Text(
                  context.l10n.registerSuccess,
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  context.l10n.registerSuccessDetail,
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () => context.go('/login'),
                  icon: const Icon(Icons.login),
                  label: Text(context.l10n.login),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.registerTitle)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            Text(
              context.l10n.registerPrompt,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 24),
            TextField(
              controller: firstNameCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: context.l10n.firstName,
                prefixIcon: const Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: lastNameCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: context.l10n.lastName,
                prefixIcon: const Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              decoration: InputDecoration(
                labelText: context.l10n.email,
                prefixIcon: const Icon(Icons.email_outlined),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: passwordCtrl,
              obscureText: obscure.value,
              decoration: InputDecoration(
                labelText: context.l10n.password,
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(obscure.value
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined),
                  onPressed: () => obscure.value = !obscure.value,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.passwordHint,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall!
                  .copyWith(color: context.colors.textMuted),
            ),
            if (errorMsg.value != null) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.error.withValues(alpha: 0.4)),
                ),
                child: Text(
                  errorMsg.value!,
                  style: const TextStyle(color: AppColors.error),
                ),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: isLoading.value ? null : submit,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: isLoading.value
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : Text(context.l10n.registerTitle),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => context.go('/login'),
              child: Text(context.l10n.alreadyHaveAccount),
            ),
          ],
        ),
      ),
    );
  }
}
