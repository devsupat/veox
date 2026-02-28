import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:veox_flutter/features/automation/providers/veo_automation_provider.dart';
import 'package:veox_flutter/features/automation/models/automation_state.dart';

class CloneTab extends ConsumerStatefulWidget {
  const CloneTab({super.key});

  @override
  ConsumerState<CloneTab> createState() => _CloneTabState();
}

class _CloneTabState extends ConsumerState<CloneTab> {
  final TextEditingController _urlController = TextEditingController(text: "https://www.youtube.com/watch?v=8A41Qka18ko");
  final TextEditingController _promptController = TextEditingController(text: "A futuristic city with flying cars"); // Mock prompt for now
  String _selectedStyle = "No Style";
  String _selectedModel = "Gemini 3 Flash";
  bool _voiceEnabled = false;
  bool _twoInOne = true;
  String _clips = "5";

  @override
  Widget build(BuildContext context) {
    final automationState = ref.watch(veoAutomationProvider);
    final automationNotifier = ref.read(veoAutomationProvider.notifier);

    return Column(
      children: [
        // Header Info
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 8),
          color: Colors.white,
          alignment: Alignment.center,
          child: const Text(
            "Frame Sequencer 3 (Human char consistant)",
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ),
        
        // Main Content (Black Background Area)
        Expanded(
          child: Container(
            color: Colors.black,
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 800),
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Logo/Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green.withValues(alpha: 0.5)),
                          ),
                          child: const Row(
                            children: [
                              Icon(LucideIcons.video, color: Colors.green, size: 16),
                              SizedBox(width: 8),
                              Text("CineRecreate", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            _buildTopLink("Analyzer"),
                            const SizedBox(width: 16),
                            _buildTopLink("Prompt Generator"),
                            const SizedBox(width: 16),
                            _buildTopLink("Veo Forge"),
                            const SizedBox(width: 24),
                            // Connection Status
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: automationState.status == AutomationStatus.connected 
                                  ? Colors.green.withValues(alpha: 0.1) 
                                  : Colors.grey.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: automationState.status == AutomationStatus.connected 
                                    ? Colors.green 
                                    : Colors.grey
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    automationState.status == AutomationStatus.connected ? LucideIcons.link : LucideIcons.link2Off, 
                                    size: 12, 
                                    color: automationState.status == AutomationStatus.connected ? Colors.green : Colors.grey
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    automationState.status == AutomationStatus.connected ? "Connected" : "Disconnected",
                                    style: TextStyle(
                                      color: automationState.status == AutomationStatus.connected ? Colors.green : Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                    const SizedBox(height: 64),

                    // Title
                    RichText(
                      text: const TextSpan(
                        children: [
                          TextSpan(text: "FRAME ", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
                          TextSpan(text: "SEQUENCER", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF3B82F6))), // Blue
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "Deconstruct cinema into a clean visual prompt JSON sequence. Automated subject\ninjection for generation-ready data.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, height: 1.5),
                    ),
                    const SizedBox(height: 48),

                    // Input Form
                    // 1. URL & Model Row
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: _buildInputContainer(
                            child: TextField(
                              controller: _urlController,
                              style: const TextStyle(color: Colors.white, fontSize: 13),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildInputContainer(
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedModel,
                                dropdownColor: const Color(0xFF1E1E1E),
                                icon: const Icon(LucideIcons.chevronDown, color: Colors.grey, size: 16),
                                isExpanded: true,
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                style: const TextStyle(color: Colors.white, fontSize: 13),
                                items: ["Gemini 3 Flash", "Gemini 1.5 Pro"].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                                onChanged: (v) => setState(() => _selectedModel = v!),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // 2. Settings Row
                    Row(
                      children: [
                        // Style Dropdown
                        Expanded(
                          child: _buildInputContainer(
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedStyle,
                                dropdownColor: const Color(0xFF1E1E1E),
                                icon: const Icon(LucideIcons.chevronDown, color: Colors.grey, size: 16),
                                isExpanded: true,
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                style: const TextStyle(color: Colors.white, fontSize: 13),
                                items: ["No Style", "Cinematic", "Anime"].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                                onChanged: (v) => setState(() => _selectedStyle = v!),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        
                        // Reference Input
                        Expanded(
                          child: _buildInputContainer(
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              child: Row(
                                children: [
                                  Icon(LucideIcons.image, size: 14, color: Colors.grey),
                                  SizedBox(width: 8),
                                  Text("Reference", style: TextStyle(color: Colors.grey, fontSize: 13)),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Clips
                        Container(
                          width: 100,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade800),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(left: 12),
                                child: Text("CLIPS", style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
                              ),
                              Expanded(
                                child: TextField(
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: Colors.white, fontSize: 13),
                                  controller: TextEditingController(text: _clips),
                                  decoration: const InputDecoration(border: InputBorder.none),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Voice Toggle
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade800),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Switch(
                                value: _voiceEnabled, 
                                onChanged: (v) => setState(() => _voiceEnabled = v),
                                activeColor: Colors.white,
                                activeTrackColor: Colors.grey,
                                inactiveThumbColor: Colors.grey,
                                inactiveTrackColor: const Color(0xFF1E1E1E),
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              const Text("VOICE English", style: TextStyle(color: Colors.grey, fontSize: 11)),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                color: Colors.green.withValues(alpha: 0.2),
                                child: const Text("2MIN", style: TextStyle(color: Colors.green, fontSize: 8)),
                              )
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),

                        // 2-IN-1 Toggle
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade800),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Text("2-IN-1", style: TextStyle(color: Colors.grey, fontSize: 11)),
                              const SizedBox(width: 8),
                              Switch(
                                value: _twoInOne, 
                                onChanged: (v) => setState(() => _twoInOne = v),
                                activeColor: Colors.white,
                                activeTrackColor: const Color(0xFF10B981), // Green
                                inactiveThumbColor: Colors.grey,
                                inactiveTrackColor: const Color(0xFF1E1E1E),
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Generate Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: automationState.status == AutomationStatus.busy 
                          ? null 
                          : () async {
                              if (automationState.status != AutomationStatus.connected) {
                                // Connect first
                                await automationNotifier.launchBrowser();
                              } else {
                                // Start Generation
                                try {
                                  // Mock prompt extraction from URL (in real app, use youtube api)
                                  await automationNotifier.generateVideo(_promptController.text);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("Video generation started on browser!")),
                                  );
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
                                  );
                                }
                              }
                          },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: automationState.status == AutomationStatus.connected ? Colors.white : Colors.blue,
                          foregroundColor: automationState.status == AutomationStatus.connected ? Colors.black : Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: automationState.status == AutomationStatus.connecting || automationState.status == AutomationStatus.busy
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : Text(
                              automationState.status == AutomationStatus.connected 
                                ? "GENERATE SEQUENCE" 
                                : "CONNECT BROWSER",
                              style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
                            ),
                      ),
                    ),
                    if (automationState.currentAction != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          automationState.currentAction!,
                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTopLink(String text) {
    return Text(
      text,
      style: const TextStyle(color: Colors.grey, fontSize: 13),
    );
  }

  Widget _buildInputContainer({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF09090B), // Very dark bg
        border: Border.all(color: Colors.grey.shade800),
        borderRadius: BorderRadius.circular(8),
      ),
      child: child,
    );
  }
}
