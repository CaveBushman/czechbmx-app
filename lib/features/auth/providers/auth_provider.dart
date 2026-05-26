import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../core/services/biometric_service.dart';
import '../auth_repository.dart';

// Auth state: null = loading, UserModel = logged in, _LoggedOut = logged out
sealed class AuthState {
  const AuthState();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  final UserModel user;
  const AuthAuthenticated(this.user);
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

// ── Provider ──────────────────────────────────────────────────────────────────

final authProvider = AsyncNotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);

// Convenience: typed current user (null if not logged in)
final currentUserProvider = Provider<UserModel?>((ref) {
  final state = ref.watch(authProvider).valueOrNull;
  if (state is AuthAuthenticated) return state.user;
  return null;
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(currentUserProvider) != null;
});

// ── Notifier ──────────────────────────────────────────────────────────────────

class AuthNotifier extends AsyncNotifier<AuthState> {
  @override
  Future<AuthState> build() async {
    final user = await ref.read(authRepositoryProvider).restoreSession();
    return user != null ? AuthAuthenticated(user) : const AuthUnauthenticated();
  }

  Future<void> login({required String email, required String password}) async {
    state = const AsyncData(AuthLoading());
    try {
      final user = await ref
          .read(authRepositoryProvider)
          .login(email: email, password: password);
      state = AsyncData(AuthAuthenticated(user));
    } catch (e) {
      state = const AsyncData(AuthUnauthenticated());
      rethrow;
    }
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    state = const AsyncData(AuthUnauthenticated());
  }

  Future<void> register({
    required String email,
    required String firstName,
    required String lastName,
    required String password,
  }) async {
    await ref.read(authRepositoryProvider).register(
          email: email,
          firstName: firstName,
          lastName: lastName,
          password: password,
        );
  }

  /// Prompt for biometrics then restore the stored session.
  /// Returns true if authentication succeeded.
  Future<bool> loginWithBiometrics(String localizedReason) async {
    final ok = await BiometricService.authenticate(localizedReason);
    if (!ok) return false;
    state = const AsyncData(AuthLoading());
    final user = await ref.read(authRepositoryProvider).restoreSession();
    if (user != null) {
      state = AsyncData(AuthAuthenticated(user));
      return true;
    }
    state = const AsyncData(AuthUnauthenticated());
    return false;
  }

  Future<void> refreshUser() async {
    try {
      final user = await ref.read(authRepositoryProvider).fetchMe();
      state = AsyncData(AuthAuthenticated(user));
    } catch (_) {
      // Keep current state if refresh fails
    }
  }

  Future<UserModel> updatePhoto(String filePath) async {
    final user = await ref.read(authRepositoryProvider).updatePhoto(filePath);
    state = AsyncData(AuthAuthenticated(user));
    return user;
  }
}
