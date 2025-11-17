import 'env.dart';

/// AppwriteConfig - Configuration for Appwrite backend connection
/// 
/// This configuration uses environment variables from .env file
/// secured with the envied package.
/// 
/// Setup Instructions:
/// 1. Create an Appwrite project at https://cloud.appwrite.io
/// 2. Navigate to your project settings  
/// 3. Copy the Project ID and API Endpoint
/// 4. Update the .env file with your credentials
/// 5. Run: flutter pub run build_runner build
class AppwriteConfig {
  /// Get the Appwrite Project ID from environment variables
  static String get projectId => Env.projectId;
  
  /// Get the Appwrite API Endpoint
  static String get endpoint => Env.apiEndpoint;
  
  /// Database ID for the Todo App
  static const String databaseId = 'todo_app_db';
  
  /// Tasks table/collection ID
  static const String tasksCollectionId = 'tasks';
}
