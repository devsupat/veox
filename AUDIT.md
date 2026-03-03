# AUDIT.md — Phase 2–3 Debugging Audit

## 1. Implementation Map

### QueueService (`lib/features/queue/domain/queue_service.dart`)
| Concern | Location |
|---|---|
| Task scheduling / pool routing | `_tick()` — classifies `browser_screenshot`, `browser_generate_video`, `browser_action` as **browser pool** (max 1); all others go to **local pool** (max 2). |
| Dispatching to Node | `_browserAction()` — builds `job_start` payload with `type` + `taskId`, sends via `NodeService.sendCommand()`. |
| Pause / Resume | `_handleNodeEvent()` listens to `eventStream` for `needs_login` → sets status `paused_needs_login`. `resumeTask()` resets to `pending`. |
| Cancel | `cancelTask()` — sends `job_cancel` to Node (for `running` **and** `paused_needs_login` tasks), marks DB `canceled`. |
| Error classification | `_processTask()` catch block checks `ProcessFailure.retryable`. `true` → `failed` (can retry). `false` → `canceled` (permanent). |
| Idempotency | `_processTask()` checks `outputPath` exists, is >1 KB, and not `.partial` before skipping. |

### NodeService (`lib/core/ipc/node_service.dart`)
| Concern | Location |
|---|---|
| NDJSON parsing | `_handleLine()` — decodes JSON, routes by `type` field: `result` (correlate), `event` (broadcast), `log`/`system` (UI). |
| Event stream | `eventStream` — broadcasts raw `Map<String, dynamic>` events from Node. Consumed by `QueueService._handleNodeEvent`. |
| Command correlation | `sendCommand()` — stores `Completer` in `_pending[id]`, resolves when matching `result` arrives. |
| Retryable flag | `_handleLine result` path extracts `json['retryable']` → passes to `ProcessFailure(retryable:)`. |
| Debug env | `startEngine()` passes `VEOX_DEBUG=1` when `kDebugMode` is true. |

### Node Engine (`engine/main.js`)
| Concern | Location |
|---|---|
| `job_start` | `jobStart()` — creates `AbortController`, dispatches to `_runBrowserScreenshot` or `_runBrowserVideo`. |
| `job_cancel` | `jobCancel()` — sets cancel flag + calls `controller.abort()`. |
| Cancel check | `_checkCancel()` — throws `retryable: false` error when flag is set. |
| Progress events | `emitProgress()` — sends `{ type: 'event', id, stage }` + structured log. |
| Debug artifacts | `debugCapture()` — when `VEOX_DEBUG=1`, saves `{debug}/{taskId}_{stage}.png` + `.html`. |
| Error classification | Each throw uses `Object.assign(err, { retryable: true/false })`. Top-level catch in `rl.on('line')` forwards `retryable` in the JSON result. |

---

## 2. E2E Manual Test Scripts

### Prerequisites (macOS)
```bash
cd veox_flutter
npm install --prefix engine   # install playwright + deps
flutter run -d macos
```

### Test A: Phase 2 — Screenshot Happy Path
1. Open app → Settings → assign a Google profile.
2. Home tab → click **Login/Connect**.
3. **Expected**: Browser opens, navigates to Veo, takes screenshot.
4. **Verify**: `~/Documents/VEOX/screenshots/{taskId}.png` exists and is >1 KB.
5. **Verify**: Queue counter **Done** increments by 1.

### Test B: Phase 2 — needs_login Pause/Resume
1. Use a **fresh profile** (no cookies).
2. Click **Login/Connect**.
3. **Expected**: Browser opens → login page detected → button changes to **Resume**.
4. Log in manually in the Playwright browser.
5. Click **Resume**.
6. **Expected**: Task re-dispatches, screenshot completes.
7. **Verify**: Status in Job Queue shows `completed`.

### Test C: Phase 2 — Cancel (expect `canceled`)
1. Click **Login/Connect** (any profile).
2. While status shows `running` or `paused_needs_login`, click **Cancel**.
3. **Verify**: Task status in Isar = `canceled` (not `failed`).
4. **Verify**: Retry does NOT pick up `canceled` tasks (they stay canceled).

### Test D: Phase 3 — Generate Video Happy Path
1. Connect browser first (Login/Connect).
2. Enter a prompt → click **Generate**.
3. **Expected**: Progress shows `open → navigate → login_check → prompt_fill → submit → poll → download → done`.
4. **Verify**: `~/Documents/VEOX/videos/{taskId}.mp4` exists and plays.

### Test E: Phase 3 — Cancel Mid-Poll
1. Click **Generate** with a valid prompt.
2. While status shows `poll`, click **Cancel**.
3. **Verify**: Polling stops immediately. Status = `canceled`.
4. **Verify**: No `.partial` file remains.

### Test F: Phase 3 — Cancel Mid-Download
1. Click **Generate** and wait until `download` stage.
2. Click **Cancel**.
3. **Verify**: `.partial` file is cleaned up. Status = `canceled`.

### Test G: Phase 3 — Retryable vs Non-Retryable
| Scenario | Expected |
|---|---|
| Navigation timeout (retryable) | Status = `failed`, retry backoff kicks in |
| Policy block detected (non-retryable) | Status = `canceled`, NO retry |
| Manual cancel (non-retryable) | Status = `canceled`, NO retry |

---

## 3. Instrumentation

### Debug Toggle
- **Config flag**: `VEOX_DEBUG` environment variable.
- In **debug builds** (`kDebugMode`), `VEOX_DEBUG=1` is automatically passed to the Node engine via `NodeService.startEngine()`.
- In **release builds**, set manually: `VEOX_DEBUG=1 flutter run -d macos`.

### Debug Artifacts (when `VEOX_DEBUG=1`)
On any failure in `_runBrowserVideo`:
- **Screenshot**: `{projectOutput}/debug/{taskId}_{stage}.png`
- **HTML dump**: `{projectOutput}/debug/{taskId}_{stage}.html`

### State Transition Logging
Every `emitProgress()` call now logs:
```
[state] {taskId} → {stage}
```
Visible in Flutter's terminal log panel via `NodeService.logStream`.

---

## 4. Bugs Found & Patched

### BUG-1 (CRITICAL): `browser_generate_video` missing from browser pool
- **File**: `queue_service.dart` → `_tick()`
- **Impact**: Video generation tasks would run in the **local pool** (max 2), bypassing the browser pool limit (max 1). Two video tasks could fight over one browser context.
- **Fix**: Added `task.type == 'browser_generate_video'` to the `isBrowser` classification.

### BUG-2 (CRITICAL): Cancelled jobs retried indefinitely
- **File**: `engine/main.js` → `_checkCancel()`
- **Impact**: `_checkCancel()` threw a plain `Error` without `retryable: false`. The `jobStart` catch block defaulted it to `retryable: true`, so cancelled jobs would be endlessly retried.
- **Fix**: Added `{ retryable: false }` to the cancel error.

### BUG-3 (MEDIUM): `cancelTask` didn't handle `paused_needs_login`
- **File**: `queue_service.dart` → `cancelTask()`
- **Impact**: Cancelling a paused task would update the DB but not send `job_cancel` to Node. The browser page/context could remain open.
- **Fix**: Extended the condition to also send `job_cancel` for `paused_needs_login` tasks. Wrapped in try/catch since the job may have already exited.

---

## 5. File Tree (Relevant)

```
veox_flutter/
├── engine/
│   └── main.js                          # Node engine (job_start, job_cancel, debug)
├── lib/
│   ├── core/
│   │   ├── errors/failures.dart         # ProcessFailure.retryable
│   │   └── ipc/node_service.dart        # NDJSON IPC, VEOX_DEBUG passthrough
│   ├── features/
│   │   ├── automation/
│   │   │   ├── models/automation_state.dart
│   │   │   └── services/veo_automation_service.dart
│   │   └── queue/
│   │       ├── domain/queue_service.dart # Pool routing, cancel, error classification
│   │       └── presentation/queue_provider.dart
│   └── ui/pages/home_tab.dart
└── AUDIT.md                             # This file
```

---

## 6. Run Instructions

```bash
cd veox_flutter
flutter run -d macos          # debug build → VEOX_DEBUG=1 auto-enabled
```

## 7. Post-Task Checks

- [ ] Run Test A–G from §2 above.
- [ ] After Test C: query Isar → verify status string is literally `canceled`.
- [ ] After Test E: verify no `.partial` files in `~/Documents/VEOX/videos/`.
- [ ] After Test G (policy): verify `retryFailed()` does NOT pick up `canceled` tasks.
- [ ] Check `~/Documents/VEOX/videos/debug/` for `.png` + `.html` artifacts (requires a failure in debug mode).
