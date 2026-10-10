import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:skillbridge_python_lab/core/di/app_dependencies.dart';
import 'package:skillbridge_python_lab/app/theme.dart';
import 'achievements_controller.dart';

/// Screen: Achievements / progress. All points and achievements shown here come
/// from the LMS; nothing is awarded locally.
class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  late final AchievementsController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AchievementsController(context.read<AppDependencies>());
    _controller.load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Progress & SkillCoins')),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          if (_controller.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          final progress = _controller.progress;
          return RefreshIndicator(
            onRefresh: _controller.load,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  color: AppTheme.brandBlueDark,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Text('${progress.totalPoints}',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 40, fontWeight: FontWeight.w800)),
                        const Text('verified SkillCoins',
                            style: TextStyle(color: Color(0xFFB9D4EE))),
                        const SizedBox(height: 16),
                        Text(
                          '${progress.completedChallenges} of ${progress.totalChallenges} challenges completed',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Padding(
                  padding: EdgeInsets.all(8),
                  child: Text(
                    'SkillCoins are confirmed by the SkillBridge LMS after it grades your '
                    'submission. This app never awards coins on its own.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Achievements',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                if (_controller.achievements.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(
                      child: Text('Complete a challenge to earn your first achievement.',
                          textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                    ),
                  )
                else
                  for (final achievement in _controller.achievements)
                    Card(
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: AppTheme.brandAmber,
                          child: Icon(Icons.emoji_events, color: Colors.white),
                        ),
                        title: Text(achievement.title),
                        subtitle: Text(achievement.description),
                      ),
                    ),
                const SizedBox(height: 16),
                const Text('Recent submissions',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                if (_controller.recentSubmissions.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('No submissions yet.', style: TextStyle(color: Colors.grey)),
                  )
                else
                  for (final summary in _controller.recentSubmissions)
                    ListTile(
                      dense: true,
                      leading: const Icon(Icons.description_outlined),
                      title: Text(summary.exerciseId),
                      subtitle: Text(summary.state.replaceAll('_', ' ')),
                    ),
              ],
            ),
          );
        },
      ),
    );
  }
}
