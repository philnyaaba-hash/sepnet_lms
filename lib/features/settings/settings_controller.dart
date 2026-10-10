import 'package:flutter/material.dart';

import 'package:skillbridge_python_lab/core/storage/settings_repository.dart';

/// App-level preferences (theme, editor sizing) backed by [SettingsRepository].
class SettingsController extends ChangeNotifier {
  SettingsController(this._repository)
      : _themeMode = _parseThemeMode(_repository.themeMode),
        _editorFontSize = _repository.editorFontSize,
        _tabSize = _repository.tabSize,
        _wordWrap = _repository.wordWrap,
        _autoSaveDraft = _repository.autoSaveDraft;

  final SettingsRepository _repository;

  ThemeMode _themeMode;
  double _editorFontSize;
  int _tabSize;
  bool _wordWrap;
  bool _autoSaveDraft;

  ThemeMode get themeMode => _themeMode;
  double get editorFontSize => _editorFontSize;
  int get tabSize => _tabSize;
  bool get wordWrap => _wordWrap;
  bool get autoSaveDraft => _autoSaveDraft;

  static ThemeMode _parseThemeMode(String value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  static String _themeModeName(ThemeMode mode) => mode.name;

  Future<void> setThemeMode(ThemeMode mode) async {
    if (mode == _themeMode) return;
    _themeMode = mode;
    notifyListeners();
    await _repository.setThemeMode(_themeModeName(mode));
  }

  Future<void> setEditorFontSize(double size) async {
    final clamped = size.clamp(10.0, 28.0);
    if (clamped == _editorFontSize) return;
    _editorFontSize = clamped;
    notifyListeners();
    await _repository.setEditorFontSize(clamped);
  }

  Future<void> setTabSize(int size) async {
    if (size == _tabSize) return;
    _tabSize = size;
    notifyListeners();
    await _repository.setTabSize(size);
  }

  Future<void> setWordWrap(bool value) async {
    if (value == _wordWrap) return;
    _wordWrap = value;
    notifyListeners();
    await _repository.setWordWrap(value);
  }

  Future<void> setAutoSaveDraft(bool value) async {
    if (value == _autoSaveDraft) return;
    _autoSaveDraft = value;
    notifyListeners();
    await _repository.setAutoSaveDraft(value);
  }

  /// Number of spaces inserted by the indentation shortcut.
  String get indentUnit => ' ' * _tabSize;
}
