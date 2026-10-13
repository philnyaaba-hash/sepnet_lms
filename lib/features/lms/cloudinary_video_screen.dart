import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../app/theme.dart';
import '../../integrations/cloudinary/cloudinary_config.dart';

class CloudinaryVideoScreen extends StatefulWidget {
  const CloudinaryVideoScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.publicId,
  });

  final String title;
  final String subtitle;
  final String publicId;

  @override
  State<CloudinaryVideoScreen> createState() => _CloudinaryVideoScreenState();
}

class _CloudinaryVideoScreenState extends State<CloudinaryVideoScreen> {
  VideoPlayerController? _controller;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _loadVideo();
  }

  Future<void> _loadVideo() async {
    setState(() => _error = null);
    final controller = VideoPlayerController.networkUrl(
      Uri.parse(CloudinaryConfig.videoUrl(widget.publicId)),
    );
    try {
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      final previous = _controller;
      setState(() => _controller = controller);
      await previous?.dispose();
    } catch (error) {
      await controller.dispose();
      if (mounted) setState(() => _error = error);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return Scaffold(
      backgroundColor: const Color(0xFF0E1018),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0E1018),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            Text(
              widget.subtitle,
              style: const TextStyle(
                fontSize: 12,
                color: SkillBridgeColors.textMuted,
              ),
            ),
          ],
        ),
      ),
      body: controller == null
          ? _LoadingOrError(
              error: _error,
              onRetry: _loadVideo,
              publicId: widget.publicId,
            )
          : ValueListenableBuilder<VideoPlayerValue>(
              valueListenable: controller,
              builder: (context, value, _) => ListView(
                padding: const EdgeInsets.only(bottom: 28),
                children: [
                  const _LearningPathHeader(),
                  _VideoSurface(controller: controller, value: value),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.subtitle,
                          style: const TextStyle(
                            color: Color(0xFFB8BAC6),
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 20),
                        _LessonMeta(value: value),
                        const SizedBox(height: 20),
                        const _InterwovenPractice(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _VideoSurface extends StatelessWidget {
  const _VideoSurface({
    required this.controller,
    required this.value,
    this.allowFullscreen = true,
  });

  final VideoPlayerController controller;
  final VideoPlayerValue value;
  final bool allowFullscreen;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: value.aspectRatio == 0 ? 16 / 9 : value.aspectRatio,
            child: Stack(
              alignment: Alignment.center,
              children: [
                VideoPlayer(controller),
                if (!value.isPlaying)
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: controller.play,
                      customBorder: const CircleBorder(),
                      child: Container(
                        width: 68,
                        height: 68,
                        decoration: const BoxDecoration(
                          color: SkillBridgeColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 38,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          _PlaybackControls(
            controller: controller,
            value: value,
            allowFullscreen: allowFullscreen,
          ),
        ],
      ),
    );
  }
}

class _PlaybackControls extends StatelessWidget {
  const _PlaybackControls({
    required this.controller,
    required this.value,
    required this.allowFullscreen,
  });

  final VideoPlayerController controller;
  final VideoPlayerValue value;
  final bool allowFullscreen;

  Duration _clamp(Duration position) {
    if (position < Duration.zero) return Duration.zero;
    if (position > value.duration) return value.duration;
    return position;
  }

  Future<void> _seekBy(Duration offset) =>
      controller.seekTo(_clamp(value.position + offset));

  @override
  Widget build(BuildContext context) {
    final remaining = value.duration - value.position;
    final speed = value.playbackSpeed;
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 2, 8, 8),
      child: Column(
        children: [
          VideoProgressIndicator(
            controller,
            allowScrubbing: true,
            colors: const VideoProgressColors(
              playedColor: SkillBridgeColors.accent,
              bufferedColor: Colors.white38,
              backgroundColor: Colors.white24,
            ),
          ),
          Row(
            children: [
              IconButton(
                onPressed: () => _seekBy(const Duration(seconds: -10)),
                tooltip: 'Back 10 seconds',
                icon: const Icon(Icons.replay_10_rounded, color: Colors.white),
              ),
              IconButton(
                onPressed: value.isPlaying ? controller.pause : controller.play,
                tooltip: value.isPlaying ? 'Pause' : 'Play',
                icon: Icon(
                  value.isPlaying
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              IconButton(
                onPressed: () => _seekBy(const Duration(seconds: 10)),
                tooltip: 'Forward 10 seconds',
                icon: const Icon(Icons.forward_10_rounded, color: Colors.white),
              ),
              Text(
                _formatTime(value.position),
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
              const Text(
                ' / ',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
              Text(
                _formatTime(value.duration),
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => _showVolume(context),
                tooltip: 'Volume',
                icon: Icon(
                  value.volume == 0
                      ? Icons.volume_off_rounded
                      : Icons.volume_up_rounded,
                  color: Colors.white,
                ),
              ),
              PopupMenuButton<double>(
                tooltip: 'Playback speed',
                initialValue: speed,
                onSelected: controller.setPlaybackSpeed,
                color: const Color(0xFF252735),
                itemBuilder: (_) => [
                  for (final item in [0.75, 1.0, 1.25, 1.5, 2.0])
                    PopupMenuItem(
                      value: item,
                      child: Text(
                        '${item}x',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                ],
                icon: const Icon(Icons.speed_rounded, color: Colors.white),
              ),
              if (allowFullscreen)
                IconButton(
                  onPressed: () => _openFullscreen(context),
                  tooltip: 'Fullscreen',
                  icon: const Icon(
                    Icons.fullscreen_rounded,
                    color: Colors.white,
                  ),
                ),
            ],
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${_formatTime(remaining)} remaining • HD',
              style: const TextStyle(color: Colors.white54, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _showVolume(BuildContext context) async {
    var volume = value.volume;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF191B27),
      showDragHandle: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 28),
          child: Row(
            children: [
              Icon(
                volume == 0
                    ? Icons.volume_off_rounded
                    : Icons.volume_up_rounded,
                color: SkillBridgeColors.accent,
              ),
              Expanded(
                child: Slider(
                  value: volume,
                  onChanged: (next) {
                    setSheetState(() => volume = next);
                    controller.setVolume(next);
                  },
                  min: 0,
                  max: 1,
                  divisions: 10,
                  label: '${(volume * 100).round()}%',
                ),
              ),
              Text(
                '${(volume * 100).round()}%',
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openFullscreen(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _FullscreenPlayer(controller: controller),
      ),
    );
  }
}

class _FullscreenPlayer extends StatelessWidget {
  const _FullscreenPlayer({required this.controller});

  final VideoPlayerController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close_rounded, color: Colors.white),
        ),
        title: const Text(
          'Fullscreen video',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Center(
        child: ValueListenableBuilder<VideoPlayerValue>(
          valueListenable: controller,
          builder: (context, value, _) => _VideoSurface(
            controller: controller,
            value: value,
            allowFullscreen: false,
          ),
        ),
      ),
    );
  }
}

class _LearningPathHeader extends StatelessWidget {
  const _LearningPathHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
        decoration: BoxDecoration(
          color: const Color(0xFF191B27),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFF303241)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'SECTION FOUNDATIONS',
              style: TextStyle(
                color: Color(0xFF9C9EAB),
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.4,
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              'Unit 1: Python Kickstart',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _PathNode(
                  icon: Icons.play_arrow_rounded,
                  label: 'Start',
                  active: true,
                ),
                const Expanded(child: _PathLine()),
                _PathNode(
                  icon: Icons.ondemand_video_rounded,
                  label: 'Watch',
                  active: true,
                ),
                const Expanded(child: _PathLine()),
                _PathNode(
                  icon: Icons.code_rounded,
                  label: 'Try',
                  active: false,
                ),
                const Expanded(child: _PathLine()),
                _PathNode(
                  icon: Icons.check_rounded,
                  label: 'Check',
                  active: false,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PathNode extends StatelessWidget {
  const _PathNode({
    required this.icon,
    required this.label,
    required this.active,
  });

  final IconData icon;
  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = active ? SkillBridgeColors.accent : const Color(0xFF777A89);
    return Column(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.16),
            shape: BoxShape.circle,
            border: Border.all(color: color.withValues(alpha: 0.7), width: 1.5),
          ),
          child: Icon(icon, color: color, size: 19),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _PathLine extends StatelessWidget {
  const _PathLine();

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 17),
    height: 3,
    color: const Color(0xFF3A3C4A),
  );
}

class _LoadingOrError extends StatelessWidget {
  const _LoadingOrError({
    required this.error,
    required this.onRetry,
    required this.publicId,
  });

  final Object? error;
  final VoidCallback onRetry;
  final String publicId;

  @override
  Widget build(BuildContext context) {
    final hasError = error != null;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              hasError ? Icons.cloud_off_rounded : Icons.cloud_download_rounded,
              color: hasError
                  ? const Color(0xFFFFC857)
                  : SkillBridgeColors.accent,
              size: 56,
            ),
            const SizedBox(height: 16),
            Text(
              hasError
                  ? 'We could not load this lesson'
                  : 'Preparing your lesson',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              hasError ? 'Check your connection and try again.' : 'Connecting securely to the SkillsBridg Academy video library.',
              style: const TextStyle(color: SkillBridgeColors.textMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            if (hasError)
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try again'),
              )
            else
              const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 3),
              ),
            const SizedBox(height: 18),
            Text(
              'Video: $publicId',
              style: const TextStyle(color: Color(0xFF606271), fontSize: 11),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _LessonMeta extends StatelessWidget {
  const _LessonMeta({required this.value});

  final VideoPlayerValue value;

  @override
  Widget build(BuildContext context) {
    final seconds = value.position.inSeconds;
    final minutes = seconds ~/ 60;
    final remaining = seconds % 60;
    return Row(
      children: [
        const Icon(
          Icons.play_circle_outline_rounded,
          color: SkillBridgeColors.accent,
          size: 20,
        ),
        const SizedBox(width: 8),
        Text(
          '$minutes:${remaining.toString().padLeft(2, '0')} watched',
          style: const TextStyle(color: Color(0xFFB8BAC6)),
        ),
        const Spacer(),
        const Text(
          'Cloudinary • HD',
          style: TextStyle(color: Color(0xFFB8BAC6), fontSize: 12),
        ),
      ],
    );
  }
}

class _InterwovenPractice extends StatelessWidget {
  const _InterwovenPractice();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Learn by doing',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'The practical is part of the lesson — not an extra assignment.',
          style: TextStyle(color: Color(0xFFB8BAC6), height: 1.4),
        ),
        const SizedBox(height: 14),
        _FlowCard(
          index: '01',
          icon: Icons.play_circle_outline_rounded,
          color: SkillBridgeColors.accent,
          title: 'Watch the idea',
          body: 'Follow the introduction video and pause whenever you want to try the idea yourself.',
        ),
        _FlowCard(
          index: '02',
          icon: Icons.code_rounded,
          color: const Color(0xFFFFC857),
          title: 'Try it in Code Lab',
          body: 'Write your first output with print(). Start small, run it, and see the result.',
          action: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Code Lab practice is ready for this lesson.'),
            ),
          ),
        ),
        _FlowCard(
          index: '03',
          icon: Icons.quiz_rounded,
          color: const Color(0xFFC9A7FF),
          title: 'Quick check',
          body: 'What does print() do? Choose an answer to lock in the idea.',
          action: () => _showCheck(context),
        ),
      ],
    );
  }

  void _showCheck(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF191B27),
      showDragHandle: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(22, 4, 22, 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quick check',
              style: TextStyle(
                color: Colors.white,
                fontSize: 21,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'What does print() do in Python?',
              style: TextStyle(color: Color(0xFFD5D6DE)),
            ),
            const SizedBox(height: 16),
            for (final answer in [
              'Displays a value',
              'Deletes a variable',
              'Starts a loop',
            ])
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(answer),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _FlowCard extends StatelessWidget {
  const _FlowCard({
    required this.index,
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
    this.action,
  });

  final String index;
  final IconData icon;
  final Color color;
  final String title;
  final String body;
  final VoidCallback? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF191B27),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF303241)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'STEP $index',
                    style: TextStyle(
                      color: color,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    body,
                    style: const TextStyle(
                      color: Color(0xFFB8BAC6),
                      height: 1.4,
                    ),
                  ),
                  if (action != null) ...[
                    const SizedBox(height: 11),
                    FilledButton.tonalIcon(
                      onPressed: action,
                      icon: const Icon(Icons.arrow_forward_rounded, size: 17),
                      label: const Text('Open'),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
