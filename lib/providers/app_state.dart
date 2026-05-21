import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/models.dart';
import '../services/epub_service.dart';
import '../services/storage_service.dart';

class AppState extends ChangeNotifier {
  AppState() {
    _init();
  }

  final _storage = StorageService();
  final _epub = EpubService();
  final _uuid = const Uuid();

  bool _loading = true;
  bool _isDark = false;
  UserAccount? _user;
  List<BookItem> _books = [];
  List<Playlist> _playlists = [];
  ReadingStreak _streak = ReadingStreak();
  String? _authError;

  bool get loading => _loading;
  bool get isDark => _isDark;
  UserAccount? get user => _user;
  List<BookItem> get books => List.unmodifiable(_books);
  List<Playlist> get playlists => List.unmodifiable(_playlists);
  ReadingStreak get streak => _streak;
  String? get authError => _authError;
  bool get isLoggedIn => _user != null;

  Future<void> _init() async {
    _isDark = await _storage.isDarkTheme();
    final sessionId = await _storage.getSessionUserId();
    if (sessionId != null) {
      final users = await _storage.getUsers();
      _user = users.cast<UserAccount?>().firstWhere(
            (u) => u?.id == sessionId,
            orElse: () => null,
          );
      if (_user != null) {
        await _loadUserData();
      }
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> _loadUserData() async {
    if (_user == null) return;
    _books = await _storage.getBooks(_user!.id);
    _playlists = await _storage.getPlaylists(_user!.id);
    _streak = await _storage.getStreak(_user!.id);
  }

  Future<void> toggleTheme() async {
    _isDark = !_isDark;
    await _storage.setDarkTheme(_isDark);
    notifyListeners();
  }

  void clearAuthError() {
    _authError = null;
    notifyListeners();
  }

  Future<bool> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    _authError = null;
    email = email.trim().toLowerCase();
    if (email.isEmpty || password.length < 6 || displayName.trim().isEmpty) {
      _authError = 'Заполните все поля. Пароль — минимум 6 символов.';
      notifyListeners();
      return false;
    }

    final users = await _storage.getUsers();
    if (users.any((u) => u.email == email)) {
      _authError = 'Этот email уже зарегистрирован.';
      notifyListeners();
      return false;
    }

    final creds = await _storage.getCredentials();
    final newUser = UserAccount(
      id: _uuid.v4(),
      email: email,
      displayName: displayName.trim(),
      createdAt: DateTime.now(),
    );
    users.add(newUser);
    creds[email] = _storage.hashPassword(password);

    await _storage.saveUsers(users);
    await _storage.saveCredentials(creds);
    await _storage.setSessionUserId(newUser.id);

    _user = newUser;
    _books = [];
    _playlists = [];
    _streak = ReadingStreak();
    await _storage.saveBooks(_user!.id, _books);
    await _storage.savePlaylists(_user!.id, _playlists);
    await _storage.saveStreak(_user!.id, _streak);
    notifyListeners();
    return true;
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _authError = null;
    email = email.trim().toLowerCase();
    final users = await _storage.getUsers();
    final account = users.cast<UserAccount?>().firstWhere(
          (u) => u?.email == email,
          orElse: () => null,
        );
    if (account == null) {
      _authError = 'Пользователь не найден.';
      notifyListeners();
      return false;
    }

    final creds = await _storage.getCredentials();
    if (creds[email] != _storage.hashPassword(password)) {
      _authError = 'Неверный пароль.';
      notifyListeners();
      return false;
    }

    await _storage.setSessionUserId(account.id);
    _user = account;
    await _loadUserData();
    notifyListeners();
    return true;
  }

  Future<void> logout() async {
    await _storage.setSessionUserId(null);
    _user = null;
    _books = [];
    _playlists = [];
    _streak = ReadingStreak();
    notifyListeners();
  }

  Future<void> updateProfile({
    String? displayName,
    String? avatarPath,
    String? bannerPath,
  }) async {
    if (_user == null) return;
    if (displayName != null) _user!.displayName = displayName;
    if (avatarPath != null) _user!.avatarPath = avatarPath;
    if (bannerPath != null) _user!.bannerPath = bannerPath;

    final users = await _storage.getUsers();
    final idx = users.indexWhere((u) => u.id == _user!.id);
    if (idx >= 0) users[idx] = _user!;
    await _storage.saveUsers(users);
    notifyListeners();
  }

  Future<BookItem?> addBookFromPath(String filePath) async {
    if (_user == null) return null;
    try {
      final data = await _epub.loadBook(filePath);
      final book = BookItem(
        id: _uuid.v4(),
        title: data.title,
        author: data.author,
        filePath: filePath,
        addedAt: DateTime.now(),
      );
      _books.insert(0, book);
      await _storage.saveBooks(_user!.id, _books);
      notifyListeners();
      return book;
    } catch (e) {
      debugPrint('EPUB load error: $e');
      return null;
    }
  }

  Future<void> updateBookProgress(
    String bookId,
    int chapterIndex,
    double progress,
  ) async {
    if (_user == null) return;
    final idx = _books.indexWhere((b) => b.id == bookId);
    if (idx < 0) return;
    _books[idx].lastChapterIndex = chapterIndex;
    _books[idx].progress = progress.clamp(0, 1);
    await _storage.saveBooks(_user!.id, _books);
    notifyListeners();
  }

  Future<void> removeBook(String bookId) async {
    if (_user == null) return;
    _books.removeWhere((b) => b.id == bookId);
    for (final p in _playlists) {
      p.bookIds.remove(bookId);
    }
    await _storage.saveBooks(_user!.id, _books);
    await _storage.savePlaylists(_user!.id, _playlists);
    notifyListeners();
  }

  Future<Playlist> createPlaylist(String name, {String emoji = '📚'}) async {
    final playlist = Playlist(
      id: _uuid.v4(),
      name: name,
      emoji: emoji,
      bookIds: [],
      createdAt: DateTime.now(),
    );
    _playlists.add(playlist);
    if (_user != null) {
      await _storage.savePlaylists(_user!.id, _playlists);
    }
    notifyListeners();
    return playlist;
  }

  Future<void> renamePlaylist(String id, String name) async {
    final p = _playlists.firstWhere((x) => x.id == id);
    p.name = name;
    if (_user != null) {
      await _storage.savePlaylists(_user!.id, _playlists);
    }
    notifyListeners();
  }

  Future<void> deletePlaylist(String id) async {
    _playlists.removeWhere((p) => p.id == id);
    if (_user != null) {
      await _storage.savePlaylists(_user!.id, _playlists);
    }
    notifyListeners();
  }

  Future<void> toggleBookInPlaylist(String playlistId, String bookId) async {
    final p = _playlists.firstWhere((x) => x.id == playlistId);
    if (p.bookIds.contains(bookId)) {
      p.bookIds.remove(bookId);
    } else {
      p.bookIds.add(bookId);
    }
    if (_user != null) {
      await _storage.savePlaylists(_user!.id, _playlists);
    }
    notifyListeners();
  }

  Future<void> recordReadingSession({int minutes = 5}) async {
    if (_user == null) return;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (_streak.lastReadDate != null) {
      final last = DateTime(
        _streak.lastReadDate!.year,
        _streak.lastReadDate!.month,
        _streak.lastReadDate!.day,
      );
      final diff = today.difference(last).inDays;
      if (diff == 0) {
        _streak.todayMinutes += minutes;
      } else if (diff == 1) {
        _streak.currentStreak += 1;
        _streak.todayMinutes = minutes;
      } else {
        _streak.currentStreak = 1;
        _streak.todayMinutes = minutes;
      }
    } else {
      _streak.currentStreak = 1;
      _streak.todayMinutes = minutes;
    }

    _streak.lastReadDate = now;
    if (_streak.currentStreak > _streak.longestStreak) {
      _streak.longestStreak = _streak.currentStreak;
    }

    await _storage.saveStreak(_user!.id, _streak);
    notifyListeners();
  }

  BookItem? bookById(String id) {
    try {
      return _books.firstWhere((b) => b.id == id);
    } catch (_) {
      return null;
    }
  }

  EpubService get epubService => _epub;
}
