# DEV_RUNBOOK.md — VEOX Flutter Desktop Developer Loop

## Quick Start (Hot Reload Working)

```bash
cd veox_flutter
flutter run -d macos
```

Once the app launches you will see a prompt like:

```
Flutter run key commands.
r   Hot reload.  🔥🔥🔥
R   Hot restart.
h   List all available interactive commands.
d   Detach (terminate "flutter run" but leave application running).
c   Clear the screen.
q   Quit (terminate the application on the device).
```

| Action | Key | When to use |
|---|---|---|
| **Hot reload** | `r` | Dart-only changes (widgets, business logic, state) |
| **Hot restart** | `R` (shift+r) | State reset needed, new providers, new Isar schemas |
| **Full rebuild** | `q` then `flutter run -d macos` | Native code changes (entitlements, Podfile, Swift) |

---

## Why Hot Reload May Appear Broken

### 1. Terminal is not interactive
If you run `flutter run` inside a non-interactive terminal (e.g. an IDE "run" panel that doesn't forward stdin), the `r` / `R` keys are never sent to the Flutter tool.

**Fix**: Run from a real terminal (Terminal.app, iTerm2, Warp).

### 2. IDE-based run (Xcode / VS Code)
- **VS Code**: Use the **Run → Start Debugging** (F5) command, then hot reload via `Cmd+Shift+F5` or the ⚡ toolbar button.
- **Xcode**: Does **not** support Flutter hot reload. Always use `flutter run` from CLI.

### 3. Native code changes require full restart
Changes to these files are **never** hot-reloadable:
- `macos/Runner/*` (Swift, entitlements, Info.plist)
- `macos/Podfile` or any CocoaPods dependency
- `pubspec.yaml` (adding/removing packages)
- Isar schema changes (`*.g.dart`)
- Node engine (`engine/main.js`) — runs in a separate process

After touching any of the above: press `q`, then re-run `flutter run -d macos`.

### 4. Build cache corruption
If hot reload silently fails or shows "Reload rejected":

```bash
flutter clean
flutter pub get
flutter run -d macos
```

### 5. App state makes it look like nothing changed
Hot reload preserves widget state. If you changed `initState` logic or constructor defaults, the old state persists. Press `R` (hot restart) to reset all state.

---

## Recommended Dev Loop

```bash
# 1. Start (one time)
cd veox_flutter
flutter run -d macos

# 2. Edit Dart files in your editor

# 3. Switch to terminal, press 'r' → hot reload (< 1 second)
#    Press 'R' if you need a state reset

# 4. For Node engine changes (engine/main.js):
#    No Flutter restart needed — the NodeService restarts the Node process
#    automatically when sendCommand detects the process died.
#    OR: stop/start the engine via the UI.
```

---

## Entitlements (Already Correct ✅)

| File | Status |
|---|---|
| `DebugProfile.entitlements` | `allow-jit = true`, `app-sandbox = false`, network client+server enabled |
| `Release.entitlements` | `allow-jit = true`, `app-sandbox = false` |

> `allow-jit` is **required** for hot reload on macOS. It is already enabled. ✅

---

## Environment

| Item | Value |
|---|---|
| Flutter | 3.32.8 (stable) |
| Dart | 3.8.1 |
| Target device | macOS (desktop) `darwin-x64` |
| Build mode | Debug (default for `flutter run`) |

---

## Post-Task Checks

1. Run `flutter run -d macos` from **Terminal.app** or **iTerm2**.
2. Wait for "Flutter run key commands" prompt.
3. Change any widget text (e.g. a button label in `home_tab.dart`).
4. Press `r` in the terminal.
5. **Expected**: App updates in < 2 seconds without restarting.
6. Press `R` — app restarts fully (state reset).
7. Revert the text change, press `r` again — original text restored.
