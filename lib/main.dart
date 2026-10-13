import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app/router.dart';
import 'app/theme.dart';
import 'core/di/app_dependencies.dart';
import 'features/home/home_screen.dart';
import 'features/home/connectivity_controller.dart';
import 'features/settings/settings_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BootstrapApp());
}

/// Builds the dependency graph while showing clear loading and error states
/// (important on slow, low-end devices).
///
/// Two rules keep this stable:
///  1. One MaterialApp stays mounted for the whole app lifetime (swapping
///     MaterialApps caused an "inactive element" assertion).
///  2. Providers are installed through MaterialApp.builder, i.e. ABOVE the
///     Navigator. Pushed routes (editor, lesson, achievements, settings...)
///     are siblings of `home`, not children of it, so providers placed inside
///     `home` are invisible to them and throw ProviderNotFoundError.
///
/// The provider tree shape never changes between loading and loaded. Each
/// provider is lazy, so nothing reads `_deps` until a screen that needs it is
/// built, which only happens after loading has finished.
class BootstrapApp extends StatefulWidget {
  const BootstrapApp({super.key});

  @override
  State<BootstrapApp> createState() => _BootstrapAppState();
}

class _BootstrapAppState extends State<BootstrapApp> {
  AppDependencies? _deps;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final deps = await AppDependencies.create();
      if (!mounted) return;
      setState(() {
        _deps = deps;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e);
    }
  }

  void _retry() {
    setState(() {
      _deps = null;
      _error = null;
    });
    _load();
  }

  Widget _home() {
    if (_error != null) {
      return _ErrorScreen(message: '$_error', onRetry: _retry);
    }
    if (_deps == null) return const _LoadingScreen();
    return const HomeScreen();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SkillBridge Python Lab',
      debugShowCheckedModeBanner: false,
      theme: buildDarkTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: ThemeMode.dark,
      onGenerateRoute: AppRouter.onGenerateRoute,
      builder: (context, child) {
        return MultiProvider(
          providers: [
            Provider<AppDependencies>(create: (_) => _deps!),
            ChangeNotifierProvider<SettingsController>(
              create: (_) => SettingsController(_deps!.settings),
            ),
            ChangeNotifierProvider<ConnectivityController>(
              create: (_) => ConnectivityController(_deps!),
            ),
          ],
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: _home(),
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.terminal, size: 56),
            SizedBox(height: 16),
            Text(
              'SkillBridge Python Lab',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 24),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}

class _ErrorScreen extends StatelessWidget {
  const _ErrorScreen({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              const Text(
                'The app could not start',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 20),
              FilledButton(onPressed: onRetry, child: const Text('Try again')),
            ],
          ),
        ),
      ),
    );
  }
}
