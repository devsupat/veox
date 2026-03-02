# VEOX Architecture & Implementation Plan

## 1. Architecture Overview

**Pattern:** Host-Guest Process Model
*   **Host (Flutter Desktop):** The "Brain". Handles UI, State Management (Riverpod), Database (Isar), Task Scheduling, and Process Management.
*   **Guest (Node.js Subprocess):** The "Hands". Runs Playwright, handles browser interactions, stealth plugins, and file downloads.

**Communication (IPC):**
*   **Transport:** Standard Input/Output (STDIN/STDOUT).
*   **Protocol:** JSON-RPC 2.0 style (newline-delimited JSON).
    *   **Flutter -> Node:** `{ "id": "uuid", "command": "browser.launch", "payload": { "headless": false } }`
    *   **Node -> Flutter (Response):** `{ "id": "uuid", "status": "success", "result": ... }`
    *   **Node -> Flutter (Event):** `{ "type": "log", "level": "info", "message": "..." }` or `{ "type": "progress", "taskId": "...", "percent": 50 }`

## 2. Folder Structure

```
veox/
├── lib/
│   ├── main.dart
│   ├── core/                  # Core utilities (logger, constants)
│   ├── data/
│   │   ├── local/             # Isar/Hive implementation
│   │   └── models/            # Dart Data Models (Task, Project)
│   ├── features/
│   │   ├── automation/        # Task Queue, NodeBridgeService
│   │   ├── dashboard/         # UI Pages
│   │   └── settings/          # Profile management
│   └── shared/                # Shared widgets
│
├── automation_engine/         # Node.js Project Root
│   ├── package.json
│   ├── index.js               # Entry point (STDIN listener)
│   ├── core/
│   │   ├── browser.js         # Playwright context manager
│   │   └── logger.js          # Unified logging
│   ├── handlers/              # Command handlers
│   │   ├── generic.js         # Generic navigation/screenshot
│   │   └── veofx.js           # Specific Veo/VideoFX logic
│   └── user_data/             # Chrome Profiles (Persistent storage)
```

## 3. Data Models (Dart)

### Task
```dart
enum TaskStatus { pending, running, paused, completed, failed }

class Task {
  final String id;
  final String type; // e.g., "generate_video_veo"
  final Map<String, dynamic> params; // { "prompt": "...", "profileId": "..." }
  final TaskStatus status;
  final int retryCount;
  final String? error;
  final String? outputPath;
  final DateTime createdAt;
  
  // Isar annotations would go here
}
```

### BrowserProfile
```dart
class BrowserProfile {
  final String id;
  final String name; // "Personal", "Alt Account 1"
  final String userAgent;
  final String proxy; // Optional
  final Map<String, String> cookies; // Or path to storageState.json
}
```

## 4. Task Queue Engine (Flutter Side)

*   **Concurrency:** Semaphore pattern (e.g., max 1 or 2 active tasks to save RAM).
*   **Persistence:** Load pending tasks from Isar on app start.
*   **Retry:** Exponential backoff (delay = 2^retries * 1000ms).
*   **Idempotency:** Check if `outputOutput` exists before starting.

## 5. Browser Automation (Node Side)

*   **Engine:** `playwright-extra` with `puppeteer-extra-plugin-stealth` (adapted for Playwright) to avoid bot detection.
*   **Profiles:** Use `userDataDir` in `browserType.launchPersistentContext`. This keeps cookies/sessions alive (Auto-login).
*   **Video Downloads:** Intercept network requests (`page.on('response')`) matching video MIME types or specific API responses to capture download URLs, then download via Node `fs` stream to avoid browser dialogs.

## 6. Workflow Modules (Strategies)

1.  **Login Helper:** Open browser, wait for user to manually login, then save state (cookies/storage).
2.  **Generator:** 
    *   Navigate to URL.
    *   Check for "Sign in" selector -> if found, abort/notify.
    *   Input prompt.
    *   Click generate.
    *   Poll for completion selector.
    *   Extract video URL.
    *   Download.

## 7. Logging

*   **Structure:**
    *   Flutter UI has a `LogConsole` widget.
    *   Node sends logs via JSON: `{ "type": "log", "msg": "Clicking button...", "ts": 12345 }`.
    *   Flutter appends to memory list (for UI) and daily log file (for debug).

---

# Implementation Steps (Phase 0 & 1)

I will now generate the scaffolding for the **Automation Bridge** and the **Node.js Engine**.
