import 'package:shared_preferences/shared_preferences.dart';

/// Persisted, non-sensitive app preferences.
///
/// Auth tokens and secrets must NOT live here; use platform secure storage.
class SettingsRepository {
  SettingsRepository(this._prefs);

  final SharedPreferences _prefs;

  static const _kThemeMode = 'theme_mode';
  static const _kEditorFontSize = 'editor_font_size';
  static const _kTabSize = 'tab_size';
  static const _kWordWrap = 'word_wrap';
  static const _kAutoSave = 'auto_save_draft';
  static const _kLearnerRef = 'learner_ref';
  static const _kLastSync = 'last_sync_at';

  static Future<SettingsRepository> create() async =>
      SettingsRepository(await SharedPreferences.getInstance());

  String get themeMode => _prefs.getString(_kThemeMode) ?? 'system';
  Future<void> setThemeMode(String value) => _prefs.setString(_kThemeMode, value);

  double get editorFontSize => _prefs.getDouble(_kEditorFontSize) ?? 15.0;
  Future<void> setEditorFontSize(double value) => _prefs.setDouble(_kEditorFontSize, value);

  int get tabSize => _prefs.getInt(_kTabSize) ?? 4;
  Future<void> setTabSize(int value) => _prefs.setInt(_kTabSize, value);

  bool get wordWrap => _prefs.getBool(_kWordWrap) ?? false;
  Future<void> setWordWrap(bool value) => _prefs.setBool(_kWordWrap, value);

  bool get autoSaveDraft => _prefs.getBool(_kAutoSave) ?? true;
  Future<void> setAutoSaveDraft(bool value) => _prefs.setBool(_kAutoSave, value);

  /// A stable, non-identifying reference for the current learner. Assigned once
  /// and stored locally; the real identity binding happens server-side.
  String? get learnerRef => _prefs.getString(_kLearnerRef);
  Future<void> setLearnerRef(String value) => _prefs.setString(_kLearnerRef, value);

  DateTime? get lastSyncAt {
    final millis = _prefs.getInt(_kLastSync);
    return millis == null ? null : DateTime.fromMillisecondsSinceEpoch(millis);
  }

  Future<void> setLastSyncAt(DateTime value) =>
      _prefs.setInt(_kLastSync, value.millisecondsSinceEpoch);

  /// Privacy control: forget everything we stored about the local learner.
  Future<void> clearLearnerData() async {
    await _prefs.remove(_kLearnerRef);
    await _prefs.remove(_kLastSync);
  }
}
