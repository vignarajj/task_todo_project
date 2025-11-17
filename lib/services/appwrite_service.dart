import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import '../config/appwrite_config.dart';

/// AppwriteService - Singleton service for Appwrite client and authentication
/// 
/// This service provides:
/// - Appwrite client initialization
/// - Authentication methods (email/password, anonymous)
/// - Account management
/// - Database and storage access
class AppwriteService {
  static final AppwriteService _instance = AppwriteService._internal();
  
  factory AppwriteService() {
    return _instance;
  }
  
  AppwriteService._internal();
  
  late final Client _client;
  late final Account _account;
  late final Databases _databases;
  
  bool _initialized = false;
  
  /// Get the Appwrite client instance
  Client get client {
    if (!_initialized) {
      throw StateError('AppwriteService not initialized. Call initialize() first.');
    }
    return _client;
  }
  
  /// Get the Account service
  Account get account {
    if (!_initialized) {
      throw StateError('AppwriteService not initialized. Call initialize() first.');
    }
    return _account;
  }
  
  /// Get the Databases service
  Databases get databases {
    if (!_initialized) {
      throw StateError('AppwriteService not initialized. Call initialize() first.');
    }
    return _databases;
  }
  
  /// Initialize the Appwrite client
  /// Should be called once at app startup
  void initialize() {
    if (_initialized) return;
    
    _client = Client()
        .setEndpoint(AppwriteConfig.endpoint)
        .setProject(AppwriteConfig.projectId);
    
    _account = Account(_client);
    _databases = Databases(_client);
    
    _initialized = true;
  }
  
  /// Sign up with email and password
  /// 
  /// [email] - User email address
  /// [password] - User password
  /// [name] - Optional user name
  /// Returns the created user
  Future<models.User> signUp(String email, String password, {String? name}) async {
    try {
      return await _account.create(
        userId: ID.unique(),
        email: email,
        password: password,
        name: name,
      );
    } catch (e) {
      throw Exception('Failed to sign up: $e');
    }
  }
  
  /// Sign in with email and password
  /// 
  /// [email] - User email address
  /// [password] - User password
  /// Returns the created session
  Future<models.Session> signIn(String email, String password) async {
    try {
      return await _account.createEmailPasswordSession(
        email: email,
        password: password,
      );
    } catch (e) {
      throw Exception('Failed to sign in: $e');
    }
  }
  
  /// Sign in anonymously
  /// 
  /// Returns the created session
  Future<models.Session> signInAnonymously() async {
    try {
      return await _account.createAnonymousSession();
    } catch (e) {
      throw Exception('Failed to sign in anonymously: $e');
    }
  }
  
  /// Get the current user account
  /// 
  /// Returns null if not authenticated
  Future<models.User?> getCurrentUser() async {
    try {
      return await _account.get();
    } catch (e) {
      // User not authenticated
      return null;
    }
  }
  
  /// Sign out the current user
  Future<void> signOut() async {
    try {
      await _account.deleteSession(sessionId: 'current');
    } catch (e) {
      throw Exception('Failed to sign out: $e');
    }
  }
  
  /// Delete all sessions (sign out from all devices)
  Future<void> signOutFromAllDevices() async {
    try {
      await _account.deleteSessions();
    } catch (e) {
      throw Exception('Failed to sign out from all devices: $e');
    }
  }
  
  /// Update user name
  /// 
  /// [name] - New name
  Future<models.User> updateName(String name) async {
    try {
      return await _account.updateName(name: name);
    } catch (e) {
      throw Exception('Failed to update name: $e');
    }
  }
  
  /// Update user email
  /// 
  /// [email] - New email
  /// [password] - Current password for verification
  Future<models.User> updateEmail(String email, String password) async {
    try {
      return await _account.updateEmail(email: email, password: password);
    } catch (e) {
      throw Exception('Failed to update email: $e');
    }
  }
  
  /// Update user password
  /// 
  /// [newPassword] - New password
  /// [oldPassword] - Current password for verification
  Future<models.User> updatePassword(String newPassword, String oldPassword) async {
    try {
      return await _account.updatePassword(
        password: newPassword,
        oldPassword: oldPassword,
      );
    } catch (e) {
      throw Exception('Failed to update password: $e');
    }
  }
}
