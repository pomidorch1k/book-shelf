# Сборка APK через GitHub

APK собирается автоматически в GitHub Actions — на компьютере Flutter не нужен.

## Шаг 1. Создайте репозиторий на GitHub

1. Откройте https://github.com/new
2. Имя репозитория, например: `book-shelf`
3. **Public** или **Private** — на ваш выбор
4. **Не** добавляйте README, .gitignore и license (проект уже есть локально)
5. Нажмите **Create repository**

## Шаг 2. Загрузите код

В PowerShell:

```powershell
cd C:\Users\Olegator\book-shelf
git init
git add .
git commit -m "Книжная полка: Flutter приложение с читалкой EPUB"
git branch -M main
git remote add origin https://github.com/ВАШ_ЛОГИН/book-shelf.git
git push -u origin main
```

Замените `ВАШ_ЛОГИН` и `book-shelf` на свои значения.

## Шаг 3. Скачайте APK

1. На GitHub откройте репозиторий → вкладка **Actions**
2. Выберите workflow **Build Android APK** (последний зелёный запуск)
3. Прокрутите вниз до **Artifacts**
4. Скачайте **book-shelf-release-apk** — внутри файл `app-release.apk`
5. Перенесите на телефон и установите

## Пересборка вручную

**Actions** → **Build Android APK** → **Run workflow** → **Run workflow**

Через 5–10 минут появится новый артефакт с APK.

## Ошибки

Если workflow красный — откройте упавший job и пришлите текст ошибки из лога.
