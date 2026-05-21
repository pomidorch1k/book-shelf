class ReaderSettings {
  ReaderSettings({
    this.fontSize = 18,
    this.lineHeight = 1.65,
    this.horizontalPadding = 20,
    this.readerTheme = ReaderThemePreset.light,
  });

  double fontSize;
  double lineHeight;
  double horizontalPadding;
  ReaderThemePreset readerTheme;

  Map<String, dynamic> toJson() => {
        'fontSize': fontSize,
        'lineHeight': lineHeight,
        'horizontalPadding': horizontalPadding,
        'readerTheme': readerTheme.name,
      };

  factory ReaderSettings.fromJson(Map<String, dynamic> json) => ReaderSettings(
        fontSize: (json['fontSize'] as num?)?.toDouble() ?? 18,
        lineHeight: (json['lineHeight'] as num?)?.toDouble() ?? 1.65,
        horizontalPadding: (json['horizontalPadding'] as num?)?.toDouble() ?? 20,
        readerTheme: ReaderThemePreset.values.firstWhere(
          (e) => e.name == json['readerTheme'],
          orElse: () => ReaderThemePreset.light,
        ),
      );

  ReaderSettings copyWith({
    double? fontSize,
    double? lineHeight,
    double? horizontalPadding,
    ReaderThemePreset? readerTheme,
  }) =>
      ReaderSettings(
        fontSize: fontSize ?? this.fontSize,
        lineHeight: lineHeight ?? this.lineHeight,
        horizontalPadding: horizontalPadding ?? this.horizontalPadding,
        readerTheme: readerTheme ?? this.readerTheme,
      );
}

enum ReaderThemePreset { light, dark, sepia }
