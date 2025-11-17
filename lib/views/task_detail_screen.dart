import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/task_model.dart';
import '../viewmodels/task_viewmodel.dart';
import '../providers/providers.dart';
import '../widgets/input_field_widget.dart';

/// TaskDetailScreen - Screen for viewing and editing task details
/// 
/// Features:
/// - View task details
/// - Edit task inline
/// - Share task with others
/// - Mark as complete/incomplete
/// - Delete task
/// - Real-time updates
class TaskDetailScreen extends ConsumerStatefulWidget {
  final TaskModel task;

  const TaskDetailScreen({
    super.key,
    required this.task,
  });

  @override
  ConsumerState<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends ConsumerState<TaskDetailScreen>
    with SingleTickerProviderStateMixin {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late bool _isCompleted;
  late DateTime? _dueDate;
  
  bool _isEditing = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    // Initialize controllers with task data
    _titleController = TextEditingController(text: widget.task.title);
    _descriptionController = TextEditingController(text: widget.task.description);
    _isCompleted = widget.task.isCompleted;
    _dueDate = widget.task.dueDate;

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Use LayoutBuilder for responsive design
    return LayoutBuilder(
      builder: (context, constraints) {
        final isTablet = constraints.maxWidth > 600;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Task Details'),
            elevation: 0,
            actions: [
              if (!_isEditing)
                IconButton(
                  icon: const Icon(Icons.edit),
                  tooltip: 'Edit',
                  onPressed: () {
                    setState(() {
                      _isEditing = true;
                    });
                  },
                ),
              if (!_isEditing)
                IconButton(
                  icon: const Icon(Icons.share),
                  tooltip: 'Share',
                  onPressed: _shareTask,
                ),
              if (_isEditing)
                IconButton(
                  icon: const Icon(Icons.check),
                  tooltip: 'Save',
                  onPressed: _saveTask,
                ),
              if (_isEditing)
                IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: 'Cancel',
                  onPressed: _cancelEditing,
                ),
            ],
          ),
          body: FadeTransition(
            opacity: _fadeAnimation,
            child: SingleChildScrollView(
              padding: EdgeInsets.all(isTablet ? 24 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Title
                  _isEditing
                      ? InputFieldWidget(
                          label: 'Title',
                          controller: _titleController,
                          icon: Icons.title,
                        )
                      : _buildReadOnlyField(
                          context,
                          'Title',
                          _titleController.text,
                          Icons.title,
                        ),

                  const SizedBox(height: 16),

                  // Description
                  _isEditing
                      ? InputFieldWidget(
                          label: 'Description',
                          controller: _descriptionController,
                          icon: Icons.description,
                          maxLines: 5,
                        )
                      : _buildReadOnlyField(
                          context,
                          'Description',
                          _descriptionController.text.isEmpty
                              ? 'No description'
                              : _descriptionController.text,
                          Icons.description,
                        ),

                  const SizedBox(height: 16),

                  // Due date
                  _buildDueDateSection(context, isTablet),

                  const SizedBox(height: 16),

                  // Completion status
                  _buildCompletionToggle(context),

                  const SizedBox(height: 16),

                  // Sharing information
                  if (widget.task.sharedUserIds.isNotEmpty)
                    _buildSharingInfo(context),

                  const SizedBox(height: 32),

                  // Delete button
                  if (!_isEditing) _buildDeleteButton(context, isTablet),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Build read-only field display
  Widget _buildReadOnlyField(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(icon, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    value,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build due date section
  Widget _buildDueDateSection(BuildContext context, bool isTablet) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isTablet ? 24 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Due Date',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: _isEditing ? _pickDueDate : null,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _isEditing
                    ? Theme.of(context).colorScheme.surface
                    : Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
                border: _isEditing
                    ? Border.all(
                        color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
                      )
                    : null,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _dueDate != null
                          ? DateFormat('MMM dd, yyyy').format(_dueDate!)
                          : 'No due date',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                  if (_isEditing && _dueDate != null)
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () {
                        setState(() {
                          _dueDate = null;
                        });
                      },
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build completion toggle
  Widget _buildCompletionToggle(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              _isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Mark as Complete',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
            Switch(
              value: _isCompleted,
              onChanged: (value) {
                setState(() {
                  _isCompleted = value;
                });
                if (!_isEditing) {
                  _toggleCompletion();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Build sharing information
  Widget _buildSharingInfo(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.people,
              color: Theme.of(context).colorScheme.secondary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Shared with ${widget.task.sharedUserIds.length} user(s)',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.secondary,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build delete button
  Widget _buildDeleteButton(BuildContext context, bool isTablet) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isTablet ? 24 : 16),
      child: OutlinedButton.icon(
        onPressed: _deleteTask,
        icon: const Icon(Icons.delete),
        label: const Text('Delete Task'),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  /// Pick due date
  Future<void> _pickDueDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        _dueDate = picked;
      });
    }
  }

  /// Save task changes
  Future<void> _saveTask() async {
    if (_titleController.text.trim().isEmpty) {
      final errorMessage = 'Title cannot be empty';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Theme.of(context).colorScheme.onSurface,
          action: SnackBarAction(
            label: 'Copy',
            textColor: Theme.of(context).colorScheme.surface,
            onPressed: () {
              Clipboard.setData(ClipboardData(text: errorMessage));
            },
          ),
        ),
      );
      return;
    }

    try {
      final updatedTask = widget.task.copyWith(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        dueDate: _dueDate,
        isCompleted: _isCompleted,
      );

      await ref.read(taskViewModelProvider.notifier).updateTask(updatedTask);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Task updated successfully!'),
            backgroundColor: Theme.of(context).colorScheme.onSurface,
          ),
        );

        setState(() {
          _isEditing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        final errorMessage = 'Failed to update task: $e';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Theme.of(context).colorScheme.onSurface,
            action: SnackBarAction(
              label: 'Copy',
              textColor: Theme.of(context).colorScheme.surface,
              onPressed: () {
                Clipboard.setData(ClipboardData(text: errorMessage));
              },
            ),
          ),
        );
      }
    }
  }

  /// Cancel editing
  void _cancelEditing() {
    setState(() {
      _titleController.text = widget.task.title;
      _descriptionController.text = widget.task.description;
      _isCompleted = widget.task.isCompleted;
      _dueDate = widget.task.dueDate;
      _isEditing = false;
    });
  }

  /// Toggle task completion
  Future<void> _toggleCompletion() async {
    await ref.read(taskViewModelProvider.notifier).toggleTaskCompletion(widget.task.id);
  }

  /// Share task
  Future<void> _shareTask() async {
    final shareService = ref.read(shareServiceProvider);
    
    try {
      await shareService.shareTask(
        taskId: widget.task.id,
        taskTitle: widget.task.title,
      );
    } catch (e) {
      if (mounted) {
        final errorMessage = 'Failed to share task: $e';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Theme.of(context).colorScheme.onSurface,
            action: SnackBarAction(
              label: 'Copy',
              textColor: Theme.of(context).colorScheme.surface,
              onPressed: () {
                Clipboard.setData(ClipboardData(text: errorMessage));
              },
            ),
          ),
        );
      }
    }
  }

  /// Delete task
  Future<void> _deleteTask() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Task'),
        content: const Text('Are you sure you want to delete this task?'),
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

    if (confirm == true) {
      await ref.read(taskViewModelProvider.notifier).deleteTask(widget.task.id);
      
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }
}
