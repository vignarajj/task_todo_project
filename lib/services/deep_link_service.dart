import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';

/// DeepLinkService - Handles deep link navigation
/// 
/// This service listens for deep links from:
/// - Email magic URL links
/// - App invocations via custom scheme
class DeepLinkService {
  static final DeepLinkService _instance = DeepLinkService._internal();
  
  factory DeepLinkService() {
    return _instance;
  }
  
  DeepLinkService._internal();
  
  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;
  
  /// Callback for handling incoming deep links
  Function(Uri)? onLinkReceived;
  
  /// Initialize deep link listening
  Future<void> initialize() async {
    // Handle the initial link if app was opened from a deep link
    try {
      final initialLink = await _appLinks.getInitialLink();
      if (initialLink != null) {
        debugPrint('Initial deep link: $initialLink');
        onLinkReceived?.call(initialLink);
      }
    } catch (e) {
      debugPrint('Error getting initial link: $e');
    }
    
    // Listen for deep links while app is running
    _linkSubscription = _appLinks.uriLinkStream.listen(
      (uri) {
        debugPrint('Received deep link: $uri');
        onLinkReceived?.call(uri);
      },
      onError: (error) {
        debugPrint('Deep link error: $error');
      },
    );
  }
  
  /// Dispose and clean up subscriptions
  void dispose() {
    _linkSubscription?.cancel();
  }
  
  /// Extract Magic URL parameters from deep link
  /// Returns a map with 'userId' and 'secret' if found
  Map<String, String>? extractMagicUrlParams(Uri uri) {
    final userId = uri.queryParameters['userId'];
    final secret = uri.queryParameters['secret'];
    
    if (userId != null && secret != null) {
      return {
        'userId': userId,
        'secret': secret,
      };
    }
    
    return null;
  }
}
