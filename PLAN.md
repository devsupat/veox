
---

# 2) PLAN.md (REPLACE FULL FILE)

```md
# PLAN.md — VEOX (Make UI “Alive”)

## 0) Objective
Turn the already-built Flutter Desktop UI into a functional **offline-first automation product**:
- One-click bulk tasks (“1 click = many jobs”)
- Local queue with retries & pause/resume
- Node Playwright automation engine
- Deterministic downloads and outputs
- Zero paid APIs

---

## 1) Hard Constraints
- No paid APIs; no server.
- Runs on low-end devices; browser concurrency default = 1.
- Debuggable: logs, deterministic output paths, replayable tasks.
- Policy-safe: no gray-area automation; user consent; avoid ToS violations.

---

## 2) Scope Mapping to Current UI Tabs (Keep UI, Wire Logic)
- **Home**: projects list, recent outputs, queue summary, multi-browser status
- **Character Studio**: prompt/template builder → generates JSON payloads (offline)
- **Scene Builder**: parse JSON → create scenes → create tasks in queue
- **Clone YouTube**: safest implementation first (manual transcript import / user-provided data)
- **Mastering / Reels / AV Match**: local processing pipelines (ffmpeg placeholders first)
- **Settings**: output dirs, profiles, concurrency, debug toggles
- **Export**: zip/export project outputs + logs

---

## 3) Phased Roadmap (Execution Order)

### Phase 0 — Repo Hygiene & Contracts (1–2 days)
Deliverables:
- Rewrite docs to VEOX (ARCHITECTURE/PLAN/README/CURSOR_PROMPTS)
- Define IPC message contract (request/response/events)
- Remove/disable old “paid API” assumptions from codepaths

### Phase 1 — Storage & Queue Foundation (2–4 days)
Deliverables:
- Isar collections for: Project, Scene, Task, LogEntry, Profile
- TaskQueueService:
  - concurrency limit (browser pool = 1)
  - retry w/ exponential backoff + jitter
  - pause/resume/cancel
  - idempotent output logic
- UI wiring:
  - status counters update from actual tasks (Total/Done/Active/Failed)
  - “Processing Queue” panel reflects real queue states

### Phase 2 — Node Engine Hardening + Minimal Workflow (2–4 days)
Deliverables:
- Node router supports:
  - job_start / job_cancel
  - event streaming (progress/log/needs_login)
- Minimal “golden path” workflow:
  - open browser profile
  - navigate to website
  - detect login
  - take screenshot
  - return output path
- Flutter wiring:
  - engine connect/disconnect status
  - login-required UX (button opens interactive browser)

### Phase 3 — Bulk Generation Workflow (3–7 days)
Deliverables:
- Implement 1 platform workflow end-to-end (stable):
  - prompt → generate → poll → download atomic
- Scene Builder creates tasks in bulk:
  - from range (From/To)
  - batch size
  - skip mode
- Progress reporting per task + global progress bar

### Phase 4 — Quality & Reliability (3–7 days)
Deliverables:
- Download manager improvements
- Robust selector strategy + timeouts
- Better error classification:
  - retryable vs non-retryable
- Export:
  - export project outputs + JSON + logs
- Performance hardening for low-end machines

### Phase 5 — Packaging Windows/macOS (timeboxed)
Deliverables:
- Standard build steps
- Bundle engine assets / configure pathing
- Smoke tests checklist

---

## 4) Definition of Done (MVP)
- User can create/open a project
- Paste prompts/JSON → scenes created
- Click Generate → tasks queued and executed
- Browser opens with profile; login handled; downloads saved to deterministic paths
- UI shows real progress, tasks history, and logs
- Works without paid APIs and without server