import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/task_model.dart';
import '../repositories/task_repository.dart';
import '../providers/providers.dart';
import 'auth_viewmodel.dart';

/// TaskState - Represents the state of task operations
class TaskState {
  final List<TaskModel> tasks;
  final bool isLoading;
  final String? error;
  final bool hasMore;
  final int currentPage;

  const TaskState({
    this.tasks = const [],
    this.isLoading = false,
    this.error,
    this.hasMore = true,
    this.currentPage = 0,
  });

  TaskState copyWith({
    List<TaskModel>? tasks,
    bool? isLoading,
    String? error,
    bool? hasMore,
    int? currentPage,
  }) {
    return TaskState(
      tasks: tasks ?? this.tasks,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
    );
  }
}

/// TaskViewModel - Manages task state and business logic
/// 
/// Handles:
/// - CRUD operations for tasks
/// - Pagination for infinite scrolling
/// - Real-time updates via subscriptions
/// - Error handling
class TaskViewModel extends StateNotifier<TaskState> {
  final TaskRepository _repository;
  final String _userId;
  final int _pageSize = 20;
  
  TaskViewModel(this._repository, this._userId) : super(const TaskState()) {
    _initialize();
  }

  /// Initialize the view model and load initial tasks
  void _initialize() {
    loadTasks();
    _subscribeToTasks();
  }

  /// Load tasks with pagination
  /// Used for initial load and infinite scrolling
  Future<void> loadTasks({bool refresh = false}) async {
    // Prevent multiple simultaneous loads
    if (state.isLoading) return;
    
    // Reset state if refreshing
    if (refresh) {
      state = const TaskState(isLoading: true);
    } else {
      state = state.copyWith(isLoading: true, error: null);
    }

    try {
      final offset = refresh ? 0 : state.currentPage * _pageSize;
      
      final newTasks = await _repository.fetchTasks(
        userId: _userId,
        limit: _pageSize,
        offset: offset,
      );

      // Combine with existing tasks or replace if refreshing
      final List<TaskModel> updatedTasks = refresh 
          ? newTasks 
          : [...state.tasks, ...newTasks];

      // Check if there are more tasks to load
      final hasMore = newTasks.length == _pageSize;

      state = TaskState(
        tasks: updatedTasks,
        isLoading: false,
        hasMore: hasMore,
        currentPage: refresh ? 1 : state.currentPage + 1,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Load more tasks for infinite scrolling
  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoading) return;
    await loadTasks();
  }

  /// Subscribe to real-time task updates
  /// Updates state when tasks change on the server
  void _subscribeToTasks() {
    _repository.subscribeToTasks(_userId).listen(
      (tasks) {
        // Update state with real-time data while preserving pagination
        state = state.copyWith(
          tasks: tasks,
          error: null,
        );
      },
      onError: (error) {
        state = state.copyWith(
          error: 'Real-time update error: $error',
        );
      },
    );
  }

  /// Create a new task
  /// 
  /// [title] - Task title
  /// [description] - Task description
  /// [dueDate] - Optional due date
  Future<void> createTask({
    required String title,
    required String description,
    DateTime? dueDate,
  }) async {
    try {
      final task = TaskModel(
        id: const Uuid().v4(),
        title: title,
        description: description,
        dueDate: dueDate,
        ownerId: _userId,
        sharedUserIds: [],
        isCompleted: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _repository.createTask(task);
      
      // Task will be updated via subscription
      // Optionally, you can add optimistic update here
    } catch (e) {
      state = state.copyWith(error: 'Failed to create task: $e');
    }
  }

  /// Update an existing task
  /// 
  /// [task] - TaskModel with updated fields
  Future<void> updateTask(TaskModel task) async {
    try {
      final updatedTask = task.copyWith(
        updatedAt: DateTime.now(),
      );
      
      await _repository.updateTask(updatedTask);
      
      // Task will be updated via subscription
    } catch (e) {
      state = state.copyWith(error: 'Failed to update task: $e');
    }
  }

  /// Toggle task completion status
  /// 
  /// [taskId] - ID of the task to toggle
  Future<void> toggleTaskCompletion(String taskId) async {
    try {
      final task = state.tasks.firstWhere((t) => t.id == taskId);
      final updatedTask = task.copyWith(
        isCompleted: !task.isCompleted,
        updatedAt: DateTime.now(),
      );
      
      await _repository.updateTask(updatedTask);
    } catch (e) {
      state = state.copyWith(error: 'Failed to toggle task: $e');
    }
  }

  /// Delete a task
  /// 
  /// [taskId] - ID of the task to delete
  Future<void> deleteTask(String taskId) async {
    try {
      await _repository.deleteTask(taskId);
      
      // Remove from state immediately for better UX
      state = state.copyWith(
        tasks: state.tasks.where((t) => t.id != taskId).toList(),
      );
    } catch (e) {
      state = state.copyWith(error: 'Failed to delete task: $e');
    }
  }

  /// Share a task with another user
  /// 
  /// [taskId] - ID of the task to share
  /// [userIdToShare] - ID of the user to share with
  Future<void> shareTask(String taskId, String userIdToShare) async {
    try {
      await _repository.shareTask(taskId, userIdToShare);
      
      // Task will be updated via subscription
    } catch (e) {
      state = state.copyWith(error: 'Failed to share task: $e');
    }
  }

  /// Clear any error messages
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Refresh tasks - reload from beginning
  Future<void> refresh() async {
    await loadTasks(refresh: true);
  }
}

/// Task ViewModel Provider
/// Creates TaskViewModel instance with dependencies
final taskViewModelProvider = StateNotifierProvider<TaskViewModel, TaskState>((ref) {
  final repository = ref.watch(taskRepositoryProvider);
  final authState = ref.watch(authViewModelProvider);
  final user = authState.user;
  
  // Ensure user is authenticated
  if (user == null) {
    throw Exception('User must be authenticated to access tasks');
  }
  
  return TaskViewModel(repository, user.id);
});
