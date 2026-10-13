import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:skillbridge_python_lab/app/app.dart';
import 'package:skillbridge_python_lab/core/di/app_dependencies.dart';
import 'package:skillbridge_python_lab/features/editor/widgets/output_console.dart';
import 'package:skillbridge_python_lab/features/home/connectivity_controller.dart';
import 'package:skillbridge_python_lab/features/python_runtime/fake_python_runtime.dart';
import 'package:skillbridge_python_lab/features/settings/settings_controller.dart';
import 'package:skillbridge_python_lab/features/submissions/submission.dart';

import 'support/test_dependencies.dart';

/// Builds an in-memory dependency graph so the real UI can be exercised
/// without a device, a network, or an interpreter.
///
/// Delegates to [buildTestDependencies]; see `support/test_dependencies.dart`.
Future<AppDependencies> createTestDependencies({
  bool online = true,
  FakePythonRuntime? runtime,
}) {
  return buildTestDependencies(
    runtime: runtime ?? FakePythonRuntime(),
    online: online,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDependencies deps;

  setUp(() async {
    deps = await createTestDependencies();
  });

  tearDown(() async {
    await deps.dispose();
  });

  /// Advances fake time far enough for microtasks, futures and the 300ms route
  /// animation to finish, without relying on [WidgetTester.pumpAndSettle]
  /// (which would hang forever on an indeterminate progress indicator).
  Future<void> pumpFrames(WidgetTester tester, {int count = 10}) async {
    for (var i = 0; i < count; i++) {
      await tester
          .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
      await tester.pump(const Duration(milliseconds: 60));
    }
  }

  /// Runs [body] on the real event loop and returns its result.
  ///
  /// `testWidgets` runs its body in a fake-async zone where timers only fire
  /// when the fake clock is advanced. SQLite's FFI path schedules a real
  /// timer, so awaiting the database directly from the test body would hang
  /// forever. Any assertion that reads the database must go through here.
  Future<T> real<T>(WidgetTester tester, Future<T> Function() body) async {
    final value = await tester.runAsync(body);
    return value as T;
  }

  /// Rebuilds the dependency graph, e.g. to simulate being offline.
  Future<void> rebuildDeps(WidgetTester tester, {required bool online}) =>
      real(tester, () async {
        await deps.dispose();
        deps = await createTestDependencies(online: online);
      });

  /// Scrolls [target] into view.
  ///
  /// `ListView` builds its children lazily, so a button near the bottom of a
  /// long screen does not exist yet and cannot be tapped. This drags the first
  /// scrollable until the finder matches.
  Future<void> scrollTo(
    WidgetTester tester,
    Finder target, {
    int maxDrags = 12,
    double extent = 300,
  }) async {
    final scrollable = find.byType(Scrollable).first;
    for (var i = 0; i < maxDrags && target.evaluate().isEmpty; i++) {
      await tester.drag(scrollable, Offset(0, -extent));
      await pumpFrames(tester, count: 2);
    }
    expect(target, findsOneWidget,
        reason: 'never became visible after $maxDrags drags');
  }

  /// Opens the exercise details screen and gets all the way into the editor.
  ///
  /// Exercises now carry a lesson, so the primary button reads "Start with a
  /// quick lesson" and tapping it opens the lesson rather than the editor. This
  /// taps through the lesson's CONTINUE until the editor appears, which
  /// exercises the real lesson -> editor chain instead of routing around it.
  Future<void> openEditor(WidgetTester tester, {required String exerciseTitle}) async {
    await tester.tap(find.text(exerciseTitle));
    await pumpFrames(tester);

    // Match the primary button itself, not any text containing "Start": the
    // details screen also has a "Starter code" heading, which makes a
    // textContaining finder resolve early and send the tap into a Text.
    // The predicate is evaluated on every scroll step, so it works while the
    // list is still lazily building and neither label exists yet.
    Finder startButton() => find.byWidgetPredicate(
          (w) =>
              w is FilledButton &&
              find
                  .descendant(
                    of: find.byWidget(w),
                    matching: find.textContaining('Start'),
                  )
                  .evaluate()
                  .isNotEmpty,
          description: 'the details screen primary button',
        );

    await scrollTo(tester, startButton());
    await tester.tap(startButton());
    await pumpFrames(tester);

    // Cap the taps so a broken lesson fails with a clear message rather than
    // looping until the test times out.
    for (var i = 0; i < 12 && find.text('Run').evaluate().isEmpty; i++) {
      final cont = find.text('CONTINUE');
      final start = find.text('Start the challenge');
      final button = cont.evaluate().isNotEmpty ? cont : start;
      if (button.evaluate().isEmpty) break;
      await tester.tap(button);
      await pumpFrames(tester);
    }
    expect(find.text('Run'), findsOneWidget,
        reason: 'the lesson never handed off to the editor');
  }

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
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
      ),
    );
    await pumpFrames(tester);
  }

  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 30));
  }

  group('home screen', () {
    testWidgets('shows branding, status and the downloaded exercises',
        (tester) async {
      await pumpApp(tester);

      expect(find.text('Python Lab'), findsOneWidget);
      expect(find.text('Practice challenges'), findsOneWidget);
      expect(find.text('Hello, World!'), findsOneWidget);
      // `SliverList` is lazy, so only the count can prove every exercise
      // arrived, not a lookup of a tile that may not be built yet.
      expect(find.text('8 available'), findsOneWidget);
      expect(find.text('Connected'), findsOneWidget);
      expect(find.text('Your progress'), findsOneWidget);

      await unmount(tester);
    });

    testWidgets('indicates offline mode when there is no connection',
        (tester) async {
      await rebuildDeps(tester, online: false);
      await pumpApp(tester);

      expect(find.text('Offline mode · your work is saved on this device'),
          findsOneWidget);
      expect(find.text('Connected'), findsNothing);

      await unmount(tester);
    });

    testWidgets('bottom navigation switches between the three tabs',
        (tester) async {
      await pumpApp(tester);

      expect(find.text('Progress'), findsOneWidget);
      await tester.tap(find.text('Progress'));
      await pumpFrames(tester);
      expect(find.text('verified SkillCoins'), findsOneWidget);

      await tester.tap(find.text('Settings'));
      await pumpFrames(tester);
      // `_SectionHeader` renders its title upper-cased for visual style, so
      // these are matched as they are drawn, not as they are written.
      expect(find.text('APPEARANCE'), findsOneWidget);
      expect(find.text('OFFLINE STORAGE'), findsOneWidget);

      await unmount(tester);
    });
  });

  group('settings', () {
    testWidgets('changing the theme updates the controller', (tester) async {
      await pumpApp(tester);

      await tester.tap(find.text('Settings'));
      await pumpFrames(tester);

      final settings = contextOf<SettingsController>(tester);
      expect(settings.themeMode, ThemeMode.system);

      await tester.tap(find.text('Dark'));
      await pumpFrames(tester);

      expect(settings.themeMode, ThemeMode.dark);

      await unmount(tester);
    });

    testWidgets('reports local storage usage', (tester) async {
      await pumpApp(tester);

      await tester.tap(find.text('Settings'));
      await pumpFrames(tester);

      expect(find.textContaining('drafts stored'), findsOneWidget);
      expect(find.textContaining('submissions on this device'), findsOneWidget);

      await unmount(tester);
    });
  });

  group('exercise details', () {
    testWidgets('shows objectives, requirements and the hint progression',
        (tester) async {
      await pumpApp(tester);

      await tester.tap(find.text('Hello, World!'));
      await pumpFrames(tester);

      expect(find.text('Instructions'), findsOneWidget);
      expect(find.text('What you will learn'), findsOneWidget);
      expect(find.text('Use the print() function'), findsOneWidget);
      expect(find.text('Requirements'), findsOneWidget);
      expect(find.text('Starter code'), findsOneWidget);
      expect(find.text('Show hint 1 of 1'), findsOneWidget);

      await tester.tap(find.text('Show hint 1 of 1'));
      await pumpFrames(tester);
      expect(find.text("Text must be in quotes: print('Hello, World!')"),
          findsOneWidget);

      await unmount(tester);
    });
  });

  group('editor', () {
    testWidgets('runs code and shows the structured result in the console',
        (tester) async {
      await pumpApp(tester);

      await openEditor(tester, exerciseTitle: 'Hello, World!');

      expect(find.text('Run'), findsOneWidget);
      expect(find.text('Tap Run to see the output here.'), findsOneWidget);

      await tester.tap(find.text('Run'));
      await pumpFrames(tester);

      expect(find.text('Finished successfully'), findsOneWidget);
      final console = tester.widget<SelectableText>(
        find.descendant(
          of: find.byType(OutputConsole),
          matching: find.byType(SelectableText),
        ),
      );
      expect(console.data, contains('Hello from the fake runtime'));
      expect(find.text('Run'), findsOneWidget);

      await unmount(tester);
    });

    testWidgets('submitting stores a durable submission before any network call',
        (tester) async {
      await pumpApp(tester);

      await openEditor(tester, exerciseTitle: 'Hello, World!');

      final pendingBefore = await real(
          tester, () => deps.submissions.pendingCount(deps.learnerRef));
      expect(pendingBefore, 0);

      await tester.tap(find.text('Submit'));
      await pumpFrames(tester);

      final stored =
          await real(tester, () => deps.submissions.listForLearner(deps.learnerRef));
      expect(stored, hasLength(1));
      expect(stored.first.syncState, SubmissionSyncState.accepted);
      expect(stored.first.serverResponseRef, isNotNull);
      final pendingAfter = await real(
          tester, () => deps.submissions.pendingCount(deps.learnerRef));
      expect(pendingAfter, 0);

      await unmount(tester);
    });

    testWidgets('an offline submit is queued locally and kept',
        (tester) async {
      await rebuildDeps(tester, online: false);
      await pumpApp(tester);

      await openEditor(tester, exerciseTitle: 'Hello, World!');

      await tester.tap(find.text('Submit'));
      await pumpFrames(tester);

      final stored =
          await real(tester, () => deps.submissions.listForLearner(deps.learnerRef));
      expect(stored, hasLength(1));
      expect(stored.first.syncState, SubmissionSyncState.pending);
      final pending = await real(
          tester, () => deps.submissions.pendingCount(deps.learnerRef));
      expect(pending, 1);
      expect(find.textContaining('Saved offline'), findsOneWidget);

      await unmount(tester);
    });
  });

  group('drafts', () {
    testWidgets('code typed in the editor is persisted as a draft',
        (tester) async {
      await pumpApp(tester);

      await openEditor(tester, exerciseTitle: 'Hello, World!');

      await tester.tap(find.byTooltip('Save draft'));
      await pumpFrames(tester);

      final draft = await real(
          tester, () => deps.drafts.find(deps.learnerRef, 'ex-hello-world'));
      expect(draft, isNotNull);
      expect(draft!.code, isNotEmpty);

      await unmount(tester);
    });
  });
}

/// Reads a provided [ChangeNotifier] from the widget tree.
T contextOf<T extends ChangeNotifier>(WidgetTester tester) {
  final scope = tester.element(find.byType(SkillBridgeApp));
  return scope.read<T>();
}
