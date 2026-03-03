
---

# VEOX — Offline AI Video Automation (Flutter Desktop + Node Playwright)

VEOX is a **local-first** Flutter Desktop application for orchestrating **bulk browser automation jobs** (no paid APIs, no server).
It turns UI-based generation platforms into a repeatable, debuggable pipeline via Playwright automation.

## Key Principles
- **Cost-zero mindset**: no paid APIs required.
- **Offline-first**: Isar DB + local outputs.
- **Automation engine**: Node.js + Playwright (persistent browser profiles).
- **Debuggable**: structured logs + task history + deterministic output paths.
- **Low-end friendly**: browser concurrency default = 1.

## What It Does (MVP)
- Projects → Scenes → Tasks
- Queue runs tasks locally
- Node engine opens browser profiles, runs workflow, downloads output
- UI shows task progress + logs

## Setup (Dev)
### Requirements
- Flutter SDK (stable)
- Node.js (LTS recommended)
- Playwright dependencies for your OS

### Install
1) Flutter deps:
```bash
cd veox_flutter
flutter pub get