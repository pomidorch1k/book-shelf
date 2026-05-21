# Книжная полка

Мобильное Android-приложение для чтения EPUB-книг.

## Возможности

- Импорт EPUB, FB2 и MOBI с телефона
- Встроенная читалка с навигацией по главам
- Светлая и тёмная тема (приложение и читалка)
- Регистрация и вход
- Плейлисты книг
- Серия чтения (streak) как в Duolingo
- Профиль с аватаром и шапкой

## Цвета

- Burnt Sienna `#E97451`
- Powder Blue `#B0E0E6`

## Сборка APK (рекомендуется — через GitHub)

Локально Flutter не нужен. Подробная инструкция: **[GITHUB_BUILD.md](GITHUB_BUILD.md)**

1. Загрузите проект на GitHub (`git push`)
2. Откройте **Actions** → workflow **Build Android APK**
3. Скачайте артефакт **book-shelf-release-apk**

## Локальная сборка (опционально)

```powershell
cd C:\Users\Olegator\book-shelf
flutter pub get
flutter build apk --release
```

APK: `build\app\outputs\flutter-apk\app-release.apk`
