import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../widgets/task_list_widget.dart';
import '../models/task_model.dart';
import '../main.dart';
import 'task_detail_screen.dart';
import 'create_task_screen.dart';

/// HomeScreen - Main screen displaying task list
/// 
/// Features:
/// - Task list with infinite scrolling
/// - Floating action button to create tasks
/// - App bar with user info and sign out
/// - Responsive layout
/// - Smooth navigation animations
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authViewModelProvider);
    final user = authState.user;

    // Use LayoutBuilder for responsive design
    return LayoutBuilder(
      builder: (context, constraints) {
        final isTablet = constraints.maxWidth > 600;

        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'My Tasks',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            elevation: 0,
            actions: [
              // User info
              if (user != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Center(
                    child: Chip(
                      avatar: CircleAvatar(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        child: Text(
                          user.email[0].toUpperCase(),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      label: Text(
                        user.email.split('@')[0],
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),
                ),
              
              // Sign out button
              IconButton(
                icon: const Icon(Icons.logout),
                tooltip: 'Sign Out',
                onPressed: () => _showSignOutDialog(context, ref),
              ),
            ],
          ),
          body: const TaskListWidget(
            onTaskTap: _navigateToTaskDetail,
          ),
          floatingActionButton: _buildFAB(context, isTablet),
        );
      },
    );
  }

  /// Build floating action button for creating tasks
  Widget _buildFAB(BuildContext context, bool isTablet) {
    return FloatingActionButton.extended(
      onPressed: () => _navigateToCreateTask(context),
      icon: const Icon(Icons.add),
      label: Text(
        isTablet ? 'Create Task' : 'New',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      elevation: 4,
    );
  }

  /// Navigate to task detail screen
  static void _navigateToTaskDetail(TaskModel task) {
    // Get BuildContext from global navigator
    final context = navigatorKey.currentContext;
    if (context != null) {
      Navigator.of(context).push(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              TaskDetailScreen(task: task),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.easeInOut;
            
            var tween = Tween(begin: begin, end: end).chain(
              CurveTween(curve: curve),
            );
            
            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
        ),
      );
    }
  }

  /// Navigate to create task screen
  void _navigateToCreateTask(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const CreateTaskScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 1.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;
          
          var tween = Tween(begin: begin, end: end).chain(
            CurveTween(curve: curve),
          );
          
          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
      ),
    );
  }

  /// Show sign out confirmation dialog
  void _showSignOutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(authViewModelProvider.notifier).signOut();
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}
