# VEOX Development Roadmap

## Phase 1: Foundation & Core UI (Weeks 1-3)
**Goal**: Establish the app shell, database, and basic task management.

- [ ] **Project Setup**:
    - [x] Flutter Desktop structure (MacOS/Windows).
    - [x] State Management (Riverpod).
    - [ ] Local Database (Isar) schema design.
    - [ ] Logging system (File + Console).
- [ ] **UI Implementation**:
    - [x] Main Layout (Sidebar, Tabs).
    - [x] Dashboard (Projects, Stats).
    - [ ] Task Queue View (List of pending/active/completed tasks).
    - [ ] Settings Page (API Keys, Paths).
- [ ] **Task Queue Engine (v1)**:
    - [ ] Basic `QueueService` with Isar.
    - [ ] Add/Remove/Retry tasks manually.
    - [ ] Simple "Mock" execution (wait 5s, success).

## Phase 2: Automation Core & Browser Management (Weeks 4-6)
**Goal**: Enable the app to control Chrome browsers via Node.js.

- [ ] **Node.js Integration**:
    - [ ] Create `engine/` directory with `package.json`.
    - [ ] Install Playwright/Puppeteer.
    - [ ] Implement `Process.start` wrapper in Dart to spawn Node scripts.
    - [ ] Define JSON-RPC protocol for Dart <-> Node communication.
- [ ] **Browser Profile Manager**:
    - [ ] UI to create/delete profiles (name, user-agent, proxy).
    - [ ] Logic to launch Chrome with specific `--user-data-dir`.
    - [ ] "Manual Login" mode (User logs in, cookies saved).
    - [ ] "Auto Login" script (Using saved credentials).

## Phase 3: AI Integration & Generation Logic (Weeks 7-9)
**Goal**: Connect to external AI services and generate actual content.

- [ ] **Veo3 Integration**:
    - [ ] Script to automate Veo3 video generation/download.
    - [ ] Handle quotas and errors.
- [ ] **Image Generation**:
    - [ ] Integration with Whisk/Midjourney (via Discord automation or API).
    - [ ] Bulk prompt processing.
- [ ] **Voice Generation**:
    - [ ] ElevenLabs/Gemini TTS API integration.
    - [ ] Audio file management (saving .wav/.mp3).
- [ ] **Media Processing**:
    - [ ] FFmpeg integration for merging video + audio.
    - [ ] Background music overlay.

## Phase 4: The "1000 Video" Engine (Weeks 10-12)
**Goal**: Scale up stability and concurrency.

- [ ] **Concurrency Control**:
    - [ ] Implement `Semaphore` to limit active browser instances (e.g., Max 5).
    - [ ] Resource monitoring (RAM/CPU usage).
- [ ] **Error Recovery System**:
    - [ ] Automatic retry logic for network failures.
    - [ ] Circuit breaker for API limits.
    - [ ] "Resume" functionality after app crash.
- [ ] **Bulk Tools**:
    - [ ] CSV Import/Export for prompts.
    - [ ] "Batch Edit" for task settings.
    - [ ] Upscaling pipeline integration.

## Phase 5: Polish, Distribution & Monetization (Weeks 13+)
**Goal**: Prepare for public release.

- [ ] **Security**:
    - [ ] Encrypt sensitive data (API keys, passwords).
    - [ ] Code obfuscation.
- [ ] **Distribution**:
    - [ ] Auto-updater implementation.
    - [ ] Licensing system (Key validation).
    - [ ] Installers (DMG, EXE, MSI).
- [ ] **Optimization**:
    - [ ] Reduce memory footprint.
    - [ ] Improve startup time.
    - [ ] extensive testing on Windows and macOS.
