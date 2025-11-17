import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task_model.dart';

/// TaskItemWidget - Reusable widget for displaying a single task item
/// 
/// Features:
/// - Checkbox for completion status
/// - Task title and description
/// - Due date display
/// - Swipe-to-delete functionality
/// - Animations for interactions
class TaskItemWidget extends StatefulWidget {
  final TaskModel task;
  final VoidCallback? onTap;
  final VoidCallback? onToggleComplete;
  final VoidCallback? onDelete;

  const TaskItemWidget({
    super.key,
    required this.task,
    this.onTap,
    this.onToggleComplete,
    this.onDelete,
  });

  @override
  State<TaskItemWidget> createState() => _TaskItemWidgetState();
}

class _TaskItemWidgetState extends State<TaskItemWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    // Initialize animation controller for scale effect
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Use MediaQuery for responsive sizing
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Dismissible(
        key: ValueKey(widget.task.id),
        direction: DismissDirection.endToStart,
        background: _buildDismissBackground(context),
        confirmDismiss: (_) async {
          // Trigger delete callback and prevent automatic dismiss
          widget.onDelete?.call();
          return false; // We handle deletion in ViewModel
        },
        child: Card(
          margin: EdgeInsets.symmetric(
            horizontal: isTablet ? 16 : 8,
            vertical: 4,
          ),
          elevation: 2,
          child: InkWell(
            onTap: () {
              _animationController.forward().then((_) {
                _animationController.reverse();
              });
              widget.onTap?.call();
            },
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: EdgeInsets.all(isTablet ? 16 : 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Checkbox for completion status
                  _buildCheckbox(),
                  const SizedBox(width: 12),
                  
                  // Task content
                  Expanded(
                    child: _buildTaskContent(context),
                  ),
                  
                  // Shared indicator
                  if (widget.task.sharedUserIds.isNotEmpty)
                    _buildSharedIndicator(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Build checkbox for task completion
  Widget _buildCheckbox() {
    return Transform.scale(
      scale: 1.2,
      child: Checkbox(
        value: widget.task.isCompleted,
        onChanged: (_) => widget.onToggleComplete?.call(),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }

  /// Build task content (title, description, due date)
  Widget _buildTaskContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Task title
        Text(
          widget.task.title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                decoration: widget.task.isCompleted
                    ? TextDecoration.lineThrough
                    : null,
                color: widget.task.isCompleted
                    ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)
                    : Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        
        // Task description
        if (widget.task.description.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            widget.task.description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  decoration: widget.task.isCompleted
                      ? TextDecoration.lineThrough
                      : null,
                ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
        
        // Due date
        if (widget.task.dueDate != null) ...[
          const SizedBox(height: 8),
          _buildDueDateChip(context),
        ],
      ],
    );
  }

  /// Build due date chip with color coding
  Widget _buildDueDateChip(BuildContext context) {
    final dueDate = widget.task.dueDate!;
    final now = DateTime.now();
    final isOverdue = dueDate.isBefore(now) && !widget.task.isCompleted;
    final isDueSoon = dueDate.difference(now).inDays <= 1 && !widget.task.isCompleted;

    // Use theme colors instead of hardcoded colors
    Color chipColor = Theme.of(context).colorScheme.onSurface;
    double opacity = isOverdue || isDueSoon ? 0.8 : 0.6;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: chipColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.calendar_today,
            size: 12,
            color: chipColor.withValues(alpha: opacity),
          ),
          const SizedBox(width: 4),
          Text(
            _formatDueDate(dueDate),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: chipColor.withValues(alpha: opacity),
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }

  /// Build shared indicator icon
  Widget _buildSharedIndicator(BuildContext context) {
    return Tooltip(
      message: 'Shared with ${widget.task.sharedUserIds.length} user(s)',
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.people,
              size: 16,
              color: Theme.of(context).colorScheme.secondary,
            ),
            const SizedBox(width: 4),
            Text(
              '${widget.task.sharedUserIds.length}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.secondary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build dismiss background for swipe-to-delete
  Widget _buildDismissBackground(BuildContext context) {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onSurface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        Icons.delete,
        color: Theme.of(context).colorScheme.surface,
        size: 32,
      ),
    );
  }

  /// Format due date for display
  String _formatDueDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final taskDate = DateTime(date.year, date.month, date.day);

    if (taskDate == today) {
      return 'Today';
    } else if (taskDate == tomorrow) {
      return 'Tomorrow';
    } else if (taskDate.isBefore(today)) {
      return 'Overdue';
    } else {
      return DateFormat('MMM dd, yyyy').format(date);
    }
  }
}
