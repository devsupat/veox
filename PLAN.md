# PLAN.md — AI Creative Studio (Flutter Desktop)

## 🎯 Tujuan Proyek
Menghidupkan Flutter Desktop App yang sudah memiliki UI lengkap menjadi aplikasi fungsional penuh, dengan backend logic untuk:
- AI Image Generation (Character + Scene)
- YouTube Clone via transcript scraping
- AI Voice & Music generation
- Video assembly & mastering
- Headless browser automation (Veo3/Grok via Google Labs)

---

## 📅 Development Phases

### PHASE 1 — Foundation & State Management (Week 1)
**Goal:** Setup arsitektur, dependency injection, dan state management seluruh modul.

- [ ] Setup `Riverpod` atau `Bloc` sebagai state manager global
- [ ] Setup `Hive` atau `Isar` untuk local database (projects, scenes, characters)
- [ ] Setup `dio` + interceptor untuk HTTP client (API calls)
- [ ] Setup `flutter_secure_storage` untuk menyimpan API keys
- [ ] Buat `AppRouter` dengan `go_router`
- [ ] Buat `SettingsService` untuk manage Google/API credentials
- [ ] Buat model data: `Project`, `Character`, `Scene`, `Prompt`, `VideoAsset`

**Deliverable:** App bisa menyimpan/load project, settings tersimpan persistent.

---

### PHASE 2 — Character Studio (Week 2)
**Goal:** Generate karakter dengan konsistensi seed/reference image.

- [ ] Integrasi **Stable Diffusion API** (via `stable-diffusion-webui` REST atau Replicate API)
  - Endpoint: `/sdapi/v1/txt2img` dengan parameter `seed` tetap
  - Support `ControlNet` untuk reference image consistency
- [ ] Integrasi **Replicate API** sebagai alternatif (model: `stability-ai/sdxl`)
- [ ] UI logic: tombol Generate → call API → tampilkan hasil di grid
- [ ] Fitur seed lock: simpan seed per karakter
- [ ] Fitur reference image: upload gambar → encode base64 → kirim sebagai `init_image`
- [ ] Simpan karakter ke local DB dengan thumbnail

**Service:** `CharacterService`, `ImageGenerationService`

---

### PHASE 3 — Scene Builder (Week 2-3)
**Goal:** Teks cerita → JSON scenes → visual prompts → generate gambar per scene.

- [ ] Integrasi **Claude API** atau **OpenAI GPT-4** untuk:
  - Parse teks cerita → ekstrak karakter
  - Generate visual prompt per scene (format sinematik)
  - Output: JSON `{scene_number, description, characters[], prompt, camera_angle}`
- [ ] Auto-detect karakter di setiap scene → match dengan Character Studio
- [ ] Generate semua scene sekaligus (parallel API calls dengan `Future.wait`)
- [ ] Drag & drop karakter ke scene untuk replace
- [ ] Import gambar eksternal sebagai scene asset
- [ ] Regenerate scene individual

**Service:** `SceneBuilderService`, `LLMService`, `PromptParserService`

---

### PHASE 4 — YouTube Clone (Week 3)
**Goal:** URL YouTube → transkrip → prompts → generate ulang konten.

- [ ] Integrasi **YouTube Transcript API** (via `youtube_transcript_api` Python bridge atau REST wrapper)
  - Alternatif: `yt-dlp` untuk download subtitle
  - Gunakan `dart:io` `Process.run` untuk eksekusi yt-dlp
- [ ] Parse transkrip → kirim ke LLM → generate visual prompts
- [ ] Extract thumbnail/keyframe dari video (opsional, via ffmpeg)
- [ ] Copy prompts ke clipboard / kirim ke Home Screen
- [ ] Load scenes otomatis dari prompts hasil clone

**Service:** `YouTubeCloneService`, `TranscriptService`

---

### PHASE 5 — Headless Browser Automation (Week 3-4)
**Goal:** Auto-login dan generate via Veo3 (Google Labs) & Grok.

- [ ] Embed **`webview_flutter`** atau launch external Chromium via `puppeteer` (Node.js subprocess)
- [ ] Strategi: Flutter spawn Node.js process yang jalankan Puppeteer script
  - Script: auto-login Google → navigate ke labs.google.com/veo → inject prompt → trigger generate → polling result
- [ ] Alternatif ringan: `flutter_inappwebview` + JavaScript injection
- [ ] Untuk Grok: navigate ke `x.ai/grok` → inject prompt via JS
- [ ] Simpan session cookies untuk re-use login
- [ ] Queue system: antrian prompt → generate satu per satu otomatis
- [ ] Status monitoring: polling setiap N detik untuk cek hasil

**Service:** `BrowserAutomationService`, `Veo3Service`, `GrokService`

---

### PHASE 6 — AI Voice & Music (Week 4)
**Goal:** TTS unlimited + background music generator.

- [ ] Integrasi **ElevenLabs API** untuk TTS
  - Endpoint: `POST /v1/text-to-speech/{voice_id}`
  - Voice cloning support
- [ ] Alternatif TTS: **OpenAI TTS API** (`tts-1` model)
- [ ] Integrasi **Suno API** atau **Udio API** untuk music generation
  - Atau: **MusicGen** via Replicate
- [ ] Bulk generation: generate voice untuk semua scenes sekaligus
- [ ] Audio player preview in-app
- [ ] Export audio files ke folder project

**Service:** `TTSService`, `MusicGenerationService`, `AudioPlayerService`

---

### PHASE 7 — Video Mastering (Week 5)
**Goal:** Gabungkan gambar/video + audio + logo → export video final.

- [ ] Integrasi **`ffmpeg`** via `flutter_ffmpeg` atau `ffmpeg_kit_flutter`
  - Gabungkan image sequence → video
  - Overlay audio track
  - Burn subtitle/text overlay
  - Add logo watermark
- [ ] Import video clips dari file system
- [ ] Generate background music untuk video (auto-detect scene dari metadata)
- [ ] Simple timeline editor (drag reorder clips)
- [ ] Export preset: 1080p, 4K, Reels (9:16), YouTube (16:9)
- [ ] Bulk upscale via **Real-ESRGAN** (Replicate API atau local)

**Service:** `VideoMasteringService`, `FFmpegService`, `UpscalerService`

---

### PHASE 8 — Reels & Bulk Export (Week 5-6)
**Goal:** Template-based bulk reel creator.

- [ ] Template system: simpan konfigurasi reusable (aspect ratio, music, logo, font)
- [ ] Bulk create: apply template ke multiple scenes
- [ ] One-click export semua video
- [ ] Progress tracking per video
- [ ] Output folder manager

---

### PHASE 9 — Polish & Integration (Week 6)
- [ ] Error handling menyeluruh + retry logic
- [ ] Progress indicators semua long-running tasks
- [ ] Notification saat generate selesai
- [ ] API key validator di settings
- [ ] Log viewer untuk debug automation
- [ ] Auto-save project state

---

## 🔑 API Keys yang Dibutuhkan
| Service | Provider | Keterangan |
|---|---|---|
| Image Generation | Replicate / SD WebUI | Character & Scene |
| LLM (Story Parse) | OpenAI / Anthropic | Scene Builder |
| TTS | ElevenLabs / OpenAI | Voice generation |
| Music | Suno / Replicate MusicGen | Background music |
| Video Upscale | Replicate Real-ESRGAN | Bulk upscale |
| YouTube | yt-dlp (local tool) | Transcript clone |
| Browser Auto | Puppeteer/Node.js (local) | Veo3 & Grok |

---

## 📦 Dependency List (pubspec.yaml additions)
```yaml
dependencies:
  # State Management
  flutter_riverpod: ^2.5.1
  riverpod_annotation: ^2.3.5
  
  # Navigation
  go_router: ^13.2.0
  
  # HTTP & API
  dio: ^5.4.3
  retrofit: ^4.1.0
  
  # Local Storage
  isar: ^3.1.0
  isar_flutter_libs: ^3.1.0
  flutter_secure_storage: ^9.0.0
  
  # File & Media
  file_picker: ^8.0.0
  path_provider: ^2.1.3
  ffmpeg_kit_flutter: ^6.0.3
  
  # WebView & Browser
  flutter_inappwebview: ^6.0.0
  
  # Audio
  just_audio: ^0.9.39
  audioplayers: ^6.0.0
  
  # Image
  image: ^4.1.7
  cached_network_image: ^3.3.1
  
  # Utils
  uuid: ^4.4.0
  intl: ^0.19.0
  logger: ^2.3.0
  
dev_dependencies:
  riverpod_generator: ^2.3.11
  build_runner: ^2.4.9
  retrofit_generator: ^8.1.0
```
