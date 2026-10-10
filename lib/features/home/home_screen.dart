import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:skillbridge_python_lab/core/di/app_dependencies.dart';
import 'package:skillbridge_python_lab/app/theme.dart';
import 'package:skillbridge_python_lab/integrations/lms/lms_models.dart';
import 'package:skillbridge_python_lab/features/exercises/exercise.dart';
import 'connectivity_controller.dart';
import 'home_controller.dart';

/// Screen A: Home. Shows branding, progress, recent exercises, drafts and the
/// pending-submission queue, with a clear connection indicator.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final HomeController _controller;

  @override
  void initState() {
    super.initState();
    _controller = HomeController(context.read<AppDependencies>());
    _controller.load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _openExercise(Exercise exercise) async {
    await Navigator.of(context).pushNamed('/editor', arguments: exercise);
    if (mounted) await _controller.refreshLocal();
  }

  Future<void> _openDetails(Exercise exercise) async {
    await Navigator.of(context).pushNamed('/exercise', arguments: exercise);
    if (mounted) await _controller.refreshLocal();
  }

  @override
  Widget build(BuildContext context) {
    final connectivity = context.watch<ConnectivityController>();
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await connectivity.syncNow();
            await _controller.load();
          },
          child: ListenableBuilder(
            listenable: _controller,
            builder: (context, _) {
              return CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  const SliverToBoxAdapter(child: _BrandHeader()),
                  SliverToBoxAdapter(child: _StatusStrip(connectivity: connectivity)),
                  SliverToBoxAdapter(child: _ProgressCard(progress: _controller.progress)),
                  SliverToBoxAdapter(
                    child: _ContinueCard(
                      exercise: _controller.continueExercise,
                      onTap: _controller.continueExercise == null
                          ? null
                          : () => _openExercise(_controller.continueExercise!),
                    ),
                  ),
                  if (_controller.isFromCache && _controller.exercises.isNotEmpty)
                    const SliverToBoxAdapter(child: _InfoBanner(
                      icon: Icons.cloud_off,
                      text: 'Showing exercises saved on this device (offline).',
                    )),
                  if (_controller.error != null)
                    SliverToBoxAdapter(child: _InfoBanner(
                      icon: Icons.error_outline,
                      text: _controller.error!,
                      isError: true,
                    )),
                  SliverToBoxAdapter(
                    child: _SectionTitle(
                      title: 'Exercises',
                      subtitle: _controller.isLoading
                          ? 'Loading…'
                          : '${_controller.exercises.length} available',
                    ),
                  ),
                  if (_controller.isLoading && _controller.exercises.isEmpty)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    )
                  else if (_controller.exercises.isEmpty)
                    const SliverToBoxAdapter(child: _EmptyState())
                  else
                    SliverList.builder(
                      itemCount: _controller.exercises.length,
                      itemBuilder: (context, index) {
                        final exercise = _controller.exercises[index];
                        return _ExerciseTile(
                          exercise: exercise,
                          hasDraft: _controller.draftFor(exercise.id) != null,
                          onTap: () => _openDetails(exercise),
                        );
                      },
                    ),
                  if (_controller.drafts.isNotEmpty) ...[
                    const SliverToBoxAdapter(
                      child: _SectionTitle(title: 'Saved drafts'),
                    ),
                    SliverList.builder(
                      itemCount: _controller.drafts.length,
                      itemBuilder: (context, index) {
                        final draft = _controller.drafts[index];
                        final exercise = _controller.exercises
                            .where((e) => e.id == draft.exerciseId)
                            .cast<Exercise?>()
                            .firstWhere((e) => true, orElse: () => null);
                        return ListTile(
                          leading: const Icon(Icons.edit_note),
                          title: Text(exercise?.title ?? draft.exerciseId),
                          subtitle: Text('Saved ${_relativeTime(draft.updatedAt)}'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: exercise == null ? null : () => _openExercise(exercise),
                        );
                      },
                    ),
                  ],
                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  static String _relativeTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes} min ago';
    if (diff.inDays < 1) return '${diff.inHours} h ago';
    return '${diff.inDays} d ago';
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.brandBlueDark, AppTheme.brandBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.terminal, color: AppTheme.brandBlue),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'SkillBridge\nPython Lab',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    height: 1.1,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'Practise Python anywhere — write, run and submit your code, even offline.',
            style: TextStyle(color: Color(0xFFDCE9F7), fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _StatusStrip extends StatelessWidget {
  const _StatusStrip({required this.connectivity});

  final ConnectivityController connectivity;

  @override
  Widget build(BuildContext context) {
    final online = connectivity.isOnline;
    return Container(
      color: online ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(online ? Icons.wifi : Icons.wifi_off, size: 18,
              color: online ? const Color(0xFF2E7D32) : const Color(0xFFE65100)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              online ? 'Online' : 'Offline — your work is saved on this device',
              style: TextStyle(
                  fontSize: 12.5,
                  color: online ? const Color(0xFF1B5E20) : const Color(0xFF8D4E00)),
            ),
          ),
          if (connectivity.pendingCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.brandAmber,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('${connectivity.pendingCount} to sync',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
            ),
          if (connectivity.isSyncing)
            const Padding(
              padding: EdgeInsets.only(left: 8),
              child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else
            IconButton(
              icon: const Icon(Icons.sync, size: 20),
              tooltip: 'Sync now',
              onPressed: connectivity.syncNow,
            ),
        ],
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.progress});

  final LearnerProgress progress;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Your progress', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Row(
              children: [
                _Stat(label: 'Challenges', value: '${progress.completedChallenges}'),
                _Stat(label: 'SkillCoins', value: '${progress.totalPoints}'),
                _Stat(label: 'Available', value: '${progress.totalChallenges}'),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress.completionRatio,
                minHeight: 8,
                backgroundColor: Colors.grey.shade300,
              ),
            ),
            const SizedBox(height: 6),
            const Text('Points shown are verified by the SkillBridge LMS.',
                style: TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
          Text(label, style: const TextStyle(fontSize: 11.5, color: Colors.grey)),
        ],
      ),
    );
  }
}

class _ContinueCard extends StatelessWidget {
  const _ContinueCard({required this.exercise, required this.onTap});

  final Exercise? exercise;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: FilledButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.play_circle_outline),
        label: Text(
          exercise == null ? 'Start coding' : 'Continue: ${exercise!.title}',
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Row(
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const Spacer(),
          if (subtitle != null)
            Text(subtitle!, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }
}

class _ExerciseTile extends StatelessWidget {
  const _ExerciseTile({required this.exercise, required this.onTap, this.hasDraft = false});

  final Exercise exercise;
  final VoidCallback onTap;
  final bool hasDraft;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppTheme.brandBlue.withValues(alpha: 0.12),
        child: const Icon(Icons.code, color: AppTheme.brandBlue),
      ),
      title: Text(exercise.title),
      subtitle: Text(
        exercise.instructions,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: hasDraft
          ? const Chip(label: Text('Draft'), visualDensity: VisualDensity.compact)
          : const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({required this.icon, required this.text, this.isError = false});

  final IconData icon;
  final String text;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: isError ? Colors.red : Colors.orange.shade800),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 12.5))),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(Icons.inbox_outlined, size: 48, color: Colors.grey),
          SizedBox(height: 8),
          Text('No exercises yet', style: TextStyle(fontWeight: FontWeight.w600)),
          SizedBox(height: 4),
          Text(
            'Connect to the internet once to download your exercises. They will then work offline.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
