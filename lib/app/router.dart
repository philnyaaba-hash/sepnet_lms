import 'package:flutter/material.dart';

import 'package:skillbridge_python_lab/features/editor/editor_screen.dart';
import 'package:skillbridge_python_lab/features/exercises/exercise.dart';
import 'package:skillbridge_python_lab/features/exercises/exercise_details_screen.dart';
import 'package:skillbridge_python_lab/features/lessons/lesson_screen.dart';
import 'package:skillbridge_python_lab/features/lms/lms_hub_screen.dart';
import 'package:skillbridge_python_lab/features/ai/ai_tutor_screen.dart';
import 'package:skillbridge_python_lab/features/lms/cloudinary_video_screen.dart';
import 'package:skillbridge_python_lab/features/achievements/achievements_screen.dart';
import 'package:skillbridge_python_lab/features/settings/settings_screen.dart';

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
  static const String lms = '/lms';
  static const String aiTutor = '/ai-tutor';
  static const String lmsVideo = '/lms-video';

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
        final onFinished = args is Map<String, dynamic>
            ? args['onFinished'] as VoidCallback?
            : null;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) =>
              LessonScreen(exercise: exercise, onFinished: onFinished),
        );
      case lms:
        final initialSection = settings.arguments is int
            ? settings.arguments as int
            : 0;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => LmsHubScreen(initialSection: initialSection),
        );
      case aiTutor:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const AiTutorScreen(),
        );
      case lmsVideo:
        final args = settings.arguments as Map<String, String>;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => CloudinaryVideoScreen(
            title: args['title'] ?? 'Python lesson',
            subtitle: args['subtitle'] ?? 'SkillsBridg Academy',
            publicId: args['publicId'] ?? '',
          ),
        );
      case '/progress':
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const AchievementsScreen(),
        );
      case '/settings':
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const SettingsScreen(),
        );
      default:
        return null;
    }
  }
}
