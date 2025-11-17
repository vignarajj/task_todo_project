import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/task_model.dart';
import '../viewmodels/task_viewmodel.dart';
import 'task_item_widget.dart';

/// TaskListWidget - Displays a scrollable list of tasks with infinite scrolling
/// 
/// Features:
/// - ListView.builder for performance
/// - Infinite scrolling with pagination
/// - Pull-to-refresh
/// - Empty state handling
/// - Loading indicators
class TaskListWidget extends ConsumerStatefulWidget {
  final Function(TaskModel)? onTaskTap;

  const TaskListWidget({
    super.key,
    this.onTaskTap,
  });

  @override
  ConsumerState<TaskListWidget> createState() => _TaskListWidgetState();
}

class _TaskListWidgetState extends ConsumerState<TaskListWidget> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Handle scroll events for infinite scrolling
  void _onScroll() {
    if (_isBottom) {
      // Load more tasks when user reaches bottom
      ref.read(taskViewModelProvider.notifier).loadMore();
    }
  }

  /// Check if user has scrolled to the bottom
  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }

  @override
  Widget build(BuildContext context) {
    final taskState = ref.watch(taskViewModelProvider);

    // Show error message if present
    if (taskState.error != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final errorMessage = taskState.error!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Theme.of(context).colorScheme.onSurface,
            action: SnackBarAction(
              label: 'Copy',
              textColor: Theme.of(context).colorScheme.surface,
              onPressed: () {
                Clipboard.setData(ClipboardData(text: errorMessage));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Error copied to clipboard'),
                    duration: const Duration(seconds: 2),
                    backgroundColor: Theme.of(context).colorScheme.onSurface,
                  ),
                );
              },
            ),
          ),
        );
        ref.read(taskViewModelProvider.notifier).clearError();
      });
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(taskViewModelProvider.notifier).refresh();
      },
      child: taskState.tasks.isEmpty && !taskState.isLoading
          ? _buildEmptyState()
          : _buildTaskList(taskState),
    );
  }

  /// Build empty state when no tasks are available
  Widget _buildEmptyState() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.task_alt,
                    size: 80,
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No tasks yet',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap + to create your first task',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                        ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Build scrollable task list with pagination
  Widget _buildTaskList(TaskState taskState) {
    return ListView.builder(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(8),
      itemCount: taskState.tasks.length + (taskState.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        // Show loading indicator at the end if there are more tasks
        if (index >= taskState.tasks.length) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final task = taskState.tasks[index];
        
        return TaskItemWidget(
          key: ValueKey(task.id),
          task: task,
          onTap: () => widget.onTaskTap?.call(task),
          onToggleComplete: () {
            ref.read(taskViewModelProvider.notifier).toggleTaskCompletion(task.id);
          },
          onDelete: () async {
            final confirm = await _showDeleteConfirmation(context, task);
            if (confirm == true) {
              ref.read(taskViewModelProvider.notifier).deleteTask(task.id);
            }
          },
        );
      },
    );
  }

  /// Show confirmation dialog before deleting a task
  Future<bool?> _showDeleteConfirmation(BuildContext context, TaskModel task) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Task'),
        content: Text('Are you sure you want to delete "${task.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
