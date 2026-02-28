# VEOX Architecture Specification

## 1. System Architecture Diagram Explanation

The VEOX system follows a **Clean Architecture** approach adapted for a desktop automation engine.

```mermaid
graph TD
    UI[Flutter UI Layer] <--> State[State Management (Riverpod)]
    State <--> Domain[Domain Layer (Use Cases)]
    Domain <--> Data[Data Layer (Repositories)]
    
    Data <--> DB[(Isar Database)]
    Data <--> FS[File System]
    
    Domain --> Engine[Automation Engine]
    Engine --> Isolates[Dart Isolates (Worker Pool)]
    Isolates --> Node[Node.js Sidecar (Playwright)]
    Node --> Chrome[Chrome Instances]
```

- **UI Layer**: Purely reactive. Subscribes to Riverpod providers. No business logic.
- **State Layer**: Handles application state, user inputs, and real-time updates from the engine.
- **Domain Layer**: Contains the core logic (e.g., `VideoGenerationUseCase`, `QueueManager`).
- **Data Layer**: Abstraction for storage. We use **Isar** for high-performance local storage of thousands of tasks.
- **Engine Layer**: The heart of VEOX.
    - **Isolates**: Heavy computation and blocking I/O (like managing 10 browser instances) run in separate threads to keep the UI 60fps smooth.
    - **Node.js Sidecar**: We spawn a Node.js child process to run Playwright/Puppeteer scripts. This offers superior browser automation capabilities (stealth, plugins) compared to pure Dart solutions.

## 2. Folder Structure

We adopt a **Feature-First** structure for scalability.

```
lib/
├── main.dart                  # Entry point
├── core/                      # Shared logic
│   ├── constants/
│   ├── theme/
│   ├── utils/                 # Logger, Helpers
│   └── errors/                # Failure classes
├── config/                    # Environment, Routes
├── data/                      # Data Layer
│   ├── datasources/           # Local (Isar), Remote (API)
│   ├── models/                # DTOs (Data Transfer Objects)
│   └── repositories/          # Repository Implementations
├── domain/                    # Domain Layer
│   ├── entities/              # Pure Dart Classes (Business Objects)
│   ├── repositories/          # Repository Interfaces
│   └── usecases/              # Business Logic Units
├── presentation/              # UI Layer
│   ├── providers/             # Riverpod Providers
│   ├── screens/               # Full Pages
│   └── widgets/               # Reusable Components
└── engine/                    # Automation Core
    ├── queue/                 # Task Queue Logic
    ├── isolates/              # Isolate Managers
    └── scripts/               # Embedded Node.js scripts
```

## 3. Core Modules Breakdown

1.  **Dashboard Module**: Project management, high-level stats.
2.  **Queue Engine Module**: The brain. detailed below.
3.  **Browser Manager Module**: Handles Chrome profiles, proxies, and cookies.
4.  **Media Processor Module**: FFmpeg wrappers for merging video/audio.
5.  **AI Connector Module**: API clients for Veo3, Gemini, ElevenLabs, etc.
6.  **Settings Module**: Global configuration (API keys, paths).

## 4. Task Queue Engine Design

We implement a **Priority Persistent Queue**.

-   **Persistence**: Tasks are saved to Isar immediately upon creation with status `pending`.
-   **Structure**:
    ```dart
    enum TaskStatus { pending, processing, completed, failed, retrying }
    enum TaskType { videoGen, imageGen, upscale, upload }
    
    class Task {
      Id id;
      TaskType type;
      int priority; // 0 = High, 10 = Low
      TaskStatus status;
      DateTime createdAt;
      Map<String, dynamic> payload; // JSON data for the task
      List<String> logs;
      int retryCount;
    }
    ```
-   **Execution**:
    -   A `QueueService` watches the Isar DB for `pending` tasks ordered by `priority`.
    -   It maintains a pool of `Worker` classes (mapped to Isolates).
    -   It dispatches tasks to available workers.
    -   On completion/failure, the worker updates the DB entry.

## 5. Multi-Browser Automation Architecture

We use a **Hybrid Approach**: Dart orchestrates, Node.js executes.

-   **Why Node.js?**: Playwright (Node) is the industry standard for stealth automation. Dart's `puppeteer` is good but lacks the ecosystem for evading bot detection.
-   **Communication**:
    -   Flutter spawns: `Process.start('node', ['script.js', '--profile', 'profile_1'])`.
    -   **Stdin/Stdout**: Flutter sends JSON commands to Node; Node sends JSON events back.
    -   **Example**: Flutter sends `{"action": "login", "url": "..."}` -> Node executes -> Node replies `{"status": "success", "cookies": [...]}`.

## 6. Chrome Profile Management Strategy

-   **Storage**: Profiles are stored in `~/Documents/VEOX/profiles/`.
-   **Isolation**: Each "Browser Profile" in the app corresponds to a distinct folder.
-   **Launch Args**:
    ```bash
    --user-data-dir="/Users/user/Documents/VEOX/profiles/profile_123"
    --no-first-run
    --no-default-browser-check
    ```
-   **Cookie Management**: We don't rely solely on Chrome's cookie jar. We export cookies to JSON in Isar after every successful session. This allows us to "restore" a session even if the profile folder is corrupted or moved.

## 7. Error Handling Strategy

-   **Retry Policy**: Exponential backoff.
    -   Attempt 1: Immediate.
    -   Attempt 2: Wait 30s.
    -   Attempt 3: Wait 5m.
    -   Attempt 4: Mark as `failed`.
-   **Circuit Breaker**: If 5 consecutive tasks fail (e.g., internet down), pause the queue automatically and notify user.
-   **Isolation**: A crash in a browser script (Node.js) should **never** crash the Flutter app. We catch the exit code of the subprocess and handle it gracefully.

## 8. Logging System Design

-   **Dual Logging**:
    1.  **Console (UI)**: ephemeral, for user feedback.
    2.  **File (Disk)**: structured, rotating logs for debugging.
-   **Structure**:
    ```text
    [2023-10-27 10:00:01] [INFO] [Queue] Starting Task #123
    [2023-10-27 10:00:05] [ERROR] [Browser] Timeout waiting for selector #login-btn
    ```
-   **Implementation**: Use `logger` package + custom `FileOutput`.

## 9. Data Models (Dart Classes)

See `lib/domain/entities/` for detailed breakdown. Key entities:
-   `Project`: Container for a batch of videos.
-   `VideoAsset`: Represents a single generated video (metadata, file path).
-   `BrowserProfile`: Metadata about a chrome profile (name, proxy, user-agent).
-   `AutomationScript`: Definition of a workflow (steps).

## 10. Scalability Strategy (1000+ Tasks)

-   **Database**: Isar handles 100k+ records easily.
-   **UI Virtualization**: Use `ListView.builder` for log/task lists. Never render all items at once.
-   **Batch Processing**: Don't load 1000 tasks into memory. Load them in pages (e.g., 50 at a time) from DB.
-   **Resource Management**: Limit concurrent browser instances based on RAM. (e.g., 1 Chrome = 500MB RAM. 16GB RAM = Max 20 concurrent tabs).

## 11. Security Considerations

-   **API Keys**: Store in `flutter_secure_storage` (Keychain/Keystore), NOT plain text Isar.
-   **Sandboxing**: Node.js scripts should run with limited permissions if possible (though tough on Desktop).
-   **Data Privacy**: All data is local. No cloud telemetry unless explicitly opted in.

## 12. Avoiding Memory Leaks

-   **Riverpod**: Use `.autoDispose` providers to kill state when UI screens are closed.
-   **Streams**: Always `cancel()` stream subscriptions in `dispose()`.
-   **Process Management**: Ensure `Process.kill()` is called on Node.js child processes when the app closes or the task is cancelled. **Orphaned chrome processes are the #1 cause of memory leaks in automation apps.**

## 13. Safe Crash Handling

-   **Global Error Boundary**: Wrap the app in `runZonedGuarded`.
-   **State Recovery**: Since the Queue is persistent (Isar), if the app crashes, on next launch:
    1.  Check DB for tasks with status `processing`.
    2.  Mark them as `failed` (crashed) or `retrying`.
    3.  Resume queue.

## 14. Background Processing Approach

-   **Desktop Lifecycle**: On Windows/macOS, "background" usually means the window is minimized.
-   **Isolates**: Use `Isolate.spawn` for the Queue Engine. This ensures that even if the UI thread is blocked (e.g., resizing window), the automation logic keeps running.
-   **System Tray**: Minimize to system tray to keep the app "alive" without a taskbar presence.
