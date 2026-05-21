import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';
import '../models/reader_settings.dart';

class StorageService {
  static const _usersKey = 'bs_users';
  static const _sessionKey = 'bs_session_user_id';
  static const _themeKey = 'bs_theme_dark';
  static const _booksPrefix = 'bs_books_';
  static const _playlistsPrefix = 'bs_playlists_';
  static const _streakPrefix = 'bs_streak_';
  static const _readerSettingsPrefix = 'bs_reader_';

  Future<SharedPreferences> get _prefs async => SharedPreferences.getInstance();

  String hashPassword(String password) {
    return sha256.convert(utf8.encode(password)).toString();
  }

  Future<List<UserAccount>> getUsers() async {
    final prefs = await _prefs;
    final raw = prefs.getString(_usersKey);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list
        .map((e) => UserAccount.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveUsers(List<UserAccount> users) async {
    final prefs = await _prefs;
    await prefs.setString(
      _usersKey,
      jsonEncode(users.map((u) => u.toJson()).toList()),
    );
  }

  Future<Map<String, String>> getCredentials() async {
    final prefs = await _prefs;
    final raw = prefs.getString('bs_credentials');
    if (raw == null) return {};
    return Map<String, String>.from(jsonDecode(raw) as Map);
  }

  Future<void> saveCredentials(Map<String, String> creds) async {
    final prefs = await _prefs;
    await prefs.setString('bs_credentials', jsonEncode(creds));
  }

  Future<String?> getSessionUserId() async {
    final prefs = await _prefs;
    return prefs.getString(_sessionKey);
  }

  Future<void> setSessionUserId(String? userId) async {
    final prefs = await _prefs;
    if (userId == null) {
      await prefs.remove(_sessionKey);
    } else {
      await prefs.setString(_sessionKey, userId);
    }
  }

  Future<bool> isDarkTheme() async {
    final prefs = await _prefs;
    return prefs.getBool(_themeKey) ?? false;
  }

  Future<void> setDarkTheme(bool dark) async {
    final prefs = await _prefs;
    await prefs.setBool(_themeKey, dark);
  }

  Future<List<BookItem>> getBooks(String userId) async {
    final prefs = await _prefs;
    final raw = prefs.getString('$_booksPrefix$userId');
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list
        .map((e) => BookItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveBooks(String userId, List<BookItem> books) async {
    final prefs = await _prefs;
    await prefs.setString(
      '$_booksPrefix$userId',
      jsonEncode(books.map((b) => b.toJson()).toList()),
    );
  }

  Future<List<Playlist>> getPlaylists(String userId) async {
    final prefs = await _prefs;
    final raw = prefs.getString('$_playlistsPrefix$userId');
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list
        .map((e) => Playlist.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> savePlaylists(String userId, List<Playlist> playlists) async {
    final prefs = await _prefs;
    await prefs.setString(
      '$_playlistsPrefix$userId',
      jsonEncode(playlists.map((p) => p.toJson()).toList()),
    );
  }

  Future<ReadingStreak> getStreak(String userId) async {
    final prefs = await _prefs;
    final raw = prefs.getString('$_streakPrefix$userId');
    if (raw == null) return ReadingStreak();
    return ReadingStreak.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> saveStreak(String userId, ReadingStreak streak) async {
    final prefs = await _prefs;
    await prefs.setString(
      '$_streakPrefix$userId',
      jsonEncode(streak.toJson()),
    );
  }

  Future<ReaderSettings> getReaderSettings(String userId) async {
    final prefs = await _prefs;
    final raw = prefs.getString('$_readerSettingsPrefix$userId');
    if (raw == null) return ReaderSettings();
    return ReaderSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> saveReaderSettings(String userId, ReaderSettings settings) async {
    final prefs = await _prefs;
    await prefs.setString(
      '$_readerSettingsPrefix$userId',
      jsonEncode(settings.toJson()),
    );
  }
}
