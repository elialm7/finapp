// lib/features/auth/presentation/providers/auth_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/models/auth_model.dart';

class AuthState {
  final String? token;
  final String? email;
  final String? baseCurrency;
  final bool isLoading;
  final String? error;

  const AuthState({
    this.token,
    this.email,
    this.baseCurrency,
    this.isLoading = false,
    this.error,
  });

  AuthState copyWith({
    String? token,
    String? email,
    String? baseCurrency,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      token: token ?? this.token,
      email: email ?? this.email,
      baseCurrency: baseCurrency ?? this.baseCurrency,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repo;

  AuthNotifier(this._repo) : super(const AuthState()) {
    _init();
  }

  Future<void> _init() async {
    final user = await _repo.tryRestoreSession();
    if (user != null) {
      state = AuthState(
        token: user.token,
        email: user.email,
        baseCurrency: user.baseCurrency,
      );
    }
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true);
    try {
      final user = await _repo.login(email, password);
      state = AuthState(token: user.token, email: user.email, baseCurrency: user.baseCurrency);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> register(String email, String password, String currency) async {
    state = state.copyWith(isLoading: true);
    try {
      final user = await _repo.register(email, password, currency);
      state = AuthState(token: user.token, email: user.email, baseCurrency: user.baseCurrency);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> logout() async {
    await _repo.logout();
    state = const AuthState();
  }
}

final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(authRepositoryProvider));
});

final currentCurrencyProvider = Provider<String>((ref) {
  return ref.watch(authStateProvider).baseCurrency ?? 'PYG';
});
