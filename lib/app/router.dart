import 'package:flutter/material.dart';

import 'package:skillbridge_python_lab/features/editor/editor_screen.dart';
import 'package:skillbridge_python_lab/features/exercises/exercise.dart';
import 'package:skillbridge_python_lab/features/exercises/exercise_details_screen.dart';

/// Central named-route table for pushed (full-screen) destinations.
///
/// Tab-level screens (Home, Progress, Settings) are hosted by the shell; only
/// detail destinations are routes.
class AppRouter {
  const AppRouter._();

  static const String home = '/';
  static const String editor = '/editor';
  static const String exercise = '/exercise';

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
      default:
        return null;
    }
  }
}
