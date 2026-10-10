import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app/app.dart';
import 'core/di/app_dependencies.dart';
import 'features/home/connectivity_controller.dart';
import 'features/settings/settings_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BootstrapApp());
}

/// Builds the dependency graph before the first frame, showing clear loading
/// and error states (important on slow, low-end devices).
class BootstrapApp extends StatefulWidget {
  const BootstrapApp({super.key});

  @override
  State<BootstrapApp> createState() => _BootstrapAppState();
}

class _BootstrapAppState extends State<BootstrapApp> {
  late Future<AppDependencies> _bootstrap;

  @override
  void initState() {
    super.initState();
    _bootstrap = AppDependencies.create();
  }

  void _retry() {
    setState(() => _bootstrap = AppDependencies.create());
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppDependencies>(
      future: _bootstrap,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const MaterialApp(
            debugShowCheckedModeBanner: false,
            home: _LoadingScreen(),
          );
        }
        if (snapshot.hasError) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            home: _ErrorScreen(message: '${snapshot.error}', onRetry: _retry),
          );
        }
        final deps = snapshot.data!;
        return MultiProvider(
          providers: [
            Provider<AppDependencies>.value(value: deps),
            ChangeNotifierProvider<SettingsController>(
              create: (_) => SettingsController(deps.settings),
            ),
            ChangeNotifierProvider<ConnectivityController>(
              create: (_) => ConnectivityController(deps),
            ),
          ],
          child: const SkillBridgeApp(),
        );
      },
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
            Text('SkillBridge Python Lab', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
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
              const Text('The app could not start', style: TextStyle(fontWeight: FontWeight.w700)),
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
