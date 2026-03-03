import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:veox_flutter/features/story/presentation/character_studio_provider.dart';
import 'package:provider/provider.dart' as p;
import 'package:veox_flutter/providers/app_state.dart';
import 'package:veox_flutter/providers/navigation_provider.dart';

class CharacterStudioTab extends ConsumerStatefulWidget {
  const CharacterStudioTab({super.key});

  @override
  ConsumerState<CharacterStudioTab> createState() => _CharacterStudioTabState();
}

class _CharacterStudioTabState extends ConsumerState<CharacterStudioTab> {
  final TextEditingController _storyController = TextEditingController();
  bool _useTemplate = true;
  final String _selectedConsistency = "CHARACTER & ENTITY CONSISTE...";
  final String _selectedModel = "GEMINI 3 LATEST";
  final int _promptCount = 10;
  bool _jsonOutput = true;

  void _startGeneration() {
    ref
        .read(characterStudioProvider.notifier)
        .generateScenesJson(_storyController.text, _promptCount);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(characterStudioProvider);
    final detectedCharacters = state.characters;
    final isGenerating = state.isDetecting;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Sidebar Tools (Left)
        Container(
          width: 70,
          color: Colors.white,
          child: Column(
            children: [
              _buildSidebarItem(LucideIcons.image, "Image\nto Video", true),
              _buildSidebarItem(LucideIcons.type, "Text to\nVideo", false),
            ],
          ),
        ),

        // 2. Story Input Panel
        Container(
          width: 320,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(right: BorderSide(color: Colors.grey.shade200)),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(
                      LucideIcons.user,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    "Story Input",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const Spacer(),
                  const Icon(LucideIcons.key, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    "Gemini API",
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Use Template Checkbox
              Row(
                children: [
                  Checkbox(
                    value: _useTemplate,
                    onChanged: (v) => setState(() => _useTemplate = v!),
                    visualDensity: VisualDensity.compact,
                  ),
                  const Text("Use Template", style: TextStyle(fontSize: 13)),
                ],
              ),

              // Dropdowns
              _buildDropdown(_selectedConsistency),
              const SizedBox(height: 8),
              _buildDropdown(
                _selectedModel,
                badge: "20",
                badgeColor: Colors.green,
              ),
              const SizedBox(height: 16),

              // Prompts & JSON
              Row(
                children: [
                  const Text(
                    "Prompts: ",
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  Container(
                    width: 50,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      "$_promptCount",
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  const Spacer(),
                  Checkbox(
                    value: _jsonOutput,
                    onChanged: (v) => setState(() => _jsonOutput = v!),
                    visualDensity: VisualDensity.compact,
                  ),
                  const Text("JSON Output", style: TextStyle(fontSize: 13)),
                ],
              ),
              const SizedBox(height: 16),

              // Tabs (Raw Story / Raw Prompt)
              Row(
                children: [
                  _buildTabBtn("RAW STORY", true),
                  const SizedBox(width: 8),
                  _buildTabBtn("RAW PROMPT", false),
                ],
              ),
              const SizedBox(height: 8),

              // Text Area
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: TextField(
                    controller: _storyController,
                    maxLines: null,
                    expands: true,
                    style: const TextStyle(fontSize: 13),
                    decoration: const InputDecoration(
                      hintText:
                          "aboy and a snai", // typo intentional from screenshot
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "4 words",
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
                  const Text(
                    "Ready",
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Buttons
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(LucideIcons.copy, size: 14),
                label: const Text("Copy Instruction"),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 40),
                  foregroundColor: Colors.blue.shade700,
                  side: BorderSide(color: Colors.blue.shade200),
                ),
              ),
              const SizedBox(height: 8),
              if (isGenerating)
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: null, // Disabled state
                        icon: const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.grey,
                          ),
                        ),
                        label: Text(
                          state.isDetecting
                              ? "Detecting..."
                              : "Detect Characters",
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.grey),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade200,
                          foregroundColor: Colors.grey,
                          elevation: 0,
                          minimumSize: const Size(0, 44),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 80,
                      height: 44,
                      child: ElevatedButton.icon(
                        onPressed: null, // Disabled in favor of auto-completion
                        icon: const Icon(LucideIcons.square, size: 14),
                        label: const Text("Stop"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              else
                ElevatedButton.icon(
                  onPressed: _startGeneration,
                  icon: const Icon(LucideIcons.sparkles, size: 16),
                  label: const Text("Generate"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(
                      0xFF3B648F,
                    ), // Blue from screenshot
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 44),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              const SizedBox(height: 16),

              // Bottom Toggles
              Row(
                children: [
                  _buildBottomToggle(LucideIcons.image, "Image to Video", true),
                  const SizedBox(width: 8),
                  _buildBottomToggle(LucideIcons.type, "Text to Video", false),
                ],
              ),
            ],
          ),
        ),

        // 3. AI Response Area (Right)
        Expanded(
          child: Container(
            color: const Color(0xFFF8FAFC), // Slate 50
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.shade200),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        LucideIcons.code,
                        size: 16,
                        color: Colors.blue,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        "AI Response",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      if (detectedCharacters.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            "${detectedCharacters.length} CHARS",
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                      const Spacer(),
                      _buildHeaderAction(
                        "Copy JSON",
                        LucideIcons.copy,
                        const Color(0xFF10B981),
                        () {
                          ref
                              .read(characterStudioProvider.notifier)
                              .copyScenesJson();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Copied to clipboard'),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                      _buildHeaderAction(
                        "Save JSON",
                        LucideIcons.save,
                        const Color(0xFF3B648F),
                        () async {
                          final appState = p.Provider.of<AppState>(
                            context,
                            listen: false,
                          );
                          final path =
                              appState.activeProject?.settings.exportPath;
                          if (path == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('No export path set for project'),
                              ),
                            );
                            return;
                          }
                          final success = await ref
                              .read(characterStudioProvider.notifier)
                              .saveScenesJson(path);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  success
                                      ? 'Saved scenes JSON'
                                      : 'Failed to save JSON',
                                ),
                              ),
                            );
                          }
                        },
                      ),
                      const SizedBox(width: 8),
                      _buildHeaderAction(
                        "Add to Studio",
                        LucideIcons.rocket,
                        const Color(0xFF8B5CF6),
                        () async {
                          final appState = p.Provider.of<AppState>(
                            context,
                            listen: false,
                          );
                          final activeProjectId = appState.activeProjectId;
                          if (activeProjectId == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('No active project'),
                              ),
                            );
                            return;
                          }

                          final success = await ref
                              .read(characterStudioProvider.notifier)
                              .addToStudio(activeProjectId);
                          if (success && mounted) {
                            ref.read(activeTabProvider.notifier).state =
                                'scene';
                          }
                        },
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(
                          LucideIcons.trash2,
                          size: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),

                // Content
                Expanded(
                  child: isGenerating
                      ? _buildProgressView(
                          state.generationProgress,
                          state.generationTotal,
                        )
                      : (state.scenesJson == null || state.scenesJson!.isEmpty)
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                LucideIcons.sparkles,
                                size: 48,
                                color: Colors.grey.shade200,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                "AI Response will appear here",
                                style: TextStyle(color: Colors.grey.shade400),
                              ),
                            ],
                          ),
                        )
                      : _buildJsonView(state.scenesJson!),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSidebarItem(IconData icon, String label, bool isSelected) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: isSelected ? Colors.blue.shade50 : Colors.transparent,
        border: isSelected
            ? const Border(left: BorderSide(color: Colors.blue, width: 3))
            : null,
      ),
      child: Column(
        children: [
          Icon(icon, color: isSelected ? Colors.blue : Colors.grey),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              color: isSelected ? Colors.blue : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown(String text, {String? badge, Color? badgeColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (badge != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: badgeColor,
                borderRadius: BorderRadius.circular(2),
              ),
              child: Text(
                badge,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          const Icon(LucideIcons.chevronDown, size: 14, color: Colors.grey),
        ],
      ),
    );
  }

  Widget _buildTabBtn(String label, bool isActive) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isActive
              ? const Color(0xFF6366F1)
              : Colors.grey.shade100, // Indigo for active
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isActive ? Colors.white : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomToggle(IconData icon, String label, bool isActive) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? Colors.blue.shade50 : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          border: isActive ? Border.all(color: Colors.blue.shade200) : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: isActive ? Colors.blue : Colors.grey),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isActive ? Colors.blue : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderAction(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressView(int progress, int total) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    LucideIcons.sparkles,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Generating Your Story Prompts",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        "Agent is refining character consistency...",
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "$progress / $total",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const LinearProgressIndicator(minHeight: 2),
        ],
      ),
    );
  }

  Widget _buildJsonView(String jsonString) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Text(
          jsonString,
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 12,
            color: Color(0xFF334155),
          ),
        ),
      ),
    );
  }
}
