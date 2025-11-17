import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../viewmodels/task_viewmodel.dart';
import '../widgets/input_field_widget.dart';

/// CreateTaskScreen - Screen for creating new tasks
/// 
/// Features:
/// - Title and description input
/// - Due date picker
/// - Form validation
/// - Responsive design
/// - Loading states
class CreateTaskScreen extends ConsumerStatefulWidget {
  const CreateTaskScreen({super.key});

  @override
  ConsumerState<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends ConsumerState<CreateTaskScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  
  DateTime? _selectedDueDate;
  bool _isCreating = false;

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.9,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
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
            title: const Text('Create Task'),
            elevation: 0,
          ),
          body: ScaleTransition(
            scale: _scaleAnimation,
            child: SingleChildScrollView(
              padding: EdgeInsets.all(isTablet ? 24 : 16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Title input
                    InputFieldWidget(
                      label: 'Title',
                      hint: 'Enter task title',
                      controller: _titleController,
                      icon: Icons.title,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a title';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Description input
                    InputFieldWidget(
                      label: 'Description',
                      hint: 'Enter task description',
                      controller: _descriptionController,
                      icon: Icons.description,
                      maxLines: 5,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Due date picker
                    _buildDueDatePicker(context, isTablet),
                    
                    const SizedBox(height: 32),
                    
                    // Create button
                    _buildCreateButton(isTablet),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Build due date picker widget
  Widget _buildDueDatePicker(BuildContext context, bool isTablet) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isTablet ? 24 : 16),
      child: InkWell(
        onTap: _pickDueDate,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                Icons.calendar_today,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Due Date',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _selectedDueDate != null
                          ? DateFormat('MMM dd, yyyy').format(_selectedDueDate!)
                          : 'No due date set',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
              if (_selectedDueDate != null)
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () {
                    setState(() {
                      _selectedDueDate = null;
                    });
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build create button
  Widget _buildCreateButton(bool isTablet) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isTablet ? 24 : 16),
      child: ElevatedButton(
        onPressed: _isCreating ? null : _createTask,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isCreating
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Text(
                'Create Task',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }

  /// Pick due date using date picker
  Future<void> _pickDueDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDueDate = picked;
      });
    }
  }

  /// Create task and navigate back
  Future<void> _createTask() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isCreating = true;
    });

    try {
      await ref.read(taskViewModelProvider.notifier).createTask(
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim(),
            dueDate: _selectedDueDate,
          );

      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Task created successfully!'),
            backgroundColor: Theme.of(context).colorScheme.onSurface,
          ),
        );

        // Navigate back
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        final errorMessage = 'Failed to create task: $e';
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
    } finally {
      if (mounted) {
        setState(() {
          _isCreating = false;
        });
      }
    }
  }
}
