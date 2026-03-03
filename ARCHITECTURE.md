# ARCHITECTURE.md — VEOX (Flutter Desktop + Node Playwright, Cost-Zero)

## 0) Non-Negotiables (Hard Rules)
- **NO paid APIs** (no OpenAI/Claude/ElevenLabs/Replicate/Suno/Udio, etc).
- **No server**. Everything runs on the user’s machine.
- **Offline-first**: local storage (Isar) + local file outputs.
- Automation uses **browser UI automation** (Playwright) and/or **local tools** (ffmpeg, OS TTS).
- Must run on **low-end machines**: default concurrency = 1 for browser tasks.
- Must be **debuggable**: structured logs, replayable tasks, deterministic outputs.

---

## 1) System Overview

VEOX is a Flutter Desktop app (Windows/macOS) that orchestrates bulk automation jobs:
- User prepares prompts/scenes/projects in UI
- Queue schedules tasks locally
- Node Playwright engine runs workflows in a real browser session
- Outputs are downloaded to deterministic folders
- Progress & logs stream back to UI

### High-level Diagram
┌───────────────────────────────┐
│ Flutter Desktop UI │
│ Pages + Widgets (already UI) │
└──────────────┬────────────────┘
│ (State updates)
┌──────────────▼────────────────┐
│ App Core (Flutter) │
│ - Task Queue Engine │
│ - Local Storage (Isar) │
│ - Output Manager │
│ - Logs / Terminal Panel │
└──────────────┬────────────────┘
│ stdin/stdout NDJSON (JSON-RPC-ish)
┌──────────────▼────────────────┐
│ Node Automation Engine │
│ - Playwright persistent ctx │
│ - Workflow modules │
│ - Download manager │
│ - Event streaming (progress) │
└──────────────┬────────────────┘
│ Files
┌──────────────▼────────────────┐
│ Local Output Folder │
│ - projects/.../videos │
│ - projects/.../screenshots │
│ - logs │
│ - profiles (browser data) │
└───────────────────────────────┘

---

## 2) IPC Protocol (Flutter ↔ Node)

### Transport
- Node process is launched by Flutter.
- Messages are **newline-delimited JSON** (NDJSON) over stdin/stdout.
- Two types of messages:
  1) **Request/Response** (correlated by `id`)
  2) **Events** (streamed progress/log events, correlated by `jobId`)

### Request (Flutter → Node)
```json
{
  "id": "uuid-123",
  "command": "job_start",
  "params": {
    "jobId": "task-001",
    "profileId": "default",
    "type": "generate_video",
    "payload": {
      "platform": "veo_web",
      "prompt": "A cyberpunk city in rain",
      "ratio": "16:9",
      "upscale": "1080p",
      "outputDir": "/.../projects/p1/videos"
    }
  }
}
Response (Node → Flutter)

Success:

{ "id": "uuid-123", "type": "result", "status": "success", "data": { "outputPath": "/.../task-001.mp4" } }

Error:

{ "id": "uuid-123", "type": "result", "status": "error", "error": "Timeout while waiting for download" }
Event (Node → Flutter)
{ "type": "event", "jobId": "task-001", "event": "progress", "pct": 35, "stage": "polling" }
{ "type": "event", "jobId": "task-001", "event": "log", "level": "info", "message": "Found download button" }
{ "type": "event", "jobId": "task-001", "event": "needs_login", "profileId": "default" }
Cancellation

Flutter:

{ "id": "uuid-999", "command": "job_cancel", "params": { "jobId": "task-001" } }

Node must stop gracefully and emit final result as canceled.

3) Core Components (Flutter)
3.1 Task Queue Engine (Local Orchestrator)

Responsibilities:

Pull eligible tasks from Isar

Enforce concurrency limits:

Browser pool default: 1

Local pool optional: 2

Handle lifecycle:

pending → running → completed/failed

retrying with exponential backoff + jitter

pause/resume/cancel

Idempotency:

deterministic output path per task

skip if output already exists & valid

3.2 Storage (Isar)

Projects

Scenes

Tasks (queue + history)

Accounts/Profiles (metadata only, NO passwords)

Logs (structured)

3.3 Output Manager

Folder layout (suggested):

Documents/VEOX/
  projects/{projectId}/
    videos/
    images/
    screenshots/
    exports/
  logs/
  profiles/{profileId}/   (browser userDataDir)
4) Node Automation Engine
4.1 Browser Strategy (Persistent Profiles)

Use launchPersistentContext(userDataDir) per profile.

Login is done manually by the user once; automation detects login state.

No password storage in app.

4.2 Workflow Modules

Workflows are modular, platform-specific where necessary, but share a common interface.

Common stages:

open_browser(profile)

navigate(platformUrl)

login_detect()

input_prompt()

submit_generate()

poll_result()

download_artifact_atomic()

return outputPath

4.3 Download Manager (Atomic + Deterministic)

Always download to {outputDir}/{jobId}.partial

After successful completion, rename to {outputDir}/{jobId}.mp4

Prevent duplicates:

if {jobId}.mp4 exists and size > threshold → treat as completed

4.4 Local Post-Processing (Optional)

ffmpeg wrapper for:

mix background music

concatenate

normalize audio

OS TTS wrapper (optional):

macOS: say

Windows: PowerShell SAPI

Output WAV/MP3 locally

5) Security & Compliance

No secrets shipped.

No storing passwords.

Automation must respect platform constraints and user consent.

“Clone YouTube” feature must avoid ToS-violating automation.

Prefer: user-provided transcript / user-owned assets / export links.

Provide clear warnings in UI.

6) Observability & Debuggability

Every job emits:

progress events

structured logs (timestamp, level, jobId)

Flutter “Terminal” panel:

live logs

filter by scope/jobId

export logs

7) Packaging Notes

Node engine is bundled with the app or required as external dependency.

Prefer simplest first:

Dev mode: Node installed locally

Later: ship Node runtime (more complex)