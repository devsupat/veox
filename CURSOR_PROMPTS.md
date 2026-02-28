# 🤖 CURSOR MASTER PROMPT — AI Creative Studio Flutter Desktop

---

## PROMPT 0 — CONTEXT SETUP (Paste ini PERTAMA ke Cursor Chat)

```
You are an expert Flutter developer working on a Flutter Desktop application called "AI Creative Studio". 

This app already has a complete UI built. Your job is to implement the business logic, services, state management, and API integrations WITHOUT changing the existing UI structure.

Before making any changes:
1. Always read PLAN.md and ARCHITECTURE.md first
2. Follow the feature-sliced architecture defined in ARCHITECTURE.md
3. Use Riverpod for state management
4. Use Isar for local database
5. Use Dio for HTTP calls
6. Never hardcode API keys — always use flutter_secure_storage

The app has these main modules:
- Character Studio (AI image generation with seed consistency)
- Scene Builder (Story text → JSON scenes → visual prompts → images)
- YouTube Clone (URL → transcript → prompts → content)
- Browser Automation (Headless Puppeteer for Veo3/Grok)
- AI Voice & Music (TTS + music generation)
- Video Mastering (FFmpeg-based editor)
- Reels (Bulk video creator)

Always implement one module at a time. Start with core infrastructure.
```

---

## PROMPT 1 — DEPENDENCIES & CORE SETUP

```
Read PLAN.md and ARCHITECTURE.md.

Task: Setup the project foundation.

1. Update pubspec.yaml to add these dependencies:
   - flutter_riverpod: ^2.5.1
   - riverpod_annotation: ^2.3.5  
   - go_router: ^13.2.0
   - dio: ^5.4.3
   - isar: ^3.1.0
   - isar_flutter_libs: ^3.1.0
   - isar_generator: ^3.1.0 (dev)
   - build_runner: ^2.4.9 (dev)
   - flutter_secure_storage: ^9.0.0
   - file_picker: ^8.0.0
   - path_provider: ^2.1.3
   - ffmpeg_kit_flutter_full: ^6.0.3
   - flutter_inappwebview: ^6.0.0
   - just_audio: ^0.9.39
   - image: ^4.1.7
   - cached_network_image: ^3.3.1
   - uuid: ^4.4.0
   - logger: ^2.3.0
   - riverpod_generator: ^2.3.11 (dev)

2. Create lib/core/storage/secure_storage_service.dart:
   - Class SecureStorageService with methods: saveApiKey(provider, key), getApiKey(provider), deleteApiKey(provider), getAllProviders()
   - Providers: 'replicate', 'openai', 'anthropic', 'elevenlabs', 'suno'

3. Create lib/core/network/dio_client.dart:
   - Singleton DioClient class
   - Method: getClient(provider) yang auto-inject Authorization header dari SecureStorageService
   - Timeout: 120 seconds (AI APIs lambat)
   - Retry interceptor: 3x retry on network error

4. Create lib/core/utils/logger.dart:
   - Wrapper untuk package:logger
   - AppLogger.info(), AppLogger.error(), AppLogger.debug()

5. Create lib/core/process/process_runner.dart:
   - Class ProcessRunner
   - Method: run(executable, args) → Future<ProcessResult>
   - Method: stream(executable, args) → Stream<String> (untuk realtime output)
   - Error handling jika executable tidak ditemukan

6. Create lib/main.dart update:
   - Wrap dengan ProviderScope
   - Initialize Isar
   - Initialize SecureStorageService

Run: flutter pub get dan pastikan semua compile tanpa error.
```

---

## PROMPT 2 — DATABASE MODELS

```
Read ARCHITECTURE.md section "Database Schema".

Task: Create all Isar database models.

Create these files:

1. lib/models/project.dart
   @Collection class Project:
   - Id id, String name, String description, DateTime createdAt, DateTime updatedAt
   - IsarLinks<Character> characters
   - IsarLinks<Scene> scenes

2. lib/models/character.dart  
   @Collection class Character:
   - Id id, String name, String imageUrl (local path), int seed
   - String? referenceImagePath, String basePrompt
   - String? negativePrompt, String? style
   - DateTime createdAt
   - int projectId (reference)

3. lib/models/scene.dart
   @Collection class Scene:
   - Id id, int sceneNumber, String description, String prompt
   - String? imagePath, String? videoPath, String? audioPath
   - String status ('pending'|'generating'|'done'|'error')
   - List<int> characterIds, int? seed, int? projectId
   - String? errorMessage, DateTime? generatedAt

4. lib/models/prompt_item.dart
   @Collection class PromptItem:
   - Id id, String text, String? source (youtube url, etc)
   - int? sceneNumber, String? status
   - DateTime createdAt

5. lib/models/api_config.dart
   @Collection class ApiConfig:
   - Id id, String provider, String encryptedKeyRef (key to secure storage)
   - String? baseUrl, String? selectedModel
   - bool isActive, DateTime updatedAt

6. lib/models/video_asset.dart
   @Collection class VideoAsset:
   - Id id, String filePath, String? thumbnailPath
   - int? durationMs, String type ('image'|'video'|'audio')
   - int? projectId, DateTime importedAt

7. lib/core/storage/isar_service.dart:
   - Singleton IsarService
   - Method: init() → opens Isar with all collections
   - Method: get isar → returns Isar instance
   - CRUD helpers per collection

After creating all models, run:
flutter pub run build_runner build --delete-conflicting-outputs

Fix any generated file issues.
```

---

## PROMPT 3 — SETTINGS MODULE

```
Task: Implement Settings module logic (connect to existing Settings UI).

1. Create lib/features/settings/domain/settings_service.dart:
   - SettingsService class (not riverpod, pure service)
   - saveApiKey(String provider, String key) → validates format first
   - getApiKey(String provider) → String?
   - testApiKey(String provider, String key) → Future<bool> (makes test call)
   - For 'replicate': GET https://api.replicate.com/v1/account with key
   - For 'openai': GET https://api.openai.com/v1/models with key
   - For 'elevenlabs': GET https://api.elevenlabs.io/v1/user with key

2. Create lib/features/settings/presentation/providers/settings_provider.dart:
   @riverpod class SettingsNotifier:
   - State: SettingsState {Map<String, String?> apiKeys, Map<String, bool> testResults, bool isTesting}
   - loadAllKeys() → load dari secure storage
   - saveKey(provider, key) → save + auto-test
   - testKey(provider) → test connection

3. Wire ke existing SettingsScreen:
   - Find the existing settings screen file
   - Add ref.watch(settingsNotifierProvider) 
   - Connect save button to notifier.saveKey()
   - Show green checkmark / red X berdasarkan testResults
   - Show loading indicator saat isTesting

Do NOT create new UI. Only add logic to existing widgets.
```

---

## PROMPT 4 — CHARACTER STUDIO LOGIC

```
Task: Implement Character Studio business logic.

1. Create lib/features/character_studio/data/image_generation_client.dart:
   - ImageGenerationClient using Dio
   - Method generateViaReplicate(prompt, seed, negativePrompt, width, height, referenceImageBase64?)
     - POST https://api.replicate.com/v1/predictions
     - Model: "stability-ai/sdxl:7762fd07..."  
     - Poll /predictions/{id} setiap 2 detik sampai status 'succeeded'
     - Return image URL
   - Method generateViaStableDiffusion(params) untuk local SD WebUI
     - POST http://localhost:7860/sdapi/v1/txt2img
   - Method downloadAndSaveImage(url, characterId) → local file path

2. Create lib/features/character_studio/domain/character_service.dart:
   - CharacterService class
   - generateCharacter(name, prompt, seed?, referenceImagePath?) → Future<Character>
     - Pilih provider dari settings (replicate / sd-webui)
     - Call appropriate client
     - Download image ke local: app_documents/characters/{uuid}.png
     - Save ke Isar, return Character
   - regenerateCharacter(characterId, newSeed?) → Future<Character>
   - deleteCharacter(characterId)
   - getAllCharacters(projectId) → Future<List<Character>>

3. Create lib/features/character_studio/presentation/providers/character_provider.dart:
   @riverpod class CharacterStudioNotifier:
   - State: {List<Character> characters, bool isGenerating, String? error, double progress}
   - loadCharacters(projectId)
   - generateCharacter(name, prompt, seed, referenceImagePath?)
   - regenerateCharacter(id)
   - deleteCharacter(id)
   - importExternalImage(filePath) → saves as character tanpa generation

4. Wire ke existing CharacterStudioScreen:
   - Connect "Generate" button → notifier.generateCharacter()
   - Connect character grid → watch characters list dari provider
   - Connect seed input → pass ke generateCharacter
   - Connect "Import Image" button → notifier.importExternalImage()
   - Show progress indicator overlay saat isGenerating
   - Show error snackbar saat error != null
   - Connect drag & drop to scene (emit event, scene builder will listen)
```

---

## PROMPT 5 — SCENE BUILDER LOGIC

```
Task: Implement Scene Builder - teks cerita menjadi scenes visual.

1. Create lib/features/scene_builder/data/llm_client.dart:
   - LLMClient using Dio
   - Method parseStoryToScenes(storyText) → Future<List<SceneJson>>
     - POST ke OpenAI atau Anthropic (pilih dari settings)
     - System prompt:
       """
       You are a visual storytelling expert. Parse the given story into scenes.
       Return ONLY valid JSON with this structure:
       {
         "characters": [{"name": "...", "description": "...", "appearance": "..."}],
         "scenes": [{
           "scene_number": 1,
           "description": "...",
           "visual_prompt": "cinematic, ...",
           "camera_angle": "wide shot",
           "lighting": "...",
           "characters_in_scene": ["character_name"],
           "mood": "..."
         }]
       }
       """
     - Parse JSON response, return list
   - Method enhancePrompt(basicPrompt) → String (tambah cinematic keywords)

2. Create lib/features/scene_builder/domain/scene_builder_service.dart:
   - SceneBuilderService
   - parseStory(text, projectId) → Future<SceneParseResult>
     - Call LLMClient.parseStoryToScenes()
     - Auto-create Character entries dari detected characters
     - Save all Scenes ke Isar
     - Return {characters, scenes}
   - generateScene(sceneId) → Future<Scene>
     - Get scene dari Isar
     - Call ImageGenerationClient dengan scene.prompt + seed
     - Update scene.imagePath dan status
   - generateAllScenes(projectId, {int concurrency = 3}) → Stream<Scene>
     - Process dengan concurrency limit
     - Yield setiap scene yang selesai
   - assignCharacterToScene(sceneId, characterId)
   - regenerateScene(sceneId, newPrompt?)

3. Create providers/scene_builder_provider.dart:
   @riverpod class SceneBuilderNotifier:
   - State: {scenes, characters, isParsingStory, isGenerating, progress, error}
   - parseStory(text)
   - generateAllScenes() → listen stream, update progress
   - generateSingleScene(id)
   - reorderScenes(oldIndex, newIndex)

4. Wire ke existing SceneBuilderScreen:
   - Paste story text area → detect text, enable Parse button
   - Parse button → notifier.parseStory()
   - Generate All button → notifier.generateAllScenes()
   - Scene grid → watch scenes list
   - Drag & drop character → notifier.assignCharacterToScene()
   - Per-scene regenerate button
   - Progress bar: "Generating scene X of Y"
```

---

## PROMPT 6 — YOUTUBE CLONE LOGIC

```
Task: Implement YouTube Clone - extract transcript dan buat prompts.

1. Create lib/features/youtube_clone/data/ytdlp_client.dart:
   - YtDlpClient
   - Check if yt-dlp is installed: Process.run('yt-dlp', ['--version'])
   - If not found, provide download instructions
   - Method getTranscript(url) → Future<String>:
     - Process.run('yt-dlp', ['--write-auto-sub', '--sub-lang', 'en', 
       '--skip-download', '--output', tempPath, url])
     - Read generated .vtt/.srt file
     - Clean timestamps, return plain text
   - Method getVideoInfo(url) → Future<VideoInfo> {title, duration, thumbnail}:
     - yt-dlp --dump-json url

2. Create lib/features/youtube_clone/domain/youtube_clone_service.dart:
   - YouTubeCloneService
   - cloneVideo(url) → Stream<CloneProgress>:
     1. Yield progress: "Fetching video info..."
     2. Get transcript via YtDlpClient
     3. Yield progress: "Analyzing transcript..."
     4. Send to LLM: generate visual prompts per segment
        System prompt: "Convert this transcript into visual prompts for video recreation..."
     5. Parse JSON response → List<PromptItem>
     6. Save to Isar
     7. Yield progress: "Done" with promptItems

3. Create providers/youtube_clone_provider.dart:
   @riverpod class YouTubeCloneNotifier:
   - State: {isCloning, progress, prompts, error, videoInfo}
   - startClone(url)
   - copyAllPrompts() → clipboard
   - sendToHomeScreen(prompts) → navigate + pass prompts
   - clearPrompts()

4. Wire ke existing YouTubeCloneScreen:
   - URL input field
   - Start button → validate URL → notifier.startClone()
   - Progress steps display (Step 1: Fetching... ✓, Step 2: ...)
   - Prompts list display saat selesai
   - Copy All button
   - "Send to Scene Builder" button
   - Error state: show error + "yt-dlp not installed" guide jika perlu
```

---

## PROMPT 7 — BROWSER AUTOMATION (Veo3 & Grok)

```
Task: Implement browser automation untuk Veo3 dan Grok.

STRATEGY: Gunakan flutter_inappwebview + JavaScript injection sebagai primary approach.
Fallback: Puppeteer via Node.js subprocess.

1. Create lib/features/browser_automation/data/webview_controller.dart:
   - BrowserController class wrapping InAppWebViewController
   - Method: navigateTo(url)
   - Method: injectJS(script) → Future<dynamic>
   - Method: waitForElement(selector, timeout) → Future<bool>
   - Method: clickElement(selector)
   - Method: fillInput(selector, value)
   - Method: getCookies() → Future<String>
   - Method: setCookies(cookiesJson)

2. Create automation scripts (as Dart string constants):
   lib/features/browser_automation/data/scripts/veo3_script.dart:
   - loginCheck: "document.querySelector('[data-email]')?.textContent"
   - submitPrompt: "document.querySelector('.prompt-input').value = '{PROMPT}'; ..."
   - checkProgress: "document.querySelector('.generation-status')?.textContent"
   - downloadResult: "document.querySelector('.download-btn')?.click()"
   
   lib/features/browser_automation/data/scripts/grok_script.dart:
   - Similar scripts untuk grok.x.ai

3. Create lib/features/browser_automation/domain/veo3_service.dart:
   - Veo3Service
   - submitPromptQueue(List<String> prompts) → Stream<AutomationProgress>:
     1. Navigate to labs.google.com/veo (or applicable URL)
     2. Check login status → if not logged, wait for manual login
     3. For each prompt: fill → submit → poll result → download
     4. Yield progress per prompt
   - downloadResult(url, outputPath) → Future<String>

4. Create providers/browser_automation_provider.dart:
   @riverpod class BrowserAutomationNotifier:
   - State: {platform, isRunning, queue, currentIndex, results, needsLogin, webViewUrl}
   - initSession(platform, prompts)
   - startAutomation()
   - pauseAutomation()
   - onLoginDetected() → resume automation

5. Wire ke existing BrowserAutomationScreen / browser widget:
   - Dropdown: pilih platform (Veo3 / Grok)
   - Prompts input (atau receive dari Scene Builder)
   - Show actual WebView (InAppWebView widget)
   - "Login" button → navigate ke login page, monitor login status
   - "Start" button → startAutomation()
   - Progress: "Processing prompt 3 of 12..."
   - Results gallery: thumbnail hasil yang sudah done
   - "Download All" button

Note: Tambahkan disclaimer di UI bahwa automation bergantung pada struktur website yang bisa berubah sewaktu-waktu.
```

---

## PROMPT 8 — AI VOICE & MUSIC

```
Task: Implement AI Voice (TTS) dan Music Generation.

1. Create lib/features/ai_voice_music/data/elevenlabs_client.dart:
   - ElevenLabsClient
   - getVoices() → Future<List<Voice>> {id, name, preview_url, labels}
     - GET https://api.elevenlabs.io/v1/voices
   - generateSpeech(text, voiceId, {stability, similarityBoost}) → Future<Uint8List>
     - POST https://api.elevenlabs.io/v1/text-to-speech/{voiceId}
     - Return audio bytes (mp3)
   - saveAudio(bytes, filename) → Future<String> (local path)

2. Create lib/features/ai_voice_music/data/openai_tts_client.dart:
   - OpenAITTSClient (fallback jika no ElevenLabs)
   - generateSpeech(text, voice='alloy') → Future<Uint8List>
     - POST https://api.openai.com/v1/audio/speech

3. Create lib/features/ai_voice_music/data/music_gen_client.dart:
   - MusicGenClient via Replicate
   - generateMusic(prompt, duration=30, {instrumental=true}) → Future<String> (audio url)
     - POST https://api.replicate.com/v1/predictions
     - Model: "meta/musicgen:..."
   - generateForVideo(videoDescription, mood) → Future<String>
     - Auto-craft music prompt dari video description

4. Create lib/features/ai_voice_music/domain/tts_service.dart:
   - TTSService
   - generateVoiceForScene(scene) → Future<String> (audio path)
   - generateBulkVoices(scenes) → Stream<VoiceProgress>
   - previewVoice(text, voiceId) → Future<void> (play immediately)
   - availableVoices() → Future<List<Voice>>

5. Create providers/voice_music_provider.dart:
   @riverpod class VoiceMusicNotifier:
   - State: {voices, selectedVoice, scenes, isGenerating, progress, audioPlaying}
   - loadVoices()
   - selectVoice(voiceId)
   - generateForScene(sceneId, text)
   - generateBulkAll()
   - generateMusic(prompt, duration)
   - playPreview(audioPath)
   - stopPreview()

6. Wire ke existing VoiceMusicScreen:
   - Voice dropdown → watch voices list
   - Preview button → play sample voice
   - Text input per scene
   - Generate button (single / bulk)
   - Progress bar untuk bulk generation
   - Music generator: prompt input + duration slider
   - Audio waveform atau simple play button untuk preview result
```

---

## PROMPT 9 — VIDEO MASTERING

```
Task: Implement Video Mastering dengan FFmpeg.

1. Create lib/features/video_mastering/domain/ffmpeg_command_builder.dart:
   - FFmpegCommandBuilder (builder pattern)
   - Static methods:
     - imagesToVideo(imagePaths, outputPath, fps=24) → List<String> (ffmpeg args)
     - addAudio(videoPath, audioPath, outputPath) → List<String>
     - addLogo(videoPath, logoPath, outputPath, {x=10, y=10, opacity=0.8}) → List<String>
     - concatenate(videoPaths, outputPath) → List<String> (via concat demuxer)
     - upscale(inputPath, outputPath, scale=2) → List<String>
     - exportReel(videoPath, outputPath, {aspectRatio='9:16'}) → List<String>
     - addSubtitles(videoPath, srtPath, outputPath) → List<String>

2. Create lib/features/video_mastering/domain/video_mastering_service.dart:
   - VideoMasteringService
   - assembleFromScenes(projectId, {includeAudio=true, logoPath?}) → Stream<MasteringProgress>:
     1. Get all scenes dengan imagePath dan audioPath dari Isar
     2. Build FFmpeg command: images → video clips
     3. Add audio per clip
     4. Concatenate all clips
     5. Add logo if provided
     6. Yield progress setiap step
   - importVideo(filePath) → Future<VideoAsset>
   - generateBackgroundMusic(videoPath, projectDescription) → Future<String>
     - Extract project description → call MusicGen → return audio path
   - exportVideo(inputPath, outputPath, {preset='1080p'}) → Future<void>
   - bulkUpscale(imagePaths) → Stream<UpscaleProgress>
     - Via Replicate Real-ESRGAN API

3. Create providers/video_mastering_provider.dart:
   @riverpod class VideoMasteringNotifier:
   - State: {clips, isAssembling, isMastering, progress, outputPath, logoPath, error}
   - loadProjectAssets(projectId)
   - addClip(videoAsset)
   - removeClip(assetId)
   - reorderClips(oldIndex, newIndex)
   - setLogo(filePath)
   - assemble()
   - exportFinal(outputPath, preset)
   - bulkUpscale()

4. Wire ke existing VideoMasteringScreen:
   - Import video/image button → file picker → notifier.addClip()
   - Simple list/timeline of clips (reorderable)
   - Logo picker button
   - Export preset dropdown (1080p, 4K, Reels 9:16, YouTube 16:9)
   - Assemble & Export button → notifier.assemble()
   - Progress overlay dengan step details
   - "Generate Music" button untuk auto background music
   - Preview setelah export (launch file)
```

---

## PROMPT 10 — INTEGRATION & POLISH

```
Task: Final integration, error handling, dan project management.

1. Create lib/features/home/domain/project_service.dart:
   - ProjectService
   - createProject(name, description) → Future<Project>
   - loadProject(id) → Future<Project> dengan all relations
   - deleteProject(id)
   - getAllProjects() → Future<List<Project>>
   - exportProject(id, outputDir) → zip all assets

2. Create global error handling:
   - lib/core/errors/error_handler.dart
   - Show snackbar untuk recoverable errors
   - Show dialog untuk critical errors
   - Log all errors via AppLogger
   - Riverpod ProviderObserver untuk track state changes

3. Create lib/core/utils/notification_service.dart (Desktop notifications):
   - showNotification(title, body) → when long task completes
   - Use: local_notifier package untuk desktop

4. Wire "Load Scenes" / "Paste Prompts" di Home Screen:
   - Home screen menerima List<String> prompts
   - Tampilkan di list
   - "Generate All" → call SceneBuilderService.generateFromPrompts()

5. Project selector:
   - Sidebar / dropdown untuk switch between projects
   - All modules filter data berdasarkan currentProjectId

6. Add loading states ke semua buttons yang belum:
   - Scan semua screen untuk ElevatedButton yang belum ada loading
   - Wrap dengan Consumer dan check provider state

7. Run full app test:
   - Test flow: Create Project → Add Character → Build Scene → Export Video
   - Fix any runtime errors
   - Ensure all navigation works

8. Create README.md dengan:
   - Required tools: yt-dlp installation guide, ffmpeg installation guide
   - API keys setup guide
   - Feature usage guide
```

---

## 💡 Tips untuk Cursor

### Saat Error
```
Fix the error in [file]. The error is: [paste error].
Keep the existing UI unchanged. Only fix the logic layer.
```

### Saat UI Perlu Diwire
```
The existing screen is at [path]. 
Find all interactive widgets (buttons, text fields, dropdowns) that are not yet connected to any logic.
Wire them to [ProviderName] from [provider_file_path].
Do not modify the widget's visual appearance, only add onPressed/onChanged callbacks and ref.watch calls.
```

### Saat Perlu Cek Existing Code
```
Before implementing [feature], first read all existing files in lib/features/[module]/ 
and list what's already implemented vs what's missing.
Then implement only the missing parts.
```

### Pattern untuk Long Running Tasks
```
All long-running operations must:
1. Return Stream<Progress> not Future<Result>
2. Update provider state incrementally
3. Be cancellable via a cancel flag
4. Show progress percentage in UI
5. Log each step via AppLogger
```
