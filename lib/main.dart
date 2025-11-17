import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'views/auth_screen.dart';
import 'views/home_screen.dart';
import 'viewmodels/auth_viewmodel.dart';

/// Global navigator key for navigation from static contexts
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// Main entry point of the TODO Flutter app
/// 
/// This app demonstrates:
/// - MVVM architecture with Riverpod state management
/// - Appwrite backend integration for real-time collaboration
/// - Email + Magic URL authentication with deep linking
/// - Infinite scrolling with pagination
/// - Task sharing via share_plus
/// - Responsive design for all screen sizes
/// - Smooth animations and transitions
/// - Comprehensive error handling
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Run app with Riverpod provider scope
  runApp(
    const ProviderScope(
      child: TodoApp(),
    ),
  );
}

/// TodoApp - Root widget of the application
/// 
/// Features:
/// - Material Design with light/dark theme support
/// - Authentication state-based routing
/// - Global navigator key for navigation
class TodoApp extends ConsumerWidget {
  const TodoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'TODO App',
      debugShowCheckedModeBanner: false,
      
      // Navigator key for global navigation access
      navigatorKey: navigatorKey,
      
      // Theme configuration
      theme: _buildLightTheme(),
      darkTheme: _buildDarkTheme(),
      themeMode: ThemeMode.system,
      
      // Home widget with authentication routing
      home: const AuthenticationWrapper(),
    );
  }

  /// Build light theme with Material 3 - Black and White only
  ThemeData _buildLightTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.light(
        primary: Colors.black,
        onPrimary: Colors.white,
        secondary: Colors.black,
        onSecondary: Colors.white,
        surface: Colors.white,
        onSurface: Colors.black,
        error: Colors.black,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: Colors.white,
      cardTheme: CardThemeData(
        elevation: 2,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Colors.black, width: 1),
        ),
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.black),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.black),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.black, width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.black,
          side: const BorderSide(color: Colors.black),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: Colors.black,
        ),
      ),
    );
  }

  /// Build dark theme with Material 3 - Black and White only
  ThemeData _buildDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.dark(
        primary: Colors.white,
        onPrimary: Colors.black,
        secondary: Colors.white,
        onSecondary: Colors.black,
        surface: Colors.black,
        onSurface: Colors.white,
        error: Colors.white,
        onError: Colors.black,
      ),
      scaffoldBackgroundColor: Colors.black,
      cardTheme: CardThemeData(
        elevation: 2,
        color: Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Colors.white, width: 1),
        ),
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.black,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white, width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: const BorderSide(color: Colors.white),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: Colors.white,
        ),
      ),
    );
  }
}

/// AuthenticationWrapper - Handles routing based on authentication state
/// 
/// Displays:
/// - AuthScreen if user is not authenticated
/// - HomeScreen if user is authenticated
/// 
/// Uses Riverpod to watch authentication state changes
class AuthenticationWrapper extends ConsumerWidget {
  const AuthenticationWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authViewModelProvider);

    // Show loading indicator while checking auth state
    if (authState.isLoading && authState.user == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Route to appropriate screen based on authentication
    if (authState.isAuthenticated) {
      return const HomeScreen();
    } else {
      return const AuthScreen();
    }
  }
}
