import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:appwrite/appwrite.dart';
import '../services/appwrite_service.dart';
import '../services/share_service.dart';
import '../services/deep_link_service.dart';
import '../repositories/task_repository.dart';
import '../models/user_model.dart';

/// Appwrite Service Provider
/// Provides singleton instance of AppwriteService
final appwriteServiceProvider = Provider<AppwriteService>((ref) {
  final service = AppwriteService();
  service.initialize();
  return service;
});

/// Databases Provider
/// Provides Appwrite Databases instance
final databasesProvider = Provider<Databases>((ref) {
  final appwriteService = ref.watch(appwriteServiceProvider);
  return appwriteService.databases;
});

/// Share Service Provider  
final shareServiceProvider = Provider<ShareService>((ref) {
  return ShareService();
});

/// Task Repository Provider
final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  final databases = ref.watch(databasesProvider);
  return TaskRepository(databases);
});

/// Current User Provider
/// Provides the currently authenticated user, null if not authenticated
/// This will be managed by AuthViewModel
final currentUserProvider = StateProvider<UserModel?>((ref) {
  return null;
});
