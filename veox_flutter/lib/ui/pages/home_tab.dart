import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:veox_flutter/providers/app_state.dart';
import 'package:veox_flutter/features/automation/services/veo_automation_service.dart';
import 'package:veox_flutter/features/automation/models/automation_state.dart';
import 'package:veox_flutter/features/automation/services/settings_service.dart';
import 'package:veox_flutter/features/workflows/providers/home_workflow_provider.dart';

import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:veox_flutter/features/history/providers/scene_history_provider.dart';
import 'package:veox_flutter/features/story/data/project_model.dart';
import 'package:veox_flutter/core/database/isar_service.dart';
import 'package:veox_flutter/ui/widgets/job_queue_dialog.dart';

class HomeTab extends ConsumerStatefulWidget {
  const HomeTab({super.key});

  @override
  ConsumerState<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends ConsumerState<HomeTab> {
  final TextEditingController _promptController = TextEditingController();
  String _aspectRatio = "16:9";
  String _selectedModel = "Veo 3.1 - Fast (Lower Priority)";
  String _selectedQuality = "AI Ultra (25,000 cr)";

  // Settings State
  String _currentProfile = "Loading...";

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = ref.read(settingsServiceProvider);
    final profile = await settings.getProfileName();
    if (mounted) setState(() => _currentProfile = profile);
  }

  void _showSettingsDialog() async {
    final settings = ref.read(settingsServiceProvider);
    final profileController = TextEditingController(
      text: await settings.getProfileName(),
    );
    final apiKeyController = TextEditingController(
      text: await settings.getApiKey(),
    );

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Automation Settings"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: profileController,
              decoration: const InputDecoration(
                labelText: "Browser Profile Name",
                helperText:
                    "Unique name creates a separate browser session (cookies/login)",
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: apiKeyController,
              decoration: const InputDecoration(
                labelText: "API Key (Optional)",
              ),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              await settings.saveProfileName(profileController.text);
              await settings.saveApiKey(apiKeyController.text);
              if (context.mounted) {
                Navigator.pop(context);
                _loadSettings(); // Refresh UI
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Settings Saved!")),
                );
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  // Range inputs
  final TextEditingController _fromController = TextEditingController(
    text: "1",
  );
  final TextEditingController _toController = TextEditingController(
    text: "999",
  );
  bool _isBoost = false;
  String _upscale = "1080p"; // 1080p or 4K

  // Browser Controls

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final scenesAsync = ref.watch(sceneHistoryProvider);
    final scenes = scenesAsync.value ?? [];
    final automationState = ref.watch(veoAutomationProvider);
    final automationNotifier = ref.read(veoAutomationProvider.notifier);
    final workflowState = ref.watch(homeWorkflowProvider);
    final workflowNotifier = ref.read(homeWorkflowProvider.notifier);

    return Column(
      children: [
        // 1. Control Panel
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Panel: Generation Settings
              Expanded(
                flex: 2,
                child: AbsorbPointer(
                  absorbing: workflowState.isRunning,
                  child: Opacity(
                    opacity: workflowState.isRunning ? 0.5 : 1.0,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Row 1: Ratio & Model
                        Row(
                          children: [
                            const Text(
                              "Ratio: ",
                              style: TextStyle(color: Colors.grey),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                children: [
                                  _buildToggleBtn(
                                    "16:9",
                                    _aspectRatio == "16:9",
                                    (v) =>
                                        setState(() => _aspectRatio = "16:9"),
                                  ),
                                  _buildToggleBtn(
                                    "9:16",
                                    _aspectRatio == "9:16",
                                    (v) =>
                                        setState(() => _aspectRatio = "9:16"),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Text(
                              "Model: ",
                              style: TextStyle(color: Colors.grey),
                            ),
                            Expanded(
                              child: Container(
                                height: 32,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _selectedModel,
                                    isExpanded: true,
                                    items:
                                        [
                                              "Veo 3.1 - Fast (Lower Priority)",
                                              "Veo 2.0",
                                              "Gemini 1.5 Pro",
                                              "Groq Llama 3",
                                            ]
                                            .map(
                                              (e) => DropdownMenuItem(
                                                value: e,
                                                child: Text(
                                                  e,
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                  ),
                                                ),
                                              ),
                                            )
                                            .toList(),
                                    onChanged: (v) =>
                                        setState(() => _selectedModel = v!),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Row 2: Frame Ops & Upscale
                        Row(
                          children: [
                            _buildOutlineBtn("First Frames", LucideIcons.image),
                            const SizedBox(width: 8),
                            _buildOutlineBtn("Last Frames", LucideIcons.image),
                            const SizedBox(width: 16),
                            const Text(
                              "Upscale: ",
                              style: TextStyle(color: Colors.grey),
                            ),
                            _buildToggleBtn(
                              "1080p",
                              _upscale == "1080p",
                              (v) => setState(() => _upscale = "1080p"),
                              color: Colors.blue,
                            ),
                            _buildToggleBtn(
                              "4K",
                              _upscale == "4K",
                              (v) => setState(() => _upscale = "4K"),
                              color: Colors.purple,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Row 3: Playback Controls
                        Row(
                          children: [
                            _buildControlBtn(
                              "Start",
                              LucideIcons.play,
                              Colors.green.shade50,
                              Colors.green,
                              () => appState.startGeneration(),
                            ),
                            const SizedBox(width: 8),
                            _buildControlBtn(
                              "Pause",
                              LucideIcons.pause,
                              Colors.grey.shade100,
                              Colors.grey,
                              null,
                            ),
                            const SizedBox(width: 8),
                            _buildControlBtn(
                              "Stop",
                              LucideIcons.square,
                              Colors.grey.shade100,
                              Colors.grey,
                              () => appState.stopGeneration(),
                            ),
                            const SizedBox(width: 8),
                            _buildControlBtn(
                              "Retry",
                              LucideIcons.refreshCw,
                              Colors.orange.shade50,
                              Colors.orange,
                              null,
                            ),
                            const SizedBox(width: 8),
                            _buildControlBtn(
                              "Resumes",
                              LucideIcons.rotateCcw,
                              Colors.grey.shade100,
                              Colors.grey,
                              null,
                            ),
                            const SizedBox(width: 8),
                            Container(
                              height: 32,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Center(
                                child: Text(
                                  "1",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Row 4: Range & Boost
                        Row(
                          children: [
                            const Text(
                              "From: ",
                              style: TextStyle(color: Colors.grey),
                            ),
                            SizedBox(
                              width: 50,
                              child: _buildInput(_fromController),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              "To: ",
                              style: TextStyle(color: Colors.grey),
                            ),
                            SizedBox(
                              width: 50,
                              child: _buildInput(_toController),
                            ),
                            const SizedBox(width: 16),
                            const Text(
                              "10x Boost ",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Switch(
                              value: _isBoost,
                              onChanged: (v) => setState(() => _isBoost = v),
                              activeColor: Colors.purple,
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),
                        // Prompt Input
                        Container(
                          height: 40,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: TextField(
                            controller: _promptController,
                            decoration: const InputDecoration(
                              hintText:
                                  "Quick prompt... e.g. A cyberpunk city in rain",
                              border: InputBorder.none,
                              hintStyle: TextStyle(
                                color: Colors.grey,
                                fontSize: 13,
                              ),
                            ),
                            onSubmitted: (val) {
                              if (val.isNotEmpty) {
                                appState.addScene(val);
                                _promptController.clear();
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 24),

              // Right Panel: Credits & Browser
              SizedBox(
                width: 300,
                child: Column(
                  children: [
                    // Job Queue Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(LucideIcons.list, size: 14),
                        label: const Text("Job Queue"),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => const JobQueueDialog(),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade50,
                          foregroundColor: Colors.blue.shade700,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Credits
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.purple.shade50,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.purple.shade100),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  LucideIcons.star,
                                  size: 14,
                                  color: Colors.purple,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _selectedQuality,
                                    style: const TextStyle(
                                      color: Colors.purple,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedQuality,
                              icon: const Icon(
                                LucideIcons.chevronDown,
                                size: 14,
                              ),
                              isDense: true,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black,
                              ),
                              items:
                                  [
                                        "AI Ultra (25,000 cr)",
                                        "AI Pro (10,000 cr)",
                                        "Free Tier (Daily Limit)",
                                        "Groq (Free)",
                                      ]
                                      .map(
                                        (e) => DropdownMenuItem(
                                          value: e,
                                          child: Text(e),
                                        ),
                                      )
                                      .toList(),
                              onChanged: (v) =>
                                  setState(() => _selectedQuality = v!),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Multi-Browser Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade200),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "MULTI-BROWSER",
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              InkWell(
                                onTap: _showSettingsDialog,
                                child: const Icon(
                                  LucideIcons.settings,
                                  size: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Text("Profile: "),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  _currentProfile,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              // Login Button
                              InkWell(
                                onTap: () async {
                                  // Launch browser for manual login
                                  await automationNotifier.launchBrowser();
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          "Browser Launched for Profile: $_currentProfile. Please login manually.",
                                        ),
                                      ),
                                    );
                                  }
                                },
                                child: _buildStatusBadge(
                                  "Login",
                                  Colors.orange,
                                ),
                              ),
                              const SizedBox(width: 4),
                              _buildStatusBadge("ALL", Colors.green),
                              const SizedBox(width: 4),
                              IconButton(
                                onPressed: () =>
                                    automationNotifier.closeBrowser(),
                                icon: const Icon(
                                  LucideIcons.stopCircle,
                                  color: Colors.red,
                                  size: 20,
                                ),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed:
                                      automationState.status ==
                                          AutomationStatus.connected
                                      ? null
                                      : () =>
                                            automationNotifier.launchBrowser(),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        automationState.status ==
                                            AutomationStatus.connected
                                        ? Colors.green
                                        : Colors.orange,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 0,
                                    ),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                  child: Text(
                                    automationState.status ==
                                            AutomationStatus.connected
                                        ? "Connected"
                                        : "Connect Opened",
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () => automationNotifier
                                      .launchBrowser(), // Same as Connect for now
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.grey.shade700,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 0,
                                    ),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                  child: const Text(
                                    "Open No Login",
                                    style: TextStyle(fontSize: 11),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Generate Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed:
                            automationState.status == AutomationStatus.busy ||
                                workflowState.isRunning
                            ? null
                            : () async {
                                if (automationState.status !=
                                    AutomationStatus.connected) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        "Please connect browser first!",
                                      ),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  return;
                                }

                                final appState = context.read<AppState>();
                                final prompt = _promptController.text;
                                appState.addLog(
                                  "INFO",
                                  "Starting Generation Task...",
                                );

                                final finalPrompt = prompt.isEmpty
                                    ? "A cyberpunk character"
                                    : prompt;

                                try {
                                  workflowNotifier.startGeneration();

                                  final newScene = SceneModel()
                                    ..sceneId = const Uuid().v4()
                                    ..text = "User generated prompt"
                                    ..generatedPrompt = finalPrompt
                                    ..status = "generating"
                                    ..index = scenes.length + 1;
                                  appState.addLog(
                                    "INFO",
                                    "Saving job to history...",
                                  );
                                  await IsarService().saveScene(newScene);

                                  await automationNotifier.executeVeoAction(
                                    email: "user@example.com",
                                    password: "secure_password",
                                    profileName: _currentProfile,
                                    action: "generate",
                                    prompt: finalPrompt,
                                  );

                                  workflowNotifier.completeGeneration();

                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          "Generation sequence completed!",
                                        ),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  workflowNotifier.failGeneration(e.toString());
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text("Automation Error: $e"),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              },
                        icon: automationState.status == AutomationStatus.busy
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(LucideIcons.sparkles, size: 16),
                        label: Text(
                          workflowState.isRunning
                              ? "Engine Running..."
                              : automationState.status == AutomationStatus.busy
                              ? "Generating..."
                              : "Generate",
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981), // Green
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                    if (workflowState.currentAction != null ||
                        automationState.currentAction != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          workflowState.currentAction ??
                              automationState.currentAction ??
                              "",
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const Icon(
                          LucideIcons.trash2,
                          size: 12,
                          color: Colors.red,
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          "Clear",
                          style: TextStyle(color: Colors.red, fontSize: 12),
                        ),
                        const SizedBox(width: 16),
                        InkWell(
                          onTap: _handleExport,
                          child: const Row(
                            children: [
                              Icon(
                                LucideIcons.download,
                                size: 12,
                                color: Colors.blue,
                              ),
                              SizedBox(width: 4),
                              Text(
                                "Export",
                                style: TextStyle(
                                  color: Colors.blue,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // 2. Scene Grid
        if (workflowState.isRunning)
          Expanded(
            child: Container(
              color: const Color(0xFFF9FAFB),
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(color: Colors.blue),
                    const SizedBox(height: 24),
                    Text(
                      workflowState.currentAction ?? "Processing...",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Your assets are being generated. This may take a moment...",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          Expanded(
            child: Container(
              color: const Color(0xFFF9FAFB),
              padding: const EdgeInsets.all(16),
              child: scenes.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            LucideIcons.playSquare,
                            size: 64,
                            color: Colors.grey.shade200,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "Generated scenes will appear here",
                            style: TextStyle(color: Colors.grey.shade400),
                          ),
                        ],
                      ),
                    )
                  : GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            childAspectRatio: 1.2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                      itemCount: scenes.length,
                      itemBuilder: (context, index) {
                        return _buildSceneCard(scenes[index]);
                      },
                    ),
            ),
          ),
      ],
    );
  }

  Widget _buildToggleBtn(
    String label,
    bool isSelected,
    Function(bool) onTap, {
    Color color = Colors.blue,
  }) {
    return InkWell(
      onTap: () => onTap(!isSelected),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : Colors.black54,
          ),
        ),
      ),
    );
  }

  Widget _buildOutlineBtn(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.blue),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Icon(icon, size: 12, color: Colors.blue),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.blue,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlBtn(
    String label,
    IconData icon,
    Color bg,
    Color fg,
    VoidCallback? onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: fg),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: fg,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInput(TextEditingController controller) {
    return Container(
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(4),
      ),
      child: TextField(
        controller: controller,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 12),
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.only(bottom: 14),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.check, size: 10, color: Colors.white),
          const SizedBox(width: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 9,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleExport() async {
    final path = await FilePicker.platform.saveFile(
      dialogTitle: 'Save Output As',
      fileName: 'veo_output_${DateTime.now().millisecondsSinceEpoch}.mp4',
    );
    if (path != null) {
      final file = File(path);
      await file.writeAsString("DUMMY VIDEO CONTENT");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Exported to $path"),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Widget _buildSceneCard(SceneModel scene) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 30,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                  color: Colors.purple.shade50,
                  child: Text(
                    "#${scene.index.toString().padLeft(3, '0')}",
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.purple.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Icon(
                  LucideIcons.minusCircle,
                  size: 14,
                  color: Colors.orange,
                ),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: Icon(
                LucideIcons.image,
                size: 40,
                color: Colors.grey.shade200,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  scene.generatedPrompt,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(LucideIcons.refreshCw, size: 12),
                    label: const Text("Generate"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
