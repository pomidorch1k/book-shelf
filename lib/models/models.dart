class UserAccount {
  UserAccount({
    required this.id,
    required this.email,
    required this.displayName,
    this.avatarPath,
    this.bannerPath,
    this.createdAt,
  });

  final String id;
  final String email;
  String displayName;
  String? avatarPath;
  String? bannerPath;
  final DateTime? createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'displayName': displayName,
        'avatarPath': avatarPath,
        'bannerPath': bannerPath,
        'createdAt': createdAt?.toIso8601String(),
      };

  factory UserAccount.fromJson(Map<String, dynamic> json) => UserAccount(
        id: json['id'] as String,
        email: json['email'] as String,
        displayName: json['displayName'] as String,
        avatarPath: json['avatarPath'] as String?,
        bannerPath: json['bannerPath'] as String?,
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : null,
      );
}

class BookItem {
  BookItem({
    required this.id,
    required this.title,
    required this.author,
    required this.filePath,
    this.coverPath,
    this.progress = 0,
    this.lastChapterIndex = 0,
    this.bookmarkChapterIndex,
    this.bookmarkChapterTitle,
    this.bookmarkScrollOffset = 0,
    this.bookmarkAt,
    this.addedAt,
  });

  final String id;
  final String title;
  final String author;
  final String filePath;
  String? coverPath;
  double progress;
  int lastChapterIndex;
  int? bookmarkChapterIndex;
  String? bookmarkChapterTitle;
  double bookmarkScrollOffset;
  DateTime? bookmarkAt;
  final DateTime? addedAt;

  bool get hasBookmark => bookmarkChapterIndex != null;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'author': author,
        'filePath': filePath,
        'coverPath': coverPath,
        'progress': progress,
        'lastChapterIndex': lastChapterIndex,
        'bookmarkChapterIndex': bookmarkChapterIndex,
        'bookmarkChapterTitle': bookmarkChapterTitle,
        'bookmarkScrollOffset': bookmarkScrollOffset,
        'bookmarkAt': bookmarkAt?.toIso8601String(),
        'addedAt': addedAt?.toIso8601String(),
      };

  factory BookItem.fromJson(Map<String, dynamic> json) => BookItem(
        id: json['id'] as String,
        title: json['title'] as String,
        author: json['author'] as String,
        filePath: json['filePath'] as String,
        coverPath: json['coverPath'] as String?,
        progress: (json['progress'] as num?)?.toDouble() ?? 0,
        lastChapterIndex: json['lastChapterIndex'] as int? ?? 0,
        bookmarkChapterIndex: json['bookmarkChapterIndex'] as int?,
        bookmarkChapterTitle: json['bookmarkChapterTitle'] as String?,
        bookmarkScrollOffset: (json['bookmarkScrollOffset'] as num?)?.toDouble() ?? 0,
        bookmarkAt: json['bookmarkAt'] != null
            ? DateTime.parse(json['bookmarkAt'] as String)
            : null,
        addedAt: json['addedAt'] != null
            ? DateTime.parse(json['addedAt'] as String)
            : null,
      );
}

class Playlist {
  Playlist({
    required this.id,
    required this.name,
    required this.bookIds,
    this.emoji = '📚',
    this.coverPath,
    this.createdAt,
  });

  final String id;
  String name;
  String emoji;
  String? coverPath;
  List<String> bookIds;
  final DateTime? createdAt;

  bool get hasCover =>
      coverPath != null && coverPath!.isNotEmpty;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'emoji': emoji,
        'coverPath': coverPath,
        'bookIds': bookIds,
        'createdAt': createdAt?.toIso8601String(),
      };

  factory Playlist.fromJson(Map<String, dynamic> json) => Playlist(
        id: json['id'] as String,
        name: json['name'] as String,
        emoji: json['emoji'] as String? ?? '📚',
        coverPath: json['coverPath'] as String?,
        bookIds: List<String>.from(json['bookIds'] as List? ?? []),
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : null,
      );
}

class ReadingStreak {
  ReadingStreak({
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastReadDate,
    this.todayMinutes = 0,
    this.goalMinutes = 15,
  });

  int currentStreak;
  int longestStreak;
  DateTime? lastReadDate;
  int todayMinutes;
  int goalMinutes;

  Map<String, dynamic> toJson() => {
        'currentStreak': currentStreak,
        'longestStreak': longestStreak,
        'lastReadDate': lastReadDate?.toIso8601String(),
        'todayMinutes': todayMinutes,
        'goalMinutes': goalMinutes,
      };

  factory ReadingStreak.fromJson(Map<String, dynamic> json) => ReadingStreak(
        currentStreak: json['currentStreak'] as int? ?? 0,
        longestStreak: json['longestStreak'] as int? ?? 0,
        lastReadDate: json['lastReadDate'] != null
            ? DateTime.parse(json['lastReadDate'] as String)
            : null,
        todayMinutes: json['todayMinutes'] as int? ?? 0,
        goalMinutes: json['goalMinutes'] as int? ?? 15,
      );
}
