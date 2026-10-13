import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:skillbridge_python_lab/core/di/app_dependencies.dart';
import 'package:skillbridge_python_lab/app/theme.dart';
import 'package:skillbridge_python_lab/integrations/lms/lms_models.dart';
import 'package:skillbridge_python_lab/features/exercises/exercise.dart';
import 'package:skillbridge_python_lab/shared/widgets/code_buddy.dart';
import 'package:skillbridge_python_lab/shared/widgets/entrance.dart';

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
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedTab = 0;

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
    if (exercise.hasLesson) {
      await Navigator.of(context).pushNamed(
        '/lesson',
        arguments: {
          'exercise': exercise,
          'onFinished': () {
            Navigator.of(context)
                .pushReplacementNamed('/editor', arguments: exercise);
          },
        },
      );
    } else {
      await Navigator.of(context).pushNamed('/editor', arguments: exercise);
    }
    if (mounted) await _controller.refreshLocal();
  }

  Future<void> _openDetails(Exercise exercise) async {
    if (exercise.hasLesson) {
      await Navigator.of(context).pushNamed(
        '/lesson',
        arguments: {
          'exercise': exercise,
          'onFinished': () {
            Navigator.of(context)
                .pushReplacementNamed('/editor', arguments: exercise);
          },
        },
      );
    } else {
      await Navigator.of(context).pushNamed('/exercise', arguments: exercise);
    }
    if (mounted) await _controller.refreshLocal();
  }

  @override
  Widget build(BuildContext context) {
    final connectivity = context.watch<ConnectivityController>();
    return Scaffold(
      key: _scaffoldKey,
      drawer: _LmsDrawer(onDestinationSelected: _openLmsSection),
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
                  SliverToBoxAdapter(
                    child: _BrandHeader(onMenuTap: _openLmsDrawer),
                  ),
                  SliverToBoxAdapter(
                    child: Entrance(
                      index: 1,
                      child: _StatusStrip(connectivity: connectivity),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Entrance(
                      index: 2,
                      child: _LearnerGreeting(progress: _controller.progress),
                    ),
                  ),
                  const SliverToBoxAdapter(
                    child: Entrance(index: 3, child: _DailyMissionCard()),
                  ),
                  SliverToBoxAdapter(
                    child: Entrance(
                      index: 4,
                      child: _ProgressCard(progress: _controller.progress),
                    ),
                  ),
                  const SliverToBoxAdapter(
                    child: Entrance(index: 5, child: _BadgeRow()),
                  ),
                  SliverToBoxAdapter(
                    child: _ContinueCard(
                      exercise: _controller.continueExercise,
                      onTap: _controller.continueExercise == null
                          ? null
                          : () => _openExercise(_controller.continueExercise!),
                    ),
                  ),
                  if (_controller.isFromCache &&
                      _controller.exercises.isNotEmpty)
                    const SliverToBoxAdapter(
                      child: _InfoBanner(
                        icon: Icons.cloud_off_rounded,
                        text: 'Showing challenges saved on this device.',
                      ),
                    ),
                  if (_controller.error != null)
                    SliverToBoxAdapter(
                      child: _InfoBanner(
                        icon: Icons.error_outline_rounded,
                        text: _controller.error!,
                        isError: true,
                      ),
                    ),
                  SliverToBoxAdapter(
                    child: _SectionTitle(
                      title: 'Practice challenges',
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
                        return Entrance(
                          index: index.clamp(0, 8),
                          child: _ExerciseTile(
                            exercise: exercise,
                            hasDraft: _controller.draftFor(exercise.id) != null,
                            onTap: () => _openDetails(exercise),
                          ),
                        );
                      },
                    ),
                  if (_controller.drafts.isNotEmpty) ...[
                    const SliverToBoxAdapter(
                      child: _SectionTitle(title: 'Your drafts'),
                    ),
                    SliverList.builder(
                      itemCount: _controller.drafts.length,
                      itemBuilder: (context, index) {
                        final draft = _controller.drafts[index];
                        final exercise = _controller.exercises
                            .where((e) => e.id == draft.exerciseId)
                            .cast<Exercise?>()
                            .firstWhere((e) => true, orElse: () => null);
                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 5,
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: ListTile(
                            leading: const Icon(
                              Icons.edit_note_rounded,
                              color: SkillBridgeColors.accent,
                            ),
                            title: Text(
                              exercise?.title ?? draft.exerciseId,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            subtitle: Text(
                              'Saved ${_relativeTime(draft.updatedAt)}',
                            ),
                            trailing: const Icon(Icons.chevron_right_rounded),
                            onTap: exercise == null
                                ? null
                                : () => _openExercise(exercise),
                          ),
                        );
                      },
                    ),
                  ],
                  const SliverToBoxAdapter(child: SizedBox(height: 28)),
                ],
              );
            },
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedTab,
        onDestinationSelected: (index) {
          setState(() => _selectedTab = index);
          if (index == 1 && _controller.continueExercise != null) {
            Navigator.of(context)
                .pushNamed('/editor', arguments: _controller.continueExercise);
          } else if (index == 2) {
            Navigator.of(context).pushNamed('/progress');
          } else if (index == 3) {
            Navigator.of(context).pushNamed('/ai-tutor');
          } else if (index == 4) {
            Navigator.of(context).pushNamed('/settings');
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Learn',
          ),
          NavigationDestination(
            icon: Icon(Icons.code_outlined),
            selectedIcon: Icon(Icons.code_rounded),
            label: 'Code',
          ),
          NavigationDestination(
            icon: Icon(Icons.emoji_events_outlined),
            selectedIcon: Icon(Icons.emoji_events_rounded),
            label: 'Progress',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_awesome_outlined),
            selectedIcon: Icon(Icons.auto_awesome),
            label: 'Tutor',
          ),
          NavigationDestination(
            icon: Icon(Icons.more_horiz_rounded),
            selectedIcon: Icon(Icons.more_horiz_rounded),
            label: 'More',
          ),
        ],
      ),
    );
  }

  void _openLmsDrawer() => _scaffoldKey.currentState?.openDrawer();

  Future<void> _openLmsSection(int section) async {
    Navigator.of(context).pop();
    await Future<void>.delayed(const Duration(milliseconds: 280));
    if (mounted) Navigator.of(context).pushNamed('/lms', arguments: section);
  }

  static String _relativeTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes} min ago';
    if (diff.inDays < 1) return '${diff.inHours} h ago';
    return '${diff.inDays} d ago';
  }
}

class _LmsDrawer extends StatelessWidget {
  const _LmsDrawer({required this.onDestinationSelected});

  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: MediaQuery.sizeOf(context).width * 0.86,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(28)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(22, 22, 18, 20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF5A2B5F), Color(0xFFAF5C46)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(topRight: Radius.circular(28)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(17),
                    ),
                    child: const Icon(
                      Icons.school_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SKILLSBRIDG ACADEMY',
                          style: TextStyle(
                            color: Color(0xFFFFE4D8),
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Your learning hub',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    color: Colors.white,
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: SkillBridgeColors.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: SkillBridgeColors.surfaceHigh),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.auto_stories_rounded,
                      color: SkillBridgeColors.accent,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Python Quick Start',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                          SizedBox(height: 3),
                          Text(
                            '33% complete • keep going',
                            style: TextStyle(
                              fontSize: 12,
                              color: SkillBridgeColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: SkillBridgeColors.textMuted,
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(10, 6, 10, 8),
                    child: Text(
                      'LEARNING SPACE',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.3,
                        color: SkillBridgeColors.textMuted,
                      ),
                    ),
                  ),
                  _DrawerItem(
                    icon: Icons.auto_stories_rounded,
                    label: 'My Courses',
                    caption: 'Continue your path',
                    onTap: () => onDestinationSelected(0),
                  ),
                  _DrawerItem(
                    icon: Icons.campaign_rounded,
                    label: 'Announcements',
                    caption: 'What is happening',
                    onTap: () => onDestinationSelected(1),
                  ),
                  _DrawerItem(
                    icon: Icons.download_rounded,
                    label: 'Resources',
                    caption: 'Cheat sheets and guides',
                    onTap: () => onDestinationSelected(2),
                  ),
                  _DrawerItem(
                    icon: Icons.workspace_premium_rounded,
                    label: 'Certificate',
                    caption: 'Track your achievement',
                    onTap: () => onDestinationSelected(3),
                  ),
                  const Divider(height: 30),
                  _DrawerItem(
                    icon: Icons.info_outline_rounded,
                    label: 'About SkillsBridg',
                    caption: 'Learn • Build • Grow',
                    onTap: () => onDestinationSelected(4),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 8, 22, 18),
              child: Row(
                children: [
                  const Icon(
                    Icons.offline_bolt_rounded,
                    size: 18,
                    color: SkillBridgeColors.success,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Works offline on this device',
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: SkillBridgeColors.textMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.caption,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String caption;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: SkillBridgeColors.primary.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Icon(icon, color: SkillBridgeColors.primary),
      ),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
      subtitle: Text(
        caption,
        style: const TextStyle(
          fontSize: 12,
          color: SkillBridgeColors.textMuted,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: SkillBridgeColors.textMuted,
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader({required this.onMenuTap});

  final VoidCallback onMenuTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 26),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0B2547), Color(0xFF0F5FC0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: onMenuTap,
                tooltip: 'Open LMS menu',
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.14),
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.menu_rounded),
              ),
              const SizedBox(width: 8),
              const CodeBuddy(size: 88, mood: BuddyMood.happy),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SKILLSBRIDG ACADEMY',
                      style: TextStyle(
                        color: Color(0xFFBFE0FF),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 3,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Python Lab',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        height: 1.1,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Write, run and submit real Python anywhere, even offline.',
            style: TextStyle(
              color: Color(0xFFD8E9FF),
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _LearnerGreeting extends StatelessWidget {
  const _LearnerGreeting({required this.progress});

  final LearnerProgress progress;

  @override
  Widget build(BuildContext context) {
    final hasStarted = progress.completedChallenges > 0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: SkillBridgeColors.primary.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: SkillBridgeColors.primary.withValues(alpha: 0.35),
              ),
            ),
            child: const Icon(
              Icons.waving_hand_rounded,
              color: SkillBridgeColors.accent,
              size: 30,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasStarted
                      ? 'Welcome back'
                      : 'Welcome to SkillsBridg Academy',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  hasStarted
                      ? 'Pick up where you left off and keep your streak alive.'
                      : 'Your first Python adventure begins here.',
                  style: const TextStyle(
                    color: SkillBridgeColors.textMuted,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DailyMissionCard extends StatelessWidget {
  const _DailyMissionCard();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF17315A), Color(0xFF14508F)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: const Color(0xFF3E8DDE).withValues(alpha: 0.6),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: SkillBridgeColors.accent.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.rocket_launch_rounded,
                color: SkillBridgeColors.accent,
                size: 28,
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Today's mission",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Finish one lesson. Just five minutes builds real skill.',
                    style: TextStyle(color: Color(0xFFD8E9FF), height: 1.35),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.white),
          ],
        ),
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
    final tone = online ? SkillBridgeColors.success : SkillBridgeColors.accent;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: SkillBridgeColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tone.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(
            online ? Icons.wifi_rounded : Icons.wifi_off_rounded,
            size: 18,
            color: tone,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              online
                  ? 'Connected'
                  : 'Offline mode · your work is saved on this device',
              style: const TextStyle(
                fontSize: 13,
                color: SkillBridgeColors.textPrimary,
              ),
            ),
          ),
          if (connectivity.pendingCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                gradient: SkillBridgeColors.goldGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${connectivity.pendingCount} to sync',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF2A1D00),
                ),
              ),
            ),
          if (connectivity.isSyncing)
            const Padding(
              padding: EdgeInsets.only(left: 10, right: 6),
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.sync_rounded, size: 20),
              tooltip: 'Sync now',
              onPressed: connectivity.syncNow,
            ),
        ],
      ),
    );
  }
}

class _BadgeRow extends StatelessWidget {
  const _BadgeRow();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Milestones',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          Row(
            children: const [
              _MiniBadge(
                icon: Icons.lightbulb_rounded,
                label: 'Curious mind',
                color: Color(0xFFFFC857),
              ),
              SizedBox(width: 10),
              _MiniBadge(
                icon: Icons.code_rounded,
                label: 'Code explorer',
                color: Color(0xFF63B3FF),
              ),
              SizedBox(width: 10),
              _MiniBadge(
                icon: Icons.favorite_rounded,
                label: 'Keep going',
                color: Color(0xFFFF7D9A),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  const _MiniBadge({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
        decoration: BoxDecoration(
          color: SkillBridgeColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11.5,
                color: SkillBridgeColors.textMuted,
              ),
            ),
          ],
        ),
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
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your progress',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                _Stat(
                  label: 'Completed',
                  value: '${progress.completedChallenges}',
                ),
                _Stat(
                  label: 'SkillCoins',
                  value: '${progress.totalPoints}',
                  gold: true,
                ),
                _Stat(
                  label: 'Challenges',
                  value: '${progress.totalChallenges}',
                ),
              ],
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(
                  begin: 0,
                  end: progress.completionRatio.toDouble(),
                ),
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) => LinearProgressIndicator(
                  value: value,
                  minHeight: 10,
                  backgroundColor: SkillBridgeColors.surfaceHigh,
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'SkillCoins are verified by your SkillBridge account.',
              style: TextStyle(
                fontSize: 12,
                color: SkillBridgeColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, this.gold = false});

  final String label;
  final String value;
  final bool gold;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              color: gold
                  ? SkillBridgeColors.accent
                  : SkillBridgeColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: SkillBridgeColors.textMuted,
            ),
          ),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: FilledButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.play_arrow_rounded, size: 26),
        label: Text(
          exercise == null ? 'START CODING' : 'CONTINUE · ${exercise!.title}',
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
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 6),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
            ),
          ),
          const Spacer(),
          if (subtitle != null)
            Text(
              subtitle!,
              style: const TextStyle(
                fontSize: 12.5,
                color: SkillBridgeColors.textMuted,
              ),
            ),
        ],
      ),
    );
  }
}

class _ExerciseTile extends StatelessWidget {
  const _ExerciseTile({
    required this.exercise,
    required this.onTap,
    this.hasDraft = false,
  });

  final Exercise exercise;
  final VoidCallback onTap;
  final bool hasDraft;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: CircleAvatar(
          backgroundColor: SkillBridgeColors.primary.withValues(alpha: 0.14),
          child: const Icon(
            Icons.code_rounded,
            color: SkillBridgeColors.primary,
          ),
        ),
        title: Text(
          exercise.title,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        subtitle: Text(
          exercise.instructions,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: hasDraft
            ? const Chip(
                label: Text('Draft'),
                visualDensity: VisualDensity.compact,
              )
            : const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({
    required this.icon,
    required this.text,
    this.isError = false,
  });

  final IconData icon;
  final String text;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final tone = isError ? SkillBridgeColors.error : SkillBridgeColors.accent;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: tone),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                color: SkillBridgeColors.textMuted,
              ),
            ),
          ),
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
          CodeBuddy(size: 110, mood: BuddyMood.thinking),
          SizedBox(height: 10),
          Text(
            'Nothing here yet',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
          SizedBox(height: 6),
          Text(
            "Connect to the internet once to download your challenges. They'll then work offline.",
            textAlign: TextAlign.center,
            style: TextStyle(color: SkillBridgeColors.textMuted, height: 1.4),
          ),
        ],
      ),
    );
  }
}
