# ARCHITECTURE.md — AI Creative Studio (Flutter Desktop)

## 🏗️ Arsitektur Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    PRESENTATION LAYER                        │
│   Screens / Pages / Widgets (UI sudah ada, tinggal wire)    │
└────────────────────────┬────────────────────────────────────┘
                         │ watches/reads
┌────────────────────────▼────────────────────────────────────┐
│                   STATE LAYER (Riverpod)                     │
│   Providers / Notifiers / AsyncNotifiers per module          │
└────────────────────────┬────────────────────────────────────┘
                         │ calls
┌────────────────────────▼────────────────────────────────────┐
│                  DOMAIN / USE CASE LAYER                     │
│   Services: Business logic, orchestration antar API          │
└──────┬─────────────┬──────────────┬──────────────┬──────────┘
       │             │              │              │
┌──────▼──┐   ┌──────▼──┐   ┌──────▼──┐   ┌──────▼──────────┐
│  API    │   │  Local  │   │ Process │   │   WebView/      │
│ Clients │   │   DB    │   │ Runner  │   │   Browser       │
│  (dio)  │   │ (Isar)  │   │(ffmpeg/ │   │  Automation     │
│         │   │         │   │ yt-dlp) │   │  (Puppeteer)    │
└─────────┘   └─────────┘   └─────────┘   └─────────────────┘
```

---

## 📁 Struktur Folder

```
lib/
├── main.dart
├── app.dart                          # MaterialApp + Router setup
│
├── core/
│   ├── constants/
│   │   ├── api_constants.dart        # Base URLs, endpoints
│   │   └── app_constants.dart        # App-wide constants
│   ├── errors/
│   │   ├── failures.dart             # Failure types (NetworkFailure, etc.)
│   │   └── exceptions.dart
│   ├── network/
│   │   ├── dio_client.dart           # Dio instance + interceptors
│   │   └── api_interceptor.dart      # Auth header injection
│   ├── storage/
│   │   ├── isar_service.dart         # Isar DB singleton
│   │   └── secure_storage_service.dart # API keys storage
│   ├── process/
│   │   ├── process_runner.dart       # dart:io Process wrapper
│   │   └── ffmpeg_runner.dart        # FFmpeg command builder
│   └── utils/
│       ├── file_utils.dart
│       ├── image_utils.dart
│       └── logger.dart
│
├── models/                           # Data models (Isar collections)
│   ├── project.dart                  # @Collection Project
│   ├── character.dart                # @Collection Character
│   ├── scene.dart                    # @Collection Scene
│   ├── prompt.dart                   # @Collection Prompt
│   ├── voice_asset.dart              # @Collection VoiceAsset
│   ├── video_asset.dart              # @Collection VideoAsset
│   └── api_config.dart               # @Collection ApiConfig
│
├── features/
│   │
│   ├── settings/
│   │   ├── data/
│   │   │   └── settings_repository.dart
│   │   ├── domain/
│   │   │   └── settings_service.dart
│   │   └── presentation/
│   │       ├── settings_screen.dart  # (UI sudah ada)
│   │       └── providers/
│   │           └── settings_provider.dart
│   │
│   ├── character_studio/
│   │   ├── data/
│   │   │   ├── image_generation_client.dart  # Replicate/SD API
│   │   │   └── character_repository.dart
│   │   ├── domain/
│   │   │   └── character_service.dart
│   │   └── presentation/
│   │       ├── character_studio_screen.dart  # (UI sudah ada)
│   │       └── providers/
│   │           ├── character_provider.dart
│   │           └── generation_state.dart
│   │
│   ├── scene_builder/
│   │   ├── data/
│   │   │   ├── llm_client.dart               # OpenAI/Claude API
│   │   │   └── scene_repository.dart
│   │   ├── domain/
│   │   │   ├── scene_builder_service.dart
│   │   │   ├── prompt_parser_service.dart    # Story → JSON scenes
│   │   │   └── character_detector_service.dart
│   │   └── presentation/
│   │       ├── scene_builder_screen.dart     # (UI sudah ada)
│   │       └── providers/
│   │           ├── scene_builder_provider.dart
│   │           └── scene_state.dart
│   │
│   ├── youtube_clone/
│   │   ├── data/
│   │   │   ├── ytdlp_client.dart             # yt-dlp Process runner
│   │   │   └── transcript_repository.dart
│   │   ├── domain/
│   │   │   ├── youtube_clone_service.dart
│   │   │   └── transcript_parser_service.dart
│   │   └── presentation/
│   │       ├── youtube_clone_screen.dart     # (UI sudah ada)
│   │       └── providers/
│   │           └── youtube_clone_provider.dart
│   │
│   ├── browser_automation/
│   │   ├── data/
│   │   │   ├── puppeteer_bridge.dart         # Node.js subprocess bridge
│   │   │   └── webview_controller.dart       # flutter_inappwebview wrapper
│   │   ├── domain/
│   │   │   ├── browser_automation_service.dart
│   │   │   ├── veo3_service.dart
│   │   │   └── grok_service.dart
│   │   └── presentation/
│   │       ├── browser_screen.dart           # (UI sudah ada)
│   │       └── providers/
│   │           └── browser_provider.dart
│   │
│   ├── ai_voice_music/
│   │   ├── data/
│   │   │   ├── elevenlabs_client.dart        # ElevenLabs TTS API
│   │   │   ├── openai_tts_client.dart        # OpenAI TTS API
│   │   │   └── music_gen_client.dart         # Replicate MusicGen
│   │   ├── domain/
│   │   │   ├── tts_service.dart
│   │   │   └── music_generation_service.dart
│   │   └── presentation/
│   │       ├── ai_voice_screen.dart          # (UI sudah ada)
│   │       └── providers/
│   │           └── voice_music_provider.dart
│   │
│   ├── video_mastering/
│   │   ├── data/
│   │   │   ├── ffmpeg_video_client.dart      # ffmpeg_kit wrapper
│   │   │   └── upscaler_client.dart          # Real-ESRGAN via Replicate
│   │   ├── domain/
│   │   │   ├── video_mastering_service.dart
│   │   │   ├── ffmpeg_command_builder.dart
│   │   │   └── upscaler_service.dart
│   │   └── presentation/
│   │       ├── video_mastering_screen.dart   # (UI sudah ada)
│   │       └── providers/
│   │           └── video_mastering_provider.dart
│   │
│   └── reels/
│       ├── data/
│       │   └── template_repository.dart
│       ├── domain/
│       │   ├── reel_template_service.dart
│       │   └── bulk_export_service.dart
│       └── presentation/
│           ├── reels_screen.dart             # (UI sudah ada)
│           └── providers/
│               └── reels_provider.dart
│
└── router/
    └── app_router.dart                       # go_router config
```

---

## 🔄 Data Flow per Fitur

### Character Studio Flow
```
UI: GenerateButton.onTap()
  → CharacterNotifier.generateCharacter(prompt, seed)
    → CharacterService.generate(params)
      → ImageGenerationClient.txt2img(prompt, seed, referenceImage?)
        → Replicate API / SD WebUI API
      ← GeneratedImage(url, seed, metadata)
    → CharacterRepository.save(character)
      → Isar DB
    ← Character model
  ← state = AsyncData(characters)
← UI rebuild dengan gambar baru
```

### Scene Builder Flow
```
UI: ParseStoryButton.onTap()
  → SceneBuilderNotifier.parseStory(storyText)
    → LLMService.extractCharactersAndScenes(storyText)
      → OpenAI/Claude API (structured output JSON)
      ← {characters: [], scenes: [{scene_num, desc, prompt, chars}]}
    → CharacterDetectorService.matchWithExisting(characters)
    → SceneRepository.saveAll(scenes)
  ← state = AsyncData(scenes)

UI: GenerateAllScenesButton.onTap()
  → SceneBuilderNotifier.generateAllScenes()
    → Future.wait(scenes.map((s) => 
        ImageGenerationClient.txt2img(s.prompt, s.seed)))
    → parallel generation (5 at a time with throttle)
  ← state update incremental per scene selesai
```

### YouTube Clone Flow
```
UI: StartCloneButton.onTap(youtubeUrl)
  → YouTubeCloneNotifier.clone(url)
    → YtDlpClient.getTranscript(url)
      → Process.run('yt-dlp', ['--write-subs', url])
      ← transcript text
    → LLMService.transcriptToPrompts(transcript)
      → Claude/GPT API
      ← [{scene_num, visual_prompt, duration}]
    → PromptRepository.saveAll(prompts)
  ← state = AsyncData(prompts)
  → UI: tampilkan prompts, tombol "Copy All" & "Send to Home"
```

### Browser Automation Flow (Veo3 / Grok)
```
UI: StartAutomationButton.onTap()
  → BrowserAutomationNotifier.startSession(platform, prompts)
    → BrowserAutomationService.initialize(platform)
      → OPTION A: flutter_inappwebview
        → InAppWebViewController.loadUrl(platformUrl)
        → injectJavaScript(loginScript)
      → OPTION B: Puppeteer subprocess
        → Process.start('node', ['puppeteer_bridge.js', ...args])
        → listen stdout untuk status updates
    → for each prompt in queue:
        → BrowserAutomationService.submitPrompt(prompt)
        → poll result setiap 10 detik
        → download result ke local storage
  ← state update: progress, status per prompt
```

---

## 🌐 External API Reference

### Replicate API (Image Generation)
```dart
// POST https://api.replicate.com/v1/predictions
{
  "version": "stability-ai/sdxl:...",
  "input": {
    "prompt": "...",
    "seed": 42,
    "image": "data:image/png;base64,..." // optional ControlNet
  }
}
```

### OpenAI API (LLM + TTS)
```dart
// Chat: POST https://api.openai.com/v1/chat/completions
// TTS:  POST https://api.openai.com/v1/audio/speech
{
  "model": "gpt-4o",
  "response_format": { "type": "json_object" },
  "messages": [{"role": "user", "content": "..."}]
}
```

### ElevenLabs API (TTS)
```dart
// POST https://api.elevenlabs.io/v1/text-to-speech/{voice_id}
{
  "text": "...",
  "model_id": "eleven_multilingual_v2",
  "voice_settings": {"stability": 0.5, "similarity_boost": 0.75}
}
```

### FFmpeg Commands
```dart
// Image sequence → video
'ffmpeg -framerate 24 -i scene_%03d.png -c:v libx264 output.mp4'

// Add audio
'ffmpeg -i video.mp4 -i audio.mp3 -shortest output_with_audio.mp4'

// Add logo watermark
'ffmpeg -i video.mp4 -i logo.png -filter_complex "overlay=10:10" output.mp4'

// Concatenate clips
'ffmpeg -f concat -safe 0 -i filelist.txt -c copy output.mp4'
```

### Puppeteer Bridge (Node.js subprocess)
```javascript
// puppeteer_bridge.js
// Dipanggil dari Flutter via: Process.start('node', ['puppeteer_bridge.js'])
// Komunikasi via stdin/stdout JSON messages
// { "action": "login", "platform": "veo3", "cookies": "..." }
// { "action": "submit_prompt", "prompt": "...", "index": 0 }
// stdout: { "status": "generating", "index": 0, "progress": 50 }
// stdout: { "status": "done", "index": 0, "url": "https://..." }
```

---

## 🗄️ Database Schema (Isar)

```dart
@Collection()
class Project {
  Id id = Isar.autoIncrement;
  late String name;
  late String description;
  late DateTime createdAt;
  final characters = IsarLinks<Character>();
  final scenes = IsarLinks<Scene>();
}

@Collection()
class Character {
  Id id = Isar.autoIncrement;
  late String name;
  late String imageUrl;     // local path
  late String imagePath;
  late int seed;
  String? referenceImagePath;
  late String basePrompt;
  late DateTime createdAt;
}

@Collection()
class Scene {
  Id id = Isar.autoIncrement;
  late int sceneNumber;
  late String description;
  late String prompt;
  String? imagePath;
  String? videoPath;
  String? audioPath;
  late String status;       // 'pending'|'generating'|'done'|'error'
  List<int> characterIds = [];
  int? seed;
}

@Collection()
class ApiConfig {
  Id id = Isar.autoIncrement;
  late String provider;     // 'replicate'|'openai'|'elevenlabs'|...
  late String apiKey;       // encrypted via flutter_secure_storage
  String? baseUrl;
  Map<String, String>? extraParams;
}
```

---

## ⚡ State Management Pattern (Riverpod)

```dart
// Contoh: Character Studio Provider
@riverpod
class CharacterStudioNotifier extends _$CharacterStudioNotifier {
  @override
  CharacterStudioState build() => CharacterStudioState.initial();

  Future<void> generateCharacter({
    required String prompt,
    int? seed,
    String? referenceImagePath,
  }) async {
    state = state.copyWith(isGenerating: true, error: null);
    try {
      final service = ref.read(characterServiceProvider);
      final character = await service.generate(
        prompt: prompt,
        seed: seed ?? Random().nextInt(999999),
        referenceImagePath: referenceImagePath,
      );
      state = state.copyWith(
        isGenerating: false,
        characters: [...state.characters, character],
      );
    } catch (e) {
      state = state.copyWith(isGenerating: false, error: e.toString());
    }
  }
}

// Di UI (yang sudah ada), tinggal wire:
final studioState = ref.watch(characterStudioNotifierProvider);
// ...
ElevatedButton(
  onPressed: studioState.isGenerating ? null : () => 
    ref.read(characterStudioNotifierProvider.notifier)
       .generateCharacter(prompt: _promptController.text),
  child: Text(studioState.isGenerating ? 'Generating...' : 'Generate'),
)
```

---

## 🔐 Security Considerations

1. **API Keys**: Semua API key disimpan via `flutter_secure_storage` (OS keychain), TIDAK di source code atau Isar langsung
2. **Google Session**: Cookie browser automation disimpan encrypted, tidak dikirim ke server manapun
3. **Subprocess**: Validate semua input sebelum dikirim ke Process (prevent injection)
4. **Local First**: Semua asset (gambar, video, audio) disimpan lokal, tidak diupload kecuali diminta user

---

## 🚀 Setup & Running Order untuk Cursor

Berikut urutan file yang harus dibuat/dimodifikasi oleh Cursor:

1. `pubspec.yaml` — tambah semua dependencies
2. `lib/core/` — semua core services
3. `lib/models/` — semua Isar models + generate
4. `lib/features/settings/` — settings dulu agar API key bisa diisi
5. `lib/features/character_studio/` — fitur pertama yang di-wire
6. `lib/features/scene_builder/` — tergantung character studio
7. `lib/features/youtube_clone/` — independent
8. `lib/features/browser_automation/` — puppeteer bridge + webview
9. `lib/features/ai_voice_music/` — independent
10. `lib/features/video_mastering/` — dependent ffmpeg
11. `lib/features/reels/` — dependent video mastering
12. `lib/router/app_router.dart` — wire semua routes
