import 'package:flutter/material.dart';

import 'package:skillbridge_python_lab/features/editor/editor_screen.dart';
import 'package:skillbridge_python_lab/features/exercises/exercise.dart';
import 'package:skillbridge_python_lab/features/exercises/exercise_details_screen.dart';
import 'package:skillbridge_python_lab/features/lessons/lesson_screen.dart';

/// Central named-route table for pushed (full-screen) destinations.
///
/// Tab-level screens (Home, Progress, Settings) are hosted by the shell; only
/// detail destinations are routes.
class AppRouter {
  const AppRouter._();

  static const String home = '/';
  static const String editor = '/editor';
  static const String exercise = '/exercise';
  static const String lesson = '/lesson';

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case editor:
        final exercise = settings.arguments as Exercise;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => EditorScreen(exercise: exercise),
        );
      case exercise:
        final exercise = settings.arguments as Exercise;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => ExerciseDetailsScreen(exercise: exercise),
        );
      case lesson:
        // Arguments may be the bare exercise, or a map carrying a callback so
        // the caller can chain lesson -> editor without a second push.
        final args = settings.arguments;
        final exercise = switch (args) {
          final Exercise e => e,
          final Map<String, dynamic> a => a['exercise'] as Exercise,
          _ => throw ArgumentError('/lesson requires an Exercise argument.'),
        };
        final onFinished = args is Map<String, dynamic> ? args['onFinished'] as VoidCallback? : null;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => LessonScreen(exercise: exercise, onFinished: onFinished),
        );
      default:
        return null;
    }
  }
}
