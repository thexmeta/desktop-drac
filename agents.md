# Desktop-Drac: Linux Fork von GitHub Desktop - Arbeitsprotokoll

## Projektzusammenfassung

**desktop-drac** ist ein Linux-Fork von GitHub Desktop (Electron/TypeScript/React).
Forkchain: `desktop/desktop` -> `shiftkey/desktop` -> `xi72yow/desktop-drac`

Der shiftkey-Fork wird nicht mehr aktiv gepflegt. Ziel ist es, den Fork aktuell zu halten
und mit dem offiziellen upstream (`desktop/desktop`) via **Rebase-Stack** zu synchronisieren
(siehe Abschnitt „Sync mit upstream (Rebase-Stack)").

## Umgebung

| Tool | Version |
|---|---|
| Node.js | 24.11.1 (via nvm, pinned in `.node-version` / `.nvmrc`) |
| Yarn | 1.21.1 (vendored in `vendor/yarn-1.21.1.js`) |
| Electron | 42.0.1 |
| Python | 3.13.5 |
| OS | Linux (Debian/amd64) |

### Systemabhängigkeiten (apt)

- `libsecret-1-dev` - Credential Storage (keytar)
- `libxss1` - X11 Screen Saver Extension
- `libgconf-2-4` - GNOME Config (optional, je nach Distro)

## Git Remotes

| Remote | URL | Beschreibung |
|---|---|---|
| `origin` | `https://github.com/xi72yow/desktop-drac.git` | Eigener Fork (Push: nur xi72yow-Rechte; thexmeta-Creds = 403) |
| `upstream` | `https://github.com/shiftkey/desktop.git` | Alter Linux-Fork (shiftkey) — historisch |
| `desktop` | `https://github.com/desktop/desktop.git` | Offizielles GitHub Desktop — aktueller upstream, Rebase-Stack-Basis |

## Was wir gemacht haben

### 1. Umgebung geprüft

- Node.js 22 war installiert, aber das Projekt brauchte Node 20.17.0 (pre-merge)
- `nvm install 20.17.0` und `nvm use 20.17.0` zum Wechseln
- `libsecret-1-dev` musste nachinstalliert werden (`sudo apt install libsecret-1-dev`)
- Yarn ist im Projekt vendored - muss nicht global installiert sein

### 2. Upstream eingerichtet

```bash
git remote add desktop https://github.com/desktop/desktop.git
git fetch desktop
```

Hinweis: Das Remote heißt heute `desktop`.

Hinweis: Der Fetch des `gemoji`-Submoduls schlägt fehl (veraltete Referenz) - ist nicht kritisch.

### 3. Stand analysiert

- **47 Linux-spezifische Commits** auf dem `linux` Branch (Tooling, ARM-Support, Flatpak, Linux-UI-Fixes)
- **1.649 Commits** ist das offizielle upstream voraus

Linux-spezifische Commits umfassen:
- ARM32/ARM64 Build-Support
- Debian/RPM/AppImage Packaging
- Flatpak-Integration (Code-Editoren erkennen)
- Linux-spezifische UI-Fixes (Titlebar, About-Dialog, Argument-Parsing)
- CI/CD Workflows für den Fork
- Dependabot-Updates

### 4. Dependencies installiert und Pre-Merge Build getestet

```bash
export NVM_DIR="$HOME/.nvm" && [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh" && nvm use 20.17.0
node vendor/yarn-1.21.1.js install
node vendor/yarn-1.21.1.js build:dev
```

- Alle 5 Webpack-Targets kompiliert: main, renderer, crash, cli, highlighter
- App lief erfolgreich im Dev-Modus

### 5. Merge von desktop/development (1.649 Commits)

```bash
git merge desktop/development
```

Dieser Merge ist **historisch** — der Fork wird heute via Rebase-Stack synchronisiert (siehe Abschnitt „Sync mit upstream (Rebase-Stack)").

**15 Dateien mit Konflikten**, alle manuell gelöst:

| Datei | Lösung |
|---|---|
| `docs/technical/shell-integration.md` | Beide Shells behalten (Black Box + Ghostty) |
| `.github/workflows/ci.yml` | Upstream Runner übernommen (macos-14-xlarge, windows-2022) |
| `script/build.ts` | Unbenutzten Import `OfficialArch` und `os` entfernt |
| `package.json` | Linux-Pakete behalten (electron-builder, parallel-webpack, patch-package, optionalDependencies), upstream-Versionen übernommen (Electron 42.0.1, neue Deps) |
| `app/package.json` | `keytar-forked` behalten, `windows-argv-parser` nicht übernommen (Linux-Fork hat es entfernt), `which` übernommen |
| `app/src/lib/shells/linux.ts` | Beide Shells hinzugefügt (BlackBox + Ghostty) |
| `app/src/lib/custom-integration.ts` | Doppelte Imports bereinigt, `windows-argv-parser` Import nicht übernommen |
| `app/src/lib/editors/launch.ts` | Upstream's schlanke `launchEditor` Helper übernommen, Linux/Flatpak `spawnEditor` Support eingebaut |
| `app/src/lib/ipc-shared.ts` | `TitleBarStyle` Import behalten, `desktop-notifications` Import-Pfade auf upstream aktualisiert |
| `app/src/main-process/main.ts` | `handlePossibleProtocolLauncherArgs` durch `handleCommandLineArguments` ersetzt, Linux URL-Argument-Parsing in `handleCommandLineArguments` beibehalten, upstream Security-Fix (`return` nach `--protocol-launcher`) übernommen |
| `app/src/models/popup.ts` | `ConfirmRestart` (Linux) behalten + alle neuen upstream PopupTypes übernommen |
| `app/src/ui/about/about.tsx` | Linux "View Releases" Link behalten, `this.state` -> `this.props` für updateState (upstream Refactor) |
| `app/src/ui/app.tsx` | `ConfirmRestart` Import behalten + alle neuen upstream Popup-Renderer übernommen |
| `yarn.lock` + `app/yarn.lock` | Upstream-Version übernommen, durch `yarn install` regeneriert |

### 6. Post-Merge Fixes

- **`postinstall-postinstall`** Paket entfernt - inkompatibel mit npm 11 (Node 24), war redundant da `patch-package` bereits im `post-install.ts` aufgerufen wird
- **Node-Version auf 24.11.1** hochgestuft (upstream Anforderung, `process-proxy@0.5.0` braucht Node >= 22)
- **`custom-integration.ts`**: Doppelte `child_process` Imports bereinigt, unbenutzten `ChildProcess` Import entfernt
- **`linux-test.ts`**: Von Jest auf `node:test` + `node:assert` migriert (upstream hat Test-Framework gewechselt)

### 7. Tests

```
874 Tests, 871 bestanden, 2 fehlgeschlagen, 1 übersprungen
```

Die 2 Failures sind vorbestehende Edge-Cases (Git-Befehle in Nicht-Git-Verzeichnis), nicht durch Merge verursacht.

### 8. Packaging verbessert

**`script/package.ts`** angepasst: Automatische Distro-Erkennung via `/etc/os-release`:
- Debian/Ubuntu -> nur `.deb` + AppImage
- Fedora/RHEL/SUSE -> nur `.rpm` + AppImage
- Unbekannt -> beides (wie bisher)

So muss `rpmbuild` nicht auf Debian installiert sein und umgekehrt.

### 9. Prod-Build und Packaging erfolgreich

```bash
node vendor/yarn-1.21.1.js build:prod   # Prod-Build
node vendor/yarn-1.21.1.js run package  # Packaging
```

Ergebnis:
- `dist/GitHubDesktop-linux-x86_64-3.5.5.AppImage` (178 MB)
- `dist/GitHubDesktop-linux-amd64-3.5.5.deb` (130 MB)
- SHA256 Checksummen generiert
- `.deb` installiert und getestet - funktioniert!

### 10. CI/CD vereinfacht (Debian First)

Strategie: **Debian first** - nur amd64, nur `.deb` + AppImage. Kein ARM, kein RPM.

**`.github/workflows/ci-linux.yml`** komplett umgeschrieben:
- ARM-Jobs (`arm64`, `arm`) entfernt
- shiftkey Container-Actions durch direkte Build-Steps ersetzt (`actions/setup-node`, `apt-get install`)
- `amd64` Job: Ubuntu-latest Runner, Node 24.11.1, vendored Yarn
- Publish-Job: Node 24.11.1, `tsx` statt `ts-node`, `softprops/action-gh-release@v2`
- Artifacts: nur `*.AppImage`, `*.deb`, `*.sha256`

**`script/generate-release-notes.ts`** angepasst:
- `SUCCESSFUL_RELEASE_FILE_COUNT` von `3 * 3 * 2 = 18` auf `1 * 2 * 2 = 4` (1 Arch x 2 Formate x 2 Dateien)

**Versionsschema**: `release-{upstream-version}-linux{revision}`
- Beispiel: `release-3.5.5-linux1` (erster Linux-Release von upstream 3.5.5)
- `-linux1`: zieht automatisch upstream Changelog
- `-linux2`+: manuelle Release Notes (eigene Änderungen)

### 11. Upstream-Workflows aufgeräumt

Alle irrelevanten upstream-Workflows gelöscht:
- `ci.yml` (Mac/Windows CI)
- `create-draft-release.yml`, `sync-with-upstream.yml`, `release-pr.yml` (upstream Release-Infra)
- `triage-prs.yml`, `triage-issues.yml`, `triage-scheduled-tasks.yml` (upstream Triage-Bots)

Behalten:
- `ci-linux.yml` (unsere CI)
- `codeql.yml` (Security Scanning, kostenlos für öffentliche Repos)

**Achtung**: Die Löschungen sind heute als Stack-Commit T12 (046bb3a44) im Rebase-Stack verbucht; beim Rebase auf ein neueres upstream-Release werden sie automatisch mitgeführt (kein erneutes manuelles Löschen nötig).

### 12. wrap-ansi Fix für Node 24

`electron-builder` bundelt `cliui`/`yargs` die `wrap-ansi` nutzen. Version 8.x ist ESM-only und crasht unter Node 24 (`TypeError: mixin.wrap is not a function`).

Fix: `wrap-ansi` auf 7.0.0 (letzte CJS-Version) gepinnt via Yarn Resolution in `package.json`:
```json
"resolutions": {
  "wrap-ansi": "7.0.0"
}
```

**Achtung**: Beim Rebase auf ein neueres upstream-Release können die Lockfiles überschrieben werden. Danach `node vendor/yarn-1.21.1.js install` laufen lassen (Regen-Commit T14, 95691aaa2); Lockfiles nie hand-editen.

### 13. Release-Workflow + APT-Repo auf GitHub Pages

**`workflow_dispatch` Trigger** in `ci-linux.yml`:
- GitHub Actions Tab -> "Run workflow" -> Version eingeben (z.B. `3.5.5-linux1`)
- Tag wird automatisch erstellt und gepusht
- GitHub Release (draft) mit .deb, AppImage, sha256
- Ohne Version: nur Build (dry run)

**APT-Repository** auf GitHub Pages (`https://xi72yow.github.io/desktop-drac`):
- `scripts/update-apt-repo.sh` baut Repo-Struktur (`dpkg-scanpackages`, GPG-Signierung)
- Automatisch deployed nach jedem Release
- Gleicher GPG-Key wie zed-deb Repo
- Benötigt `GPG_PRIVATE_KEY` Secret im GitHub Repo

**User-Installation:**
```bash
# GPG Key importieren
curl -fsSL https://xi72yow.github.io/desktop-drac/pubkey.gpg | sudo gpg --dearmor -o /usr/share/keyrings/desktop-drac.gpg

# Repo hinzufügen
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/desktop-drac.gpg] https://xi72yow.github.io/desktop-drac stable main" | sudo tee /etc/apt/sources.list.d/desktop-drac.list

# Installieren
sudo apt update && sudo apt install github-desktop
```

Getestet auf Debian Trixie - funktioniert!

## Sync mit upstream (Rebase-Stack)

**Terminologie**: upstream = `desktop/desktop` (Remote `desktop`). Sync-Methode = **Rebase-Stack** (kein Merge). Basis-Tag derzeit `release-3.6.6` (8b85519e7). Fork-Endstand = Branch `linux` (52023946b).

### Ein-Kommando-Sync

```bash
bash scripts/rebase-upstream.sh
```

Das Script: fetcht Tags von `desktop`, erkennt neueres `release-*`, legt `stack/<tag>` an und rebased per `--onto`. Abbruch bei dreckigem Tree oder fehlendem Backup-Tag. Nur lokal — es pusht nie automatisch.

### Konflikte (Contract)

| Datei | Regel |
|---|---|
| `app/src/main-process/main.ts` | `git merge-file`; `confirm-reveal-directory`-Handler **muss** erhalten bleiben |
| `package.json`, `app/package.json` | 3-Way-Merge; **niemals** `git checkout linux --` |
| `yarn.lock`, `app/yarn.lock` | Regenerieren via `node vendor/yarn-1.21.1.js install`; nie hand-edit |

**Konvention (CONV-2): Hunk-map conflict zones before every rebase/cherry-pick.** Bevor
jeder Rebase oder Cherry-Pick läuft, eine Hunk-level-Map der erwarteten
Konfliktzonen erstellen: die konkreten Files, Symbole oder Const-Blöcke, in denen
sich upstream- und lokale Änderungen überschneiden. Selbst wenn git sauber
auto-mergt, gelten die gemappten Zonen als Abnahmetest — jede Zone nach dem Merge
mit einem gezielten grep/diff nachprüfen, das die vorgegebene Resolution-Shape
bestätigt. Ein sauberer Merge ist **kein** Beleg, dass die Zonen korrekt gelöst
wurden (Beleg T22: cherry-pick repo-pinning, app-store.ts const block).

### CI

`ci-linux.yml` Trigger: `[development, linux, linux-release-*]`.
- Test: `node vendor/yarn-1.21.1.js test`
- Install: `node vendor/yarn-1.21.1.js install --frozen-lockfile`
- App-Install läuft im Root-`postinstall` (Root-`node_modules/.bin` muss im PATH sein)

**Baseline (keine Regressionen)**: 14/1476 fehlschlagende Git-Behavior-Tests + `check:eslint` Exit 2 (5× TS2307).

### APT-Veröffentlichung

`scripts/update-apt-repo.sh` + Prozessdoku `docs/process/publishing-linux-releases.md`.

## Rollback

Kanonisches Rollback-Target: TAG `backup/linux-merge-era-20261004` (52023946b, Endstand des Merge-Ära-Forks).

```bash
git switch -C linux backup/linux-merge-era-20261004
git push origin linux        # Voraussetzung: xi72yow/desktop-drac Push-Rechte
git push fork linux          # `fork` = thexmeta/desktop-drac; thexmeta-Creds: origin = 403, Fork OK
```

**Niemals** Backup-Tags/-Branches löschen oder per Force-Update überschreiben.

## Stack-Layout (Rebase-Stack-Ära)

Basis: `release-3.6.6` (8b85519e7). Fork-Endstand: `linux` (= Stack-Tip `stack/3.6.6`, Publish via T20 default-branch-Tanz). 15 Content-Commits = 12 Layer-Commits (T06–T16) + 2 CI-Wartungs-Commits (T19/T19c) + 1 User-Feature (T22 repo-pinning) — **+ this docs-correction commit (T23) = 16 total**:

| Commit | Task | Welle | Inhalt |
|---|---|---|---|
| 1da6db63b | T06 | 3 | Infra: Workflows, Packaging, static, Manifeste; keytar+fs-admin Retargets |
| bccce11b1 | T07 | 3 | main.ts: argv/Protocol-URL; `confirm-reveal-directory` erhalten |
| 401cb41bb | T08 | 3 | App-Store + IPC-Vertrag |
| 1679db1ee | T09 | 3 | Dracula-Theme + UI |
| 0066658af | T09b | 3 | Protocol-URL-Tests |
| 792f9f4a6 | T10 | 3 | Title-Bar-Feature |
| b61dc24da | T11 | 3 | linux-support: helpers/linux.ts retired; Black Box + Flatpak erhalten |
| 046bb3a44 | T12 | 3 | Workflow-Löschungen (8) |
| 5455e2845 | T13 | 3 | Docs |
| 95691aaa2 | T14 | 3 | Lockfile-Regen + S1-Union-Check (85/85 verbucht: 83 angewandt + 2 dokumentierte T11-Dispositionen) |
| 213096eef | T15 | 4 | check-upstream-Rewrite + `scripts/rebase-upstream.sh` |
| 0d87e5278 | T16 | 4 | docs(agents): rebase-stack workflow + rollback runbook |
| 1ec56e1d8 | T19 | 6 | CI-Wartung: NODE_VERSION-Bump 24.11.1 → 24.15.0 (ini@7.0.0 engines) |
| 00272d964 | T19c | 6 | CI-Wartung: prettier-Format + no-sync lint debt |
| a9f9760db | T22 | 7 | User-Feature: repo-pinning + updates grouping (Cherry-pick von `repo-pinning` 7efd503dc) |
| *(dieser)* | T23 | 10 | docs-correction: Stack-Commit-Count-Tabelle (T21-Finding F1) |

**Union-Check (T14)**: 85/85 upstream-Änderungen verbucht — 83 im Stack angewandt, 2 als dokumentierte T11-Dispositionen.

**WIP-Branches (lokal, nicht im Stack)**:
- `deb-build-all`, `repo-pinning`, `protocol-url-tests` → MISSING-FROM-STACK: später auf den Stack rebasen
- `pr7-lockfix`, `protocol-url-handling` → SUPERSEDED (nichts zu tun)
- nvmrc-Fix 41353668a → bereits via `ci-linux.yml` mitgeführt

## Nächste Schritte

- [ ] Electron 42 spezifische Änderungen prüfen (API-Deprecations etc.)
- [ ] Flatpak-Paket testen

## Nützliche Befehle

```bash
# nvm laden + Node 24 aktivieren (in jeder neuen Shell nötig)
export NVM_DIR="$HOME/.nvm" && [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh" && nvm use 24.11.1

# Dependencies installieren
node vendor/yarn-1.21.1.js install

# Dev-Build
node vendor/yarn-1.21.1.js build:dev

# App starten (Dev-Modus mit Live-Reload)
node vendor/yarn-1.21.1.js start

# Prod-Build + Packaging
node vendor/yarn-1.21.1.js build:prod
node vendor/yarn-1.21.1.js run package

# Tests
GIT_TERMINAL_PROMPT=0 node vendor/yarn-1.21.1.js test:unit

# Rebase-Stack-Sync (ein Befehl)
bash scripts/rebase-upstream.sh

# Stack-Commits (Linux-spezifisch, auf Basis release-3.6.6)
git log release-3.6.6..linux --oneline

# Upstream-Commits die noch fehlen (gegen aktuellen release-Tag)
git log linux..desktop/release-3.6.6 --oneline | wc -l
```
