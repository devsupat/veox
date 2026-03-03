# 🤖 CURSOR MASTER PROMPTS — VEOX (Flutter Desktop + Node Playwright)

## HOW WE WORK
- UI is already built. **Do NOT redesign UI**.
- Make the app functional by wiring real logic behind existing buttons.
- **NO paid APIs. No server.**
- Always produce:
  1) FILE_TREE (relevant)
  2) PATCHES (minimal diffs)
  3) RUN_INSTRUCTIONS
  4) POST_TASK_CHECKS

---

## PROMPT 0 — CONTEXT SETUP (PASTE FIRST)
```text
You are a senior Flutter Desktop + Node.js Playwright engineer.

Project: VEOX (Flutter Desktop Windows/macOS). The UI is already complete.
Goal: Make the UI functional using a local Task Queue + Node Playwright automation engine (subprocess).

HARD RULES:
- NO paid APIs (no OpenAI/Claude/ElevenLabs/Replicate/Suno/Udio, etc).
- No server. Everything runs on user machine.
- Offline-first storage with Isar (or local JSON as fallback).
- Node engine communicates with Flutter via newline-delimited JSON over stdin/stdout.
- Implement a robust Task Queue: concurrency limit, retry exponential backoff, pause/resume/cancel, idempotent downloads, progress streaming.
- Do not store passwords. Login is manual with persistent browser profiles.

PROCESS:
1) Read ARCHITECTURE.md and PLAN.md (VEOX versions).
2) Scan existing code for NodeService/subprocess wiring and Isar models.
3) Implement only missing pieces. Avoid unnecessary refactors.
4) Keep UI intact (only wire events/state).

OUTPUT FORMAT REQUIRED EACH STEP:
- FILE_TREE (relevant parts only)
- PATCHES (minimal diffs)
- RUN_INSTRUCTIONS
- POST_TASK_CHECKS

Implement TaskQueueService to run local tasks stored in Isar.

Requirements:
- Browser concurrency default = 1
- Retry exponential backoff + jitter
- Pause/resume queue and cancel task
- Idempotency: deterministic output path per task; skip if output already exists and valid
- Stream progress to UI (per task + global counters)

Do NOT change UI layout. Only wire providers/state.

Standardize IPC protocol between Flutter and Node:
- Requests/responses correlated by `id`
- Events streamed with `type:event` and `jobId`

Implement:
- Flutter: parse event messages and route to queue/progress
- Node: helper to emit progress/log/needs_login events
- Add job_cancel support

Implement minimal workflow end-to-end:
- Open persistent browser profile
- Navigate to a URL
- Detect login page and emit needs_login
- Take screenshot and return output path

Wire it to an existing button (e.g. "Connect Browser" or "Login") without changing UI design.

Implement generate_video workflow for ONE platform (choose the one already used in UI).
Must:
- Use persistent context profile
- Detect login and pause task until user completes login
- Submit prompt, poll for completion, then download atomically to {outputDir}/{jobId}.mp4
- Emit progress events and structured logs
- Return outputPath

From Scene Builder, create many tasks into the queue.
Support:
- From/To range
- Batch size
- Skip mode (skip tasks already done)
- Retry button re-queues failed tasks

Update status counters panel from real data.

Node engine deps:

cd veox_flutter/engine
npm install
npx playwright install
Run
cd veox_flutter
flutter run -d macos
# or
flutter run -d windows
Output Folder

Defaults to Documents/VEOX/:

projects/{projectId}/videos

projects/{projectId}/screenshots

logs/

profiles/{profileId}/ (browser data)

Security

No passwords are stored.

Browser login is manual using persistent profiles.

Notes on Compliance

Some “content extraction” ideas can violate platform terms.
This project should be used responsibly:

Prefer user-owned content and user-provided transcripts/assets.

Avoid unauthorized scraping/redistribution.

Troubleshooting

If Node engine fails to start: verify Node is installed and engine path is correct.

If Playwright errors: run npx playwright install and ensure OS dependencies are present.

For debugging: open Logs/Terminal panel and export logs.