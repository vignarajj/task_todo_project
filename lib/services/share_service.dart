import 'package:share_plus/share_plus.dart';

/// ShareService - Handles task sharing functionality
/// 
/// Uses share_plus package to share tasks via:
/// - Email
/// - SMS
/// - Social media
/// - Other sharing apps available on the device
class ShareService {
  /// Share a task via the device's native sharing dialog
  /// 
  /// [taskId] - ID of the task to share
  /// [taskTitle] - Title of the task for the share message
  /// [appUrl] - Base URL of your app for deep linking
  /// 
  /// The shared link format: yourapp://task/{taskId}
  /// Configure deep linking in your app to handle this URL
  Future<void> shareTask({
    required String taskId,
    required String taskTitle,
    String appUrl = 'yourapp://task',
  }) async {
    try {
      // Generate shareable link
      final String shareLink = '$appUrl/$taskId';
      
      // Create share message
      final String shareMessage = '''
Check out this task: $taskTitle

Join me to collaborate on this task!
Link: $shareLink

Download the app to get started.
''';

      // Share using native share dialog
      await Share.share(
        shareMessage,
        subject: 'Task Shared: $taskTitle',
      );
    } catch (e) {
      throw Exception('Error sharing task: $e');
    }
  }

  /// Share multiple tasks at once
  /// 
  /// [taskIds] - List of task IDs to share
  /// [appUrl] - Base URL of your app for deep linking
  Future<void> shareMultipleTasks({
    required List<String> taskIds,
    String appUrl = 'yourapp://task',
  }) async {
    try {
      if (taskIds.isEmpty) {
        throw Exception('No tasks to share');
      }

      // Generate share message with all task links
      final StringBuffer messageBuffer = StringBuffer();
      messageBuffer.writeln('I\'d like to share these tasks with you:');
      messageBuffer.writeln();
      
      for (int i = 0; i < taskIds.length; i++) {
        messageBuffer.writeln('${i + 1}. $appUrl/${taskIds[i]}');
      }
      
      messageBuffer.writeln();
      messageBuffer.writeln('Download the app to collaborate!');

      // Share using native share dialog
      await Share.share(
        messageBuffer.toString(),
        subject: 'Shared Tasks',
      );
    } catch (e) {
      throw Exception('Error sharing tasks: $e');
    }
  }

  /// Share task with specific email address
  /// Note: This uses the share dialog, but you can pre-fill email apps
  /// 
  /// [taskId] - ID of the task to share
  /// [taskTitle] - Title of the task
  /// [recipientEmail] - Email address of the recipient
  Future<void> shareTaskViaEmail({
    required String taskId,
    required String taskTitle,
    required String recipientEmail,
    String appUrl = 'yourapp://task',
  }) async {
    try {
      final String shareLink = '$appUrl/$taskId';
      
      final String emailBody = '''
Hello,

I'd like to share a task with you: $taskTitle

Click the link below to view and collaborate:
$shareLink

Best regards
''';

      await Share.share(
        emailBody,
        subject: 'Task Invitation: $taskTitle',
      );
    } catch (e) {
      throw Exception('Error sharing task via email: $e');
    }
  }
}
