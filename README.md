# cleanup — deep disk cleanup skill for Claude Code (macOS)

[English](#english) · [Русский](#русский)

<a id="english"></a>

A [Claude Code](https://claude.com/claude-code) skill. Type `/cleanup` (or just say "my disk is full") and Claude:

1. **Scans read-only** — what actually eats the disk: build outputs, caches, simulators, emulators, data of uninstalled apps, media, external drives.
2. **Deletes only what regenerates itself** and isn't in use — Xcode `DerivedData`, caches of closed apps, npm/Homebrew caches.
3. **Asks you once, in batches** — not file by file — about everything else.
4. **Moves photos, videos and archives to an external drive** safely: copy → checksum verify → original to the Trash.
5. **Writes `RESTORE-MANIFEST.txt`** on the drive — every file's original path plus ready-to-paste restore commands.

## Safety rules it follows

- Anything used in the last **14 days** stays. In folders still in use, only older files move.
- Things that come back on the next build or device connection (Xcode DeviceSupport, Gradle caches, Playwright) are kept.
- No `rm` on your data — everything goes to `~/.Trash/cleanup-<date>/`; **you** empty the Trash after checking.
- Never fights macOS protection (SIP/TCC) with `sudo`.
- Looks inside data of uninstalled apps for your own videos/projects before removing it.
- Knows that `~/Movies/CapCut`, photo/Lightroom libraries and editor catalogs are app data, not media.
- Checks the drive filesystem first (NTFS is read-only on macOS; exFAT works).

## Install

```bash
git clone https://github.com/nikita3761/claude-cleanup-skill ~/.claude/skills/cleanup
```

Then in Claude Code: `/cleanup`.

## Scripts (usable on their own)

| Script | What it does |
|---|---|
| `scripts/scan.sh [N]` | Read-only report: disk, external drives, top folders, dev tooling, build outputs, media folders with last-modified dates, running apps |
| `scripts/offload.sh --dest DIR --list FILE [--min-age-days 14] [--dry-run]` | Copy listed `$HOME`-relative paths to `DIR`, verify with `rsync -c`, move originals to the Trash. `copy:` prefix keeps the original |
| `scripts/manifest.sh DIR` | Writes `RESTORE-MANIFEST.txt` with path mapping, restore commands, summary and full file list |

Requirements: macOS, `rsync` (built in), `zsh`/`bash`. Tested on macOS 15.

## License

MIT

---

<a id="русский"></a>
# cleanup — скилл глубокой очистки диска для Claude Code (macOS)

Скилл для [Claude Code](https://claude.com/claude-code). Наберите `/cleanup` или просто скажите «на диске кончилось место». Claude сделает следующее:

1. **Просканирует диск, ничего не меняя.** Покажет, что на самом деле занимает место: сборки, кэши, симуляторы, эмуляторы, данные удалённых приложений, фото и видео, внешние диски.
2. **Удалит без вопросов только то, что восстановится само** и сейчас не используется: `DerivedData` в Xcode, кэши закрытых приложений, кэши npm и Homebrew.
3. **Один раз задаст вопросы по всему остальному.** Не по каждому файлу, а пакетами.
4. **Безопасно перенесёт фото, видео и архивы на внешний диск.** Сначала копирует, потом сверяет копию с оригиналом по контрольным суммам и только после этого отправляет оригинал в Корзину.
5. **Создаст на внешнем диске `RESTORE-MANIFEST.txt`.** В нём исходный путь каждого файла и готовые команды для возврата.

## Правила безопасности

- Всё, чем пользовались за последние **14 дней**, остаётся на месте. Из папок, которые ещё в работе, переносятся только старые файлы.
- Не удаляется то, что скачается заново при следующей сборке или подключении устройства: DeviceSupport в Xcode, кэши Gradle, браузеры Playwright.
- Ваши данные не удаляются насовсем через `rm`. Всё складывается в `~/.Trash/cleanup-<дата>/`, а Корзину **вы** очищаете сами после проверки.
- Скилл не обходит защиту macOS (SIP/TCC) через `sudo`.
- Прежде чем удалить данные удалённого приложения, скилл ищет в них ваши видео и проекты.
- `~/Movies/CapCut`, медиатеки Фото и Lightroom, каталоги редакторов считаются рабочими данными приложений, а не медиа, и не переносятся.
- Первым делом проверяется формат внешнего диска. Диск в NTFS на macOS доступен только для чтения, exFAT подходит.

## Установка

```bash
git clone https://github.com/nikita3761/claude-cleanup-skill ~/.claude/skills/cleanup
```

Затем в Claude Code наберите `/cleanup`.

## Скрипты (работают и сами по себе)

| Скрипт | Что делает |
|---|---|
| `scripts/scan.sh [N]` | Отчёт без изменений на диске: свободное место, внешние диски, крупные папки, инструменты разработки, сборки, папки с медиа и даты их последнего изменения, запущенные приложения |
| `scripts/offload.sh --dest DIR --list FILE [--min-age-days 14] [--dry-run]` | Копирует пути из списка (относительно `$HOME`) в `DIR`, сверяет копию через `rsync -c`, переносит оригиналы в Корзину. С префиксом `copy:` оригинал остаётся на месте |
| `scripts/manifest.sh DIR` | Создаёт `RESTORE-MANIFEST.txt`: соответствие путей, команды для возврата, сводку и полный список файлов |

Нужно: macOS, `rsync` (встроен), `zsh` или `bash`. Проверено на macOS 15.

## Лицензия

MIT
