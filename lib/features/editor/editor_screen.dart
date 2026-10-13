import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:skillbridge_python_lab/core/di/app_dependencies.dart';
import 'package:skillbridge_python_lab/features/home/connectivity_controller.dart';
import 'package:skillbridge_python_lab/features/settings/settings_controller.dart';
import 'package:skillbridge_python_lab/features/editor/editor_controller.dart';
import 'package:skillbridge_python_lab/features/exercises/exercise.dart';

import 'widgets/code_editing_controller.dart';
import 'widgets/code_editor.dart';
import 'widgets/output_console.dart';
import 'widgets/shortcut_bar.dart';

/// Screen B + C + E: the Python editor, shortcut bar and output console.
class EditorScreen extends StatefulWidget {
  const EditorScreen({super.key, required this.exercise});

  final Exercise exercise;

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  late final AppDependencies _deps;
  late final EditorController _editor;
  late final CodeEditingController _codeController;
  late final FocusNode _focusNode;

  bool _initialising = true;
  bool _showInstructions = true;
  String? _initialiseError;

  @override
  void initState() {
    super.initState();
    _deps = context.read<AppDependencies>();
    _editor = EditorController(deps: _deps, exercise: widget.exercise);
    _codeController = CodeEditingController();
    _focusNode = FocusNode();
    _codeController.addListener(_onCodeChanged);
    _editor.addListener(_onEditorChanged);
    _initialise();
  }

  Future<void> _initialise() async {
    if (mounted) {
      setState(() {
        _initialising = true;
        _initialiseError = null;
      });
    }
    try {
      await _deps.runtime.prepare();
      await _editor.load();
      _codeController.text = _editor.code;
      _codeController.selection = TextSelection.collapsed(
        offset: _editor.code.length,
      );
    } catch (_) {
      _codeController.text = widget.exercise.starterCode;
      _codeController.selection = TextSelection.collapsed(
        offset: _codeController.text.length,
      );
      _initialiseError = 'The Python runner is taking a break. You can still edit your code and try again.';
    } finally {
      _initialising = false;
      if (mounted) setState(() {});
    }
  }

  void _onCodeChanged() {
    if (_initialising) return;
    _editor.updateCode(_codeController.text);
  }

  void _onEditorChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _codeController.removeListener(_onCodeChanged);
    _editor.removeListener(_onEditorChanged);
    _editor.dispose();
    _codeController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _run() async {
    if (_initialising || _editor.isRunning || _editor.isSubmitting) return;
    FocusScope.of(context).unfocus();
    setState(() => _showInstructions = false);
    if (widget.exercise.id == 'ex-input' && _editor.stdinText.isEmpty) {
      await _promptForInput();
    }
    if (!mounted) return;
    try {
      await _editor.run();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'The program could not start. Check your code and try again.',
          ),
        ),
      );
    }
  }

  Future<void> _promptForInput() async {
    final controller = TextEditingController(text: _editor.stdinText);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Program input'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('This exercise uses input(). Type one answer per line.'),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 4,
              autofocus: true,
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(88, 48)),
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('Use'),
          ),
        ],
      ),
    );
    if (result != null) {
      _editor.setStdinText(result);
    }
  }

  Future<void> _submit() async {
    if (_initialising || _editor.isRunning || _editor.isSubmitting) return;
    try {
      await _editor.submit();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Your work is safe. We could not submit it yet — please try again.',
          ),
        ),
      );
      return;
    }
    if (!mounted) return;
    context.read<ConnectivityController>().refreshPendingCount();
    _showSubmitFeedback();
  }

  void _showSubmitFeedback() {
    final messenger = ScaffoldMessenger.of(context);
    final message = _editor.submitMessage ?? 'Submission saved.';
    Color background;
    IconData icon;
    switch (_editor.lastSubmitOutcome) {
      case SubmitOutcome.accepted:
        background = const Color(0xFF2E7D32);
        icon = Icons.verified;
      case SubmitOutcome.rejected:
        background = const Color(0xFFB71C1C);
        icon = Icons.refresh;
      case SubmitOutcome.queuedOffline:
        background = const Color(0xFF5D4037);
        icon = Icons.cloud_off;
      case SubmitOutcome.authExpired:
      case SubmitOutcome.failed:
      case null:
        background = const Color(0xFF37474F);
        icon = Icons.error_outline;
    }
    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: background,
      ),
    );
  }

  Future<void> _saveDraft() async {
    if (_initialising) return;
    try {
      await _editor.saveDraft();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'We could not save the draft, but your code is still on screen.',
          ),
        ),
      );
      return;
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Draft saved on this device.')),
    );
  }

  Future<void> _reset() async {
    if (_initialising || _editor.isRunning || _editor.isSubmitting) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset code?'),
        content: const Text(
          'This replaces your code with the starter code. Your saved draft will be overwritten.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(88, 48)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _editor.resetToStarter();
      _codeController.text = _editor.code;
      _codeController.selection = TextSelection.collapsed(
        offset: _editor.code.length,
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'The starter code could not be restored. Your current code is still safe.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final online = context.watch<ConnectivityController>().isOnline;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.exercise.title, style: const TextStyle(fontSize: 17)),
            if (!online)
              const Text(
                'Offline — your work is saved locally',
                style: TextStyle(fontSize: 11, color: Color(0xFFFFE0A3)),
              ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Exercise details',
            icon: const Icon(Icons.info_outline),
            onPressed: () =>
                setState(() => _showInstructions = !_showInstructions),
          ),
          IconButton(
            tooltip: 'Save draft',
            icon: Icon(
              _editor.hasUnsavedChanges ? Icons.save : Icons.save_outlined,
            ),
            onPressed: _initialising ? null : _saveDraft,
          ),
          IconButton(
            tooltip: 'Reset code',
            icon: const Icon(Icons.restart_alt),
            onPressed:
                _initialising || _editor.isRunning || _editor.isSubmitting
                ? null
                : _reset,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (_showInstructions) _InstructionsCard(exercise: widget.exercise),
            if (_initialiseError != null)
              _RuntimeWarning(message: _initialiseError!, onRetry: _initialise),
            Expanded(
              flex: 3,
              child: _initialising
                  ? const Center(child: CircularProgressIndicator())
                  : CodeEditor(
                      controller: _codeController,
                      focusNode: _focusNode,
                      fontSize: context
                          .watch<SettingsController>()
                          .editorFontSize,
                      indentUnit: context
                          .watch<SettingsController>()
                          .indentUnit,
                    ),
            ),
            SizedBox(
              height: 160,
              child: OutputConsole(
                result: _editor.result,
                isRunning: _editor.isRunning,
              ),
            ),
            ShortcutBar(controller: _codeController, focusNode: _focusNode),
            _ActionBar(
              isRunning: _editor.isRunning,
              isSubmitting: _editor.isSubmitting,
              onRun: _run,
              onStop: _editor.stop,
              onSubmit: _submit,
            ),
          ],
        ),
      ),
      backgroundColor: theme.colorScheme.surface,
    );
  }
}

class _RuntimeWarning extends StatelessWidget {
  const _RuntimeWarning({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF3A2B16),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF8A6728)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Color(0xFFFFD180)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Color(0xFFFFE6B0)),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('TRY AGAIN')),
        ],
      ),
    );
  }
}

class _InstructionsCard extends StatelessWidget {
  const _InstructionsCard({required this.exercise});

  final Exercise exercise;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      color: theme.colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(exercise.instructions, style: theme.textTheme.bodyMedium),
          if (exercise.requirements.isNotEmpty) ...[
            const SizedBox(height: 8),
            for (final requirement in exercise.requirements)
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check_box_outlined, size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        requirement,
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.isRunning,
    required this.isSubmitting,
    required this.onRun,
    required this.onStop,
    required this.onSubmit,
  });

  final bool isRunning;
  final bool isSubmitting;
  final VoidCallback onRun;
  final VoidCallback onStop;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
        child: Row(
          children: [
            Expanded(
              child: isRunning
                  ? FilledButton.icon(
                      onPressed: onStop,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFB71C1C),
                      ),
                      icon: const Icon(Icons.stop),
                      label: const Text('Stop'),
                    )
                  : FilledButton.icon(
                      onPressed: onRun,
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Run'),
                    ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: isSubmitting ? null : onSubmit,
                icon: isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.cloud_upload_outlined),
                label: const Text('Submit'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
