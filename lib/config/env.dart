import 'package:envied/envied.dart';

part 'env.g.dart';

/// Environment configuration using envied
/// 
/// This class loads environment variables from .env file
/// Values are obfuscated in release builds for security
@Envied(path: '.env')
abstract class Env {
  /// Appwrite Project ID
  @EnviedField(varName: 'PROJECT_ID')
  static const String projectId = _Env.projectId;
  
  /// Appwrite API Endpoint
  @EnviedField(varName: 'API_END_POINT')
  static const String apiEndpoint = _Env.apiEndpoint;
  
  /// Appwrite API Key (for server-side operations if needed)
  @EnviedField(varName: 'API_KEY')
  static const String apiKey = _Env.apiKey;
}
