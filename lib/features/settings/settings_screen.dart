import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:skillbridge_python_lab/core/di/app_dependencies.dart';
import 'settings_controller.dart';

/// Screen F: Settings — theme, editor preferences, offline storage info,
/// app version and privacy controls.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int _draftCount = 0;
  int _submissionCount = 0;
  int _pendingCount = 0;
  bool _loaded = false;

  /// Keep in sync with `version:` in pubspec.yaml.
  static const String appVersion = '1.0.0';

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final deps = context.read<AppDependencies>();
    try {
      final drafts = await deps.drafts.listFor(deps.learnerRef, limit: 1000);
      final submissions =
          await deps.submissions.listForLearner(deps.learnerRef, limit: 1000);
      final pending = await deps.submissions.pendingCount(deps.learnerRef);
      if (mounted) {
        setState(() {
          _draftCount = drafts.length;
          _submissionCount = submissions.length;
          _pendingCount = pending;
          _loaded = true;
        });
      }
    } catch (_) {
      // A storage failure must not surface as an unhandled async error from
      // initState; show the section (with zeroed counts) instead of spinning.
      if (mounted) setState(() => _loaded = true);
    }
  }

  Future<void> _clearLocalData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear local data?'),
        content: const Text(
          'This removes drafts and submission history stored on this device. '
          'Submissions already accepted by the LMS are not affected.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Clear')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final deps = context.read<AppDependencies>();
    await deps.drafts.deleteAllFor(deps.learnerRef);
    await deps.submissions.deleteAllFor(deps.learnerRef);
    await deps.settings.clearLearnerData();
    await _loadStats();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Local data cleared.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const _SectionHeader('Appearance'),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(
                  value: ThemeMode.system,
                  label: Text('System'),
                  icon: Icon(Icons.brightness_auto),
                ),
                ButtonSegment(
                  value: ThemeMode.light,
                  label: Text('Light'),
                  icon: Icon(Icons.light_mode),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  label: Text('Dark'),
                  icon: Icon(Icons.dark_mode),
                ),
              ],
              selected: {settings.themeMode},
              onSelectionChanged: (selection) => settings.setThemeMode(selection.first),
            ),
          ),
          const _SectionHeader('Editor'),
          ListTile(
            title: const Text('Font size'),
            subtitle: Slider(
              value: settings.editorFontSize,
              min: 12,
              max: 24,
              divisions: 12,
              label: settings.editorFontSize.round().toString(),
              onChanged: settings.setEditorFontSize,
            ),
            trailing: Text('${settings.editorFontSize.round()}'),
          ),
          ListTile(
            title: const Text('Indentation width'),
            subtitle: const Text('Spaces inserted by the indent button'),
            trailing: DropdownButton<int>(
              value: settings.tabSize,
              onChanged: (v) => settings.setTabSize(v!),
              items: const [
                DropdownMenuItem(value: 2, child: Text('2')),
                DropdownMenuItem(value: 4, child: Text('4')),
                DropdownMenuItem(value: 8, child: Text('8')),
              ],
            ),
          ),
          SwitchListTile(
            title: const Text('Save drafts automatically'),
            subtitle: const Text('Autosave your code while you type'),
            value: settings.autoSaveDraft,
            onChanged: settings.setAutoSaveDraft,
          ),
          const _SectionHeader('Offline storage'),
          if (!_loaded)
            const ListTile(title: Text('Calculating…'), trailing: CircularProgressIndicator())
          else
            ListTile(
              leading: const Icon(Icons.storage_outlined),
              title: Text('$_draftCount drafts stored'),
              subtitle: Text('$_submissionCount submissions on this device '
                  '($_pendingCount waiting to sync)'),
            ),
          const _SectionHeader('Privacy & safety'),
          const ListTile(
            leading: Icon(Icons.lock_outline),
            title: Text('How your data is handled'),
            subtitle: Text(
              'Your code is stored on this device. It is only sent to the SkillBridge LMS '
              'when you tap Submit. We do not collect phone numbers or run advertising.',
            ),
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline),
            title: const Text('Clear local data'),
            subtitle: const Text('Remove drafts and submission history from this device'),
            onTap: _clearLocalData,
          ),
          const _SectionHeader('About'),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('SkillBridge Python Lab'),
            subtitle: Text('Version $appVersion • Offline-first Python practice'),
          ),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Python programs run on your device. Local execution is sandboxed by the '
              'operating system but is not a certified security boundary; only submit code '
              'you are comfortable sharing with your academy.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);
  final String title;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
        child: Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      );
}
