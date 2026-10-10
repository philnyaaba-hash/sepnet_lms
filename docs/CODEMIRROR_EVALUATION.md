# CodeMirror 6 evaluation

The task asked us to evaluate **CodeMirror 6 in a WebView** for the code editor
and to document the trade-off. This records that evaluation and the decision.

## What was evaluated

CodeMirror 6 is the current generation of CodeMirror: a modular, purely
JavaScript editor core with first-class support for many languages, packaged as
a set of ES modules. The realistic integration path for Flutter is a
`webview_flutter`/`flutter_inappwebview` container hosting a bundled HTML page
that loads CodeMirror from local assets (no network), with a JS↔Dart bridge for
document content, cursor position, and language diagnostics.

A scaffolded asset exists at `assets/editor/codemirror_index.html` in this
repo, and the decision below can be revisited without restructuring the app,
because `CodeEditor` is a leaf widget behind `CodeEditingController`.

## Scorecard

| Criterion (weight) | CodeMirror 6 in a WebView | Native `TextField` + custom widgets | Winner |
| --- | --- | --- | --- |
| Editing experience & syntax intelligence (high) | Excellent: real parsing, error markers, autocomplete, multi-cursor, folding | Basic: highlighting and line numbers; no diagnostics, no autocomplete | **CodeMirror** |
| Offline reliability (high) | Good *if* all assets are bundled and the WebView is warm; a cold WebView start on a low-end device can take seconds | Instant; no separate process | Native |
| Testability in CI (high) | Poor. WebView tests need a device/emulator or a heavy integration harness; nothing runs under `flutter test` on a laptop | Excellent. Entire editor is unit-testable; `test/python_input_formatter_test.dart` runs in milliseconds | **Native** |
| Memory on a low-end phone (high) | A WebView instance is typically 80–150 MB resident | A few MB | **Native** |
| Behaviour parity with the runtime (medium) | A second grammar for Python that can disagree with the interpreter we ship | Our tokenizer is deliberately forgiving and never rejects valid input | **Native** (for correctness of *feedback*) |
| Bundle size (medium) | +2–4 MB of JS plus a WebView shell | ~0 | **Native** |
| Accessibility (medium) | WebView accessibility is unreliable across Android versions; screen-reader support for a code editor is poor | Real Flutter semantics; text scales with system font size, works with TalkBack | **Native** |
| Keyboard & IME behaviour (medium) | WebView soft-keyboard handling varies by OEM; scroll/focus bugs are common on cheap Android devices | Predictable Flutter behaviour | **Native** |
| Offline *first run* (medium) | Must load and parse a bundle before the editor is usable | Usable on the first frame | **Native** |
| Long-term maintenance (low) | Two languages, a bridge protocol, and a WebView to keep in sync with Flutter releases | One language, standard Flutter | **Native** |

## Decision

**Ship the native editor.** Keep `assets/editor/codemirror_index.html` and this
document as the recorded alternative.

The deciding factors were the three high-weight ones:

1. **Testability.** The brief requires that nothing is claimed to work unless it
   is implemented and tested. A WebView editor cannot be meaningfully covered by
   `flutter test` on a laptop, which would have forced us either to skip editor
   tests or to write slow, flaky device tests. The native editor is covered by
   fast unit tests that have already caught real bugs (see below).
2. **Memory and first-run latency** on the target hardware. A 100 MB WebView
   resident set is a serious cost on the low-end Android phones this app is for,
   and a cold WebView start in front of the editor directly undermines
   "practice anywhere".
3. **Accessibility for minors.** TalkBack support and system font scaling work
   through normal Flutter widgets. A WebView code editor does not.

The one thing we gave up — real syntax *diagnostics* — matters less than it
looks: the authoritative feedback comes from **running the code**, which this
app does for real. A highlighter cannot tell a learner that their loop is wrong;
the interpreter can.

## What the native editor does today

| Feature | Implementation | Tested by |
| --- | --- | --- |
| Syntax highlighting (keywords, builtins, strings, numbers, comments, operators) | `PythonSyntaxHighlighter` tokenizer | `test/python_highlighter_test.dart` — invariant: highlighted spans concatenate back to the exact source text |
| Line numbers, monospace, dark terminal palette | `CodeEditor` | Widget tests |
| Auto-close brackets and quotes | `PythonInputFormatter` | `test/python_input_formatter_test.dart` |
| Skip over an auto-inserted closing quote | Same | Same |
| Wrap a selection in brackets/quotes | Same | Same |
| Auto-indent, one extra level after `:` | Same | Same |
| Indent / dedent / newline / bracket / quote shortcuts | `ShortcutBar` | — |
| Undo/redo, selection, clipboard | Flutter's built-in editing support | — |

Tests for the formatter already paid for themselves: they caught a **crash**
(`String.lastIndexOf` with a negative start index when Enter is pressed at
position 0, which is exactly what a learner does first on an empty file) and an
**unreachable branch** in the "skip over closing quote" logic that the code
claimed to implement but never could.

## When to revisit

Revisit if all of the following become true:

* We need error underlines, autocomplete, or multi-cursor editing.
* Target devices have headroom (the memory cost stops being decisive).
* A WebView-based test harness exists in CI so the editor can still be tested.

If that happens, the migration is contained: keep `CodeEditingController` and
the `PythonInputFormatter` behaviour, replace only the rendering layer behind
`CodeEditor`, and add a bridge adapter that talks to the WebView instead of to a
Flutter `TextEditingController`.
