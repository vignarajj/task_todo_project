import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:appwrite/models.dart' as models;
import '../models/user_model.dart';
import '../services/appwrite_service.dart';
import '../providers/providers.dart';

/// AuthState - Represents authentication state
class AuthState {
  final UserModel? user;
  final bool isLoading;
  final String? error;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.error,
  });

  AuthState copyWith({
    UserModel? user,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  bool get isAuthenticated => user != null;
}

/// AuthViewModel - Manages authentication state and operations
/// 
/// Handles:
/// - Email + Password authentication (Sign up & Sign in)
/// - Anonymous authentication
/// - Sign out
/// - User session management
class AuthViewModel extends StateNotifier<AuthState> {
  final AppwriteService _appwriteService;
  
  AuthViewModel(this._appwriteService) : super(const AuthState()) {
    _checkAuthStatus();
  }
  
  /// Check current authentication status on initialization
  Future<void> _checkAuthStatus() async {
    state = state.copyWith(isLoading: true);
    try {
      final appwriteUser = await _appwriteService.getCurrentUser();
      if (appwriteUser != null) {
        final user = _convertToUserModel(appwriteUser);
        state = AuthState(user: user);
      } else {
        state = const AuthState();
      }
    } catch (e) {
      state = const AuthState();
    }
  }
  
  /// Convert Appwrite User to UserModel
  UserModel _convertToUserModel(models.User appwriteUser) {
    return UserModel(
      id: appwriteUser.$id,
      email: appwriteUser.email,
      displayName: appwriteUser.name,
      createdAt: DateTime.parse(appwriteUser.$createdAt),
    );
  }

  /// Sign up with email and password
  /// 
  /// [email] - Email address
  /// [password] - Password
  /// [name] - Optional display name
  Future<void> signUp(String email, String password, {String? name}) async {
    if (email.isEmpty || !_isValidEmail(email)) {
      state = state.copyWith(error: 'Please enter a valid email address');
      return;
    }

    if (password.isEmpty || password.length < 8) {
      state = state.copyWith(error: 'Password must be at least 8 characters');
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      await _appwriteService.signUp(email, password, name: name);
      await _appwriteService.signIn(email, password);
      
      final appwriteUser = await _appwriteService.getCurrentUser();
      if (appwriteUser != null) {
        final user = _convertToUserModel(appwriteUser);
        state = AuthState(user: user);
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to sign up: ${e.toString()}',
      );
    }
  }
  
  /// Sign in with email and password
  /// 
  /// [email] - Email address
  /// [password] - Password
  Future<void> signIn(String email, String password) async {
    if (email.isEmpty || !_isValidEmail(email)) {
      state = state.copyWith(error: 'Please enter a valid email address');
      return;
    }

    if (password.isEmpty) {
      state = state.copyWith(error: 'Please enter your password');
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      await _appwriteService.signIn(email, password);
      final appwriteUser = await _appwriteService.getCurrentUser();
      
      if (appwriteUser != null) {
        final user = _convertToUserModel(appwriteUser);
        state = AuthState(user: user);
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to sign in: ${e.toString()}',
      );
    }
  }

  /// Sign in anonymously
  Future<void> signInAnonymously() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _appwriteService.signInAnonymously();
      final appwriteUser = await _appwriteService.getCurrentUser();
      
      if (appwriteUser != null) {
        final user = _convertToUserModel(appwriteUser);
        state = AuthState(user: user);
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to sign in anonymously: ${e.toString()}',
      );
    }
  }

  /// Sign out current user
  Future<void> signOut() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _appwriteService.signOut();
      state = const AuthState();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to sign out: ${e.toString()}',
      );
    }
  }

  /// Clear error message
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Validate email format
  bool _isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }
}

/// Auth ViewModel Provider
final authViewModelProvider = StateNotifierProvider<AuthViewModel, AuthState>((ref) {
  final appwriteService = ref.watch(appwriteServiceProvider);
  return AuthViewModel(appwriteService);
});
