import 'package:flutter/material.dart';

import '../../app/theme.dart';

class LmsHubScreen extends StatefulWidget {
  const LmsHubScreen({super.key, this.initialSection = 0});

  final int initialSection;

  @override
  State<LmsHubScreen> createState() => _LmsHubScreenState();
}

class _LmsHubScreenState extends State<LmsHubScreen> {
  late int _section;

  static const _sections = <({String label, IconData icon})>[
    (label: 'Courses', icon: Icons.auto_stories_rounded),
    (label: 'News', icon: Icons.campaign_rounded),
    (label: 'Resources', icon: Icons.download_rounded),
    (label: 'Certificate', icon: Icons.workspace_premium_rounded),
    (label: 'About', icon: Icons.info_outline_rounded),
  ];

  @override
  void initState() {
    super.initState();
    _section = widget.initialSection.clamp(0, _sections.length - 1).toInt();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SkillBridgeColors.background,
      appBar: AppBar(
        titleSpacing: 20,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'SkillsBridg Academy',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            Text(
              'Your learning hub',
              style: TextStyle(
                fontSize: 12,
                color: SkillBridgeColors.textMuted,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'About SkillsBridg Academy',
            onPressed: () => _showAbout(context),
            icon: const Icon(Icons.info_outline_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          _SectionSelector(
            selected: _section,
            onSelected: (index) => setState(() => _section = index),
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 280),
              child: _buildSection(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection() {
    return switch (_section) {
      0 => const _CoursesSection(key: ValueKey('courses')),
      1 => const _NewsSection(key: ValueKey('news')),
      2 => const _ResourcesSection(key: ValueKey('resources')),
      3 => const _CertificateSection(key: ValueKey('certificate')),
      _ => const _AboutSection(key: ValueKey('about')),
    };
  }

  void _showAbout(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: SkillBridgeColors.surface,
      builder: (context) => const Padding(
        padding: EdgeInsets.fromLTRB(24, 8, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'About SkillsBridg Academy',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            SizedBox(height: 10),
            Text(
              'SkillsBridg Academy makes technology education more accessible for every learner.',
              style: TextStyle(color: SkillBridgeColors.textMuted, height: 1.5),
            ),
            SizedBox(height: 14),
            Text(
              'Learn • Build • Grow',
              style: TextStyle(
                color: SkillBridgeColors.accent,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionSelector extends StatelessWidget {
  const _SectionSelector({required this.selected, required this.onSelected});

  final int selected;
  final ValueChanged<int> onSelected;

  static const _items = <({String label, IconData icon})>[
    (label: 'Courses', icon: Icons.auto_stories_rounded),
    (label: 'News', icon: Icons.campaign_rounded),
    (label: 'Resources', icon: Icons.download_rounded),
    (label: 'Certificate', icon: Icons.workspace_premium_rounded),
    (label: 'About', icon: Icons.info_outline_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 66,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        scrollDirection: Axis.horizontal,
        itemCount: _items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final item = _items[index];
          final active = selected == index;
          return ChoiceChip(
            selected: active,
            onSelected: (_) => onSelected(index),
            avatar: Icon(
              item.icon,
              size: 18,
              color: active ? Colors.white : SkillBridgeColors.textMuted,
            ),
            label: Text(item.label),
            labelStyle: TextStyle(
              color: active ? Colors.white : SkillBridgeColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
            selectedColor: SkillBridgeColors.primary,
            backgroundColor: SkillBridgeColors.surface,
            side: BorderSide(
              color: active
                  ? SkillBridgeColors.primary
                  : SkillBridgeColors.surfaceHigh,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          );
        },
      ),
    );
  }
}

class _CoursesSection extends StatelessWidget {
  const _CoursesSection({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
      children: [
        const _LmsHero(),
        const SizedBox(height: 18),
        Text(
          'Continue learning',
          style: Theme.of(context).textTheme.titleLarge
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        _CourseCard(onTap: () => _showCourse(context)),
        const SizedBox(height: 18),
        const Text(
          'Unit 1 · Python Kickstart',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        const Text(
          'Complete each lesson to open the next step.',
          style: TextStyle(color: SkillBridgeColors.textMuted),
        ),
        const SizedBox(height: 10),
        const _LessonJourney(),
        const SizedBox(height: 12),
        const _CourseJourneyMap(),
      ],
    );
  }

  void _showCourse(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Course player connected — choose a lesson to continue.'),
      ),
    );
  }
}

class _CourseJourneyMap extends StatelessWidget {
  const _CourseJourneyMap();

  static const lessons = <_MapLessonData>[
    _MapLessonData(
      '01',
      'Python Introduction',
      'Intro video',
      'https://res.cloudinary.com/ea91sdts/video/upload/v1791880576/01._Advancing_your_career_with_Python.mp4',
      _LessonState.open,
    ),
    _MapLessonData(
      '02',
      'Demystifying Python',
      '8h 45m',
      'https://res.cloudinary.com/ea91sdts/video/upload/v1791880586/01._Demystifying_Python_SEPNET.mp4',
      _LessonState.locked,
    ),
    _MapLessonData(
      '03',
      'Starting with Python',
      '15h 20m',
      'https://res.cloudinary.com/ea91sdts/video/upload/v1791880599/02._Starting_with_Python.mp4',
      _LessonState.locked,
    ),
    _MapLessonData(
      '04',
      'Comparing Python vs Java',
      'Next lesson',
      'https://res.cloudinary.com/ea91sdts/video/upload/v1791880607/03._Comparing_Python_vs_Java.mp4',
      _LessonState.locked,
    ),
    _MapLessonData(
      '05',
      'Harnessing the Power of Python',
      'Next lesson',
      'https://res.cloudinary.com/ea91sdts/video/upload/v1791880614/04._Harnessing_the_power_of_Python.mp4',
      _LessonState.locked,
    ),
    _MapLessonData(
      '06',
      'Setting Up Your Python Environment',
      'Next lesson',
      'https://res.cloudinary.com/ea91sdts/video/upload/v1791880631/01._Setting_up_your_Python_environment.mp4',
      _LessonState.locked,
    ),
    _MapLessonData(
      '07',
      'Sorting Your Types of Data',
      'Next lesson',
      'https://res.cloudinary.com/ea91sdts/video/upload/v1791880639/02._Sorting_your_types_of_data.mp4',
      _LessonState.locked,
    ),
    _MapLessonData(
      '08',
      'Storing Data Using Variables',
      'Next lesson',
      'https://res.cloudinary.com/ea91sdts/video/upload/v1791880644/03._Storing_data_using_variables.mp4',
      _LessonState.locked,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[
      const _MapStartNode(),
      const _MapConnector(label: 'Lesson path'),
    ];
    for (final lesson in lessons) {
      children.add(
        _LessonTile(
          number: lesson.number,
          title: lesson.title,
          duration: lesson.duration,
          publicId: lesson.publicId,
          state: lesson.state,
        ),
      );
      if (lesson != lessons.last)
        children.add(
          const _MapConnector(label: 'Complete this step to continue'),
        );
    }
    children.add(const _MapFinishNode());
    return Column(children: children);
  }
}

class _MapLessonData {
  const _MapLessonData(
    this.number,
    this.title,
    this.duration,
    this.publicId,
    this.state,
  );

  final String number;
  final String title;
  final String duration;
  final String publicId;
  final _LessonState state;
}

class _MapStartNode extends StatelessWidget {
  const _MapStartNode();

  @override
  Widget build(BuildContext context) => const _MapMilestone(
    icon: Icons.flag_rounded,
    label: 'START HERE',
    detail: 'Begin Unit 1: Python Kickstart',
    color: SkillBridgeColors.accent,
  );
}

class _MapFinishNode extends StatelessWidget {
  const _MapFinishNode();

  @override
  Widget build(BuildContext context) => const _MapMilestone(
    icon: Icons.emoji_events_rounded,
    label: 'UNIT FINISH',
    detail: 'Complete all videos and practicals',
    color: Color(0xFFFFC857),
  );
}

class _MapMilestone extends StatelessWidget {
  const _MapMilestone({
    required this.icon,
    required this.label,
    required this.detail,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String detail;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  detail,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MapConnector extends StatelessWidget {
  const _MapConnector({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 38,
    child: Row(
      children: [
        const SizedBox(width: 24),
        Container(width: 3, height: 38, color: SkillBridgeColors.surfaceHigh),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: SkillBridgeColors.textMuted,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

class _LmsHero extends StatelessWidget {
  const _LmsHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF5A2B5F), Color(0xFFAF5C46)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: const [
          BoxShadow(
            color: Color(0x335A2B5F),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.school_rounded, color: Colors.white, size: 30),
              SizedBox(width: 10),
              Text(
                'WELCOME BACK',
                style: TextStyle(
                  color: Color(0xFFFFE4D8),
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Text(
            'Python Quick Start',
            style: TextStyle(
              color: Colors.white,
              fontSize: 25,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'A friendly path from first line of code to real confidence.',
            style: TextStyle(color: Color(0xFFFFE8E0), height: 1.4),
          ),
          SizedBox(height: 18),
          _ProgressLine(),
        ],
      ),
    );
  }
}

class _ProgressLine extends StatelessWidget {
  const _ProgressLine();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                '33% complete',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              '1 of 3 lessons',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.75),
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: 0.33,
            minHeight: 8,
            backgroundColor: Colors.white24,
            valueColor: const AlwaysStoppedAnimation(Color(0xFFFFD166)),
          ),
        ),
      ],
    );
  }
}

class _CourseCard extends StatelessWidget {
  const _CourseCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: SkillBridgeColors.primary.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(17),
                ),
                child: const Icon(
                  Icons.code_rounded,
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
                      'Python Quick Start',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Beginner • 1h 47m',
                      style: TextStyle(
                        color: SkillBridgeColors.textMuted,
                        fontSize: 13,
                      ),
                    ),
                    SizedBox(height: 10),
                    LinearProgressIndicator(value: 0.33, minHeight: 6),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

class _LessonTile extends StatelessWidget {
  const _LessonTile({
    required this.number,
    required this.title,
    required this.duration,
    required this.publicId,
    required this.state,
  });

  final String number;
  final String title;
  final String duration;
  final String publicId;
  final _LessonState state;

  @override
  Widget build(BuildContext context) {
    final complete = state == _LessonState.completed;
    final locked = state == _LessonState.locked;
    final active = state == _LessonState.open;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: locked
            ? () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Complete the previous lesson to unlock this video.',
                  ),
                ),
              )
            : () => Navigator.of(context).pushNamed(
                '/lms-video',
                arguments: {
                  'title': title,
                  'subtitle': duration,
                  'publicId': publicId,
                },
              ),
        leading: CircleAvatar(
          backgroundColor: complete
              ? SkillBridgeColors.success.withValues(alpha: 0.16)
              : active
              ? SkillBridgeColors.primary.withValues(alpha: 0.18)
              : SkillBridgeColors.surfaceHigh,
          child: complete
              ? const Icon(
                  Icons.check_rounded,
                  color: SkillBridgeColors.success,
                )
              : locked
              ? const Icon(
                  Icons.lock_rounded,
                  color: SkillBridgeColors.textMuted,
                  size: 19,
                )
              : Text(
                  number,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: SkillBridgeColors.primary,
                  ),
                ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'LESSON $number',
              style: const TextStyle(
                color: SkillBridgeColors.accent,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 3),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
        subtitle: Text(
          '$duration · ${complete
              ? 'Completed'
              : locked
              ? 'Locked — complete previous lesson'
              : 'Open — video + practical'}',
          style: const TextStyle(color: SkillBridgeColors.textMuted),
        ),
        trailing: Icon(
          complete
              ? Icons.replay_rounded
              : locked
              ? Icons.lock_outline_rounded
              : Icons.play_circle_outline_rounded,
          color: complete
              ? SkillBridgeColors.success
              : locked
              ? SkillBridgeColors.textMuted
              : SkillBridgeColors.accent,
        ),
      ),
    );
  }
}

enum _LessonState { completed, open, locked }

class _LessonJourney extends StatelessWidget {
  const _LessonJourney();

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: SkillBridgeColors.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: SkillBridgeColors.surfaceHigh),
          ),
          child: Row(
            children: [
              _JourneyNode(
                icon: Icons.play_arrow_rounded,
                label: 'Start',
                color: SkillBridgeColors.accent,
                scale: value,
              ),
              Expanded(child: _JourneyConnector(progress: 0)),
              _JourneyNode(
                icon: Icons.lock_rounded,
                label: 'Locked',
                color: SkillBridgeColors.textMuted,
                scale: value,
              ),
              Expanded(child: _JourneyConnector(progress: 0)),
              _JourneyNode(
                icon: Icons.lock_rounded,
                label: 'Later',
                color: SkillBridgeColors.textMuted,
                scale: value,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _JourneyNode extends StatelessWidget {
  const _JourneyNode({
    required this.icon,
    required this.label,
    required this.color,
    required this.scale,
  });

  final IconData icon;
  final String label;
  final Color color;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Transform.scale(
          scale: 0.82 + (scale * 0.18),
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.16),
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: 0.6), width: 2),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: color,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _JourneyConnector extends StatelessWidget {
  const _JourneyConnector({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: progress),
        duration: const Duration(milliseconds: 700),
        builder: (context, value, _) => LinearProgressIndicator(
          value: value,
          minHeight: 5,
          backgroundColor: SkillBridgeColors.surfaceHigh,
          valueColor: const AlwaysStoppedAnimation(SkillBridgeColors.primary),
        ),
      ),
    );
  }
}

class _NewsSection extends StatelessWidget {
  const _NewsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
      children: const [
        _NewsCard(
          title: 'Welcome to the SkillsBridg Academy',
          tag: 'GENERAL',
          date: '20 Sep 2026',
          text: 'Access Python lessons anytime, track your progress, and keep building your future.',
        ),
        _NewsCard(
          title: 'New cohort enrollment open',
          tag: 'ENROLLMENT',
          date: '18 Sep 2026',
          text: 'Seats are limited. Scholarships are available for eligible learners.',
        ),
        _NewsCard(
          title: 'Weekly live Q&A sessions',
          tag: 'SCHEDULE',
          date: '15 Sep 2026',
          text: 'Bring your questions every Saturday at 10:00 AM GMT.',
        ),
      ],
    );
  }
}

class _NewsCard extends StatelessWidget {
  const _NewsCard({
    required this.title,
    required this.tag,
    required this.date,
    required this.text,
  });

  final String title;
  final String tag;
  final String date;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(17),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  tag,
                  style: const TextStyle(
                    color: SkillBridgeColors.accent,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
                const Spacer(),
                Text(
                  date,
                  style: const TextStyle(
                    color: SkillBridgeColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
            ),
            const SizedBox(height: 6),
            Text(
              text,
              style: const TextStyle(
                color: SkillBridgeColors.textMuted,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResourcesSection extends StatelessWidget {
  const _ResourcesSection({super.key});

  @override
  Widget build(BuildContext context) {
    const resources = [
      (
        'Python Basics Cheat Sheet',
        'PDF',
        'Syntax, data types and common operations',
      ),
      (
        'Course Slides - Demystifying Python',
        'PDF',
        'Slides from the Python sessions',
      ),
      ('Practice Exercises', 'ZIP', 'Hands-on exercises with solutions'),
      (
        'Career Guide - Tech in Ghana',
        'PDF',
        'CV tips, interviews and opportunities',
      ),
    ];
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
      children: [
        for (final item in resources)
          Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              leading: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: SkillBridgeColors.primary.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.description_rounded,
                  color: SkillBridgeColors.accent,
                ),
              ),
              title: Text(
                item.$1,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(
                item.$3,
                style: const TextStyle(color: SkillBridgeColors.textMuted),
              ),
              trailing: Chip(label: Text(item.$2)),
              onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${item.$1} is ready to download.')),
              ),
            ),
          ),
      ],
    );
  }
}

class _CertificateSection extends StatelessWidget {
  const _CertificateSection({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
      children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: SkillBridgeColors.surface,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: SkillBridgeColors.surfaceHigh),
          ),
          child: const Column(
            children: [
              Icon(
                Icons.workspace_premium_rounded,
                color: SkillBridgeColors.accent,
                size: 62,
              ),
              SizedBox(height: 14),
              Text(
                'Your certificate is waiting',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                'Complete every lesson to unlock your SkillsBridg Academy certificate.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: SkillBridgeColors.textMuted,
                  height: 1.45,
                ),
              ),
              SizedBox(height: 20),
              LinearProgressIndicator(value: 0.33, minHeight: 9),
              SizedBox(height: 10),
              Text(
                '33% overall progress',
                style: TextStyle(
                  color: SkillBridgeColors.textMuted,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        const Card(
          child: ListTile(
            leading: Icon(Icons.lock_outline_rounded),
            title: Text('Certificate unlocks at 100%'),
            subtitle: Text('Keep learning — you are closer than you think.'),
          ),
        ),
      ],
    );
  }
}

class _AboutSection extends StatelessWidget {
  const _AboutSection({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF17315A), Color(0xFF0F5FC0)],
            ),
            borderRadius: BorderRadius.circular(26),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.public_rounded, color: Colors.white, size: 42),
              SizedBox(height: 18),
              Text(
                'Learn • Build • Grow',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'SkillsBridg Academy makes technology education more accessible for every learner.',
                style: TextStyle(color: Color(0xFFD8E9FF), height: 1.5),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        const Card(
          child: ListTile(
            leading: Icon(
              Icons.favorite_outline_rounded,
              color: SkillBridgeColors.accent,
            ),
            title: Text('Built for opportunity'),
            subtitle: Text(
              'Learn practical skills at your own pace, on any device.',
            ),
          ),
        ),
        const Card(
          child: ListTile(
            leading: Icon(
              Icons.groups_rounded,
              color: SkillBridgeColors.accent,
            ),
            title: Text('A community that supports you'),
            subtitle: Text(
              'Stay connected to mentors, announcements and new cohorts.',
            ),
          ),
        ),
      ],
    );
  }
}
