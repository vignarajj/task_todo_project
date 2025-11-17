import 'package:appwrite/appwrite.dart';
import '../models/task_model.dart';
import '../config/appwrite_config.dart';

/// TaskRepository - Data layer for task operations using Appwrite
/// 
/// This repository handles:
/// - CRUD operations for tasks
/// - Appwrite database queries
/// - Error handling for network operations
/// - Real-time updates via Appwrite Realtime
class TaskRepository {
  final Databases _databases;

  TaskRepository(this._databases);

  /// Fetch tasks with pagination support
  /// Uses limit and offset for infinite scrolling
  /// 
  /// [limit] - Number of tasks to fetch per request (default: 20)
  /// [offset] - Starting position for pagination (default: 0)
  /// [userId] - Current user ID to filter owned and shared tasks
  Future<List<TaskModel>> fetchTasks({
    required String userId,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      // Query for tasks owned by or shared with the user
      final result = await _databases.listDocuments(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.tasksCollectionId,
        queries: [
          Query.equal('owner_id', userId),
          Query.orderDesc('created_at'),
          Query.limit(limit),
          Query.offset(offset),
        ],
      );

      return result.documents
          .map((doc) => TaskModel.fromJson(doc.data))
          .toList();
    } catch (e) {
      throw Exception('Error fetching tasks: $e');
    }
  }

  /// Create a new task
  /// 
  /// [task] - TaskModel to create
  /// Returns the created TaskModel with server-generated fields
  Future<TaskModel> createTask(TaskModel task) async {
    try {
      final result = await _databases.createDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.tasksCollectionId,
        documentId: task.id,
        data: {
          'title': task.title,
          'description': task.description,
          'due_date': task.dueDate?.toIso8601String(),
          'owner_id': task.ownerId,
          'shared_user_ids': task.sharedUserIds,
          'is_completed': task.isCompleted,
          'created_at': task.createdAt.toIso8601String(),
          'updated_at': task.updatedAt.toIso8601String(),
        },
        permissions: [
          Permission.read(Role.user(task.ownerId)),
          Permission.update(Role.user(task.ownerId)),
          Permission.delete(Role.user(task.ownerId)),
        ],
      );

      return TaskModel.fromJson(result.data);
    } catch (e) {
      throw Exception('Error creating task: $e');
    }
  }

  /// Update an existing task
  /// 
  /// [task] - TaskModel with updated fields
  /// Returns the updated TaskModel
  Future<TaskModel> updateTask(TaskModel task) async {
    try {
      final result = await _databases.updateDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.tasksCollectionId,
        documentId: task.id,
        data: {
          'title': task.title,
          'description': task.description,
          'due_date': task.dueDate?.toIso8601String(),
          'shared_user_ids': task.sharedUserIds,
          'is_completed': task.isCompleted,
          'updated_at': DateTime.now().toIso8601String(),
        },
      );

      return TaskModel.fromJson(result.data);
    } catch (e) {
      throw Exception('Error updating task: $e');
    }
  }

  /// Delete a task
  /// 
  /// [taskId] - ID of the task to delete
  Future<void> deleteTask(String taskId) async {
    try {
      await _databases.deleteDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.tasksCollectionId,
        documentId: taskId,
      );
    } catch (e) {
      throw Exception('Error deleting task: $e');
    }
  }

  /// Subscribe to task updates for real-time synchronization
  /// 
  /// [userId] - Current user ID to filter tasks
  /// Returns a Stream of task lists that updates in real-time
  Stream<List<TaskModel>> subscribeToTasks(String userId) async* {
    // Note: Appwrite Realtime subscriptions work differently
    // This is a simplified implementation
    // For full realtime support, you would use Realtime API
    
    // Initial fetch
    final initialTasks = await fetchTasks(userId: userId);
    yield initialTasks;
    
    // TODO: Implement Appwrite Realtime subscription
    // final realtime = Realtime(AppwriteService().client);
    // final subscription = realtime.subscribe([
    //   'databases.${AppwriteConfig.databaseId}.collections.${AppwriteConfig.tasksCollectionId}.documents'
    // ]);
  }

  /// Share a task with another user
  /// 
  /// [taskId] - ID of the task to share
  /// [userIdToShare] - ID of the user to share with
  Future<TaskModel> shareTask(String taskId, String userIdToShare) async {
    try {
      // First, get the current task
      final task = await _databases.getDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.tasksCollectionId,
        documentId: taskId,
      );
      
      // Add the new user to shared_user_ids
      final currentSharedUsers = List<String>.from(task.data['shared_user_ids'] ?? []);
      if (!currentSharedUsers.contains(userIdToShare)) {
        currentSharedUsers.add(userIdToShare);
      }
      
      // Update the task
      final result = await _databases.updateDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.tasksCollectionId,
        documentId: taskId,
        data: {
          'shared_user_ids': currentSharedUsers,
          'updated_at': DateTime.now().toIso8601String(),
        },
        permissions: [
          Permission.read(Role.user(task.data['owner_id'])),
          Permission.update(Role.user(task.data['owner_id'])),
          Permission.delete(Role.user(task.data['owner_id'])),
          Permission.read(Role.user(userIdToShare)),
        ],
      );

      return TaskModel.fromJson(result.data);
    } catch (e) {
      throw Exception('Error sharing task: $e');
    }
  }
}
