import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart' as p;
import 'package:veox_flutter/core/database/task_model.dart';
import 'package:veox_flutter/core/utils/platform_utils.dart';
import 'package:veox_flutter/features/queue/presentation/queue_provider.dart';
import 'package:veox_flutter/providers/app_state.dart';
import 'package:veox_flutter/features/story/data/project_model.dart';
import 'package:veox_flutter/features/story/presentation/scene_builder/scene_builder_provider.dart';

class SceneBuilderTab extends ConsumerStatefulWidget {
  const SceneBuilderTab({super.key});

  @override
  ConsumerState<SceneBuilderTab> createState() => _SceneBuilderTabState();
}

class _SceneBuilderTabState extends ConsumerState<SceneBuilderTab> {
  final TextEditingController _storyJsonController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final appState = p.Provider.of<AppState>(context);
    final projectId = appState.activeProjectId;

    final state = ref.watch(sceneBuilderProvider);
    final scenes = state.scenes;
    final taskList = ref.watch(taskListProvider).value ?? [];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Left Panel (Story JSON & Controls)
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
              // Tabs
              Row(
                children: [
                  _buildTab("Controls", true),
                  _buildTab("Chars", false),
                ],
              ),
              const SizedBox(height: 16),

              // Story JSON Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "<> Story JSON",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  TextButton(
                    onPressed: () => _storyJsonController.clear(),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 0),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text("Clear", style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // JSON Input Area
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: TextField(
                    controller: _storyJsonController,
                    maxLines: null,
                    expands: true,
                    style: const TextStyle(
                      fontSize: 13,
                      fontFamily: 'monospace',
                    ),
                    decoration: const InputDecoration(
                      hintText: "Paste JSON...",
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (projectId != null) {
                          ref
                              .read(sceneBuilderProvider.notifier)
                              .loadScenesFromJson(
                                _storyJsonController.text,
                                projectId,
                              );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981), // Green
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: state.isParsing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              "Parse",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8B5CF6), // Purple
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text(
                        "Analyze & Detect Characters",
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Whisk Cookie
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Whisk Cookie",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text(
                          "•••••••••••",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            letterSpacing: 2,
                          ),
                        ),
                        const Spacer(),
                        ElevatedButton.icon(
                          onPressed: () {},
                          icon: const Icon(LucideIcons.chrome, size: 14),
                          label: const Text("Connect Browser"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3B82F6),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            textStyle: const TextStyle(fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          LucideIcons.checkSquare,
                          size: 12,
                          color: Colors.green,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "23h 46m remaining",
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Ultrafast Scene Generator
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF), // Light Indigo
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE0E7FF)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(LucideIcons.zap, size: 16, color: Colors.indigo),
                        SizedBox(width: 8),
                        Text(
                          "Ultrafast Scene Generator",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.indigo,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "No ref image upload • Model rotation • Batch processing",
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.indigo.shade300,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Text(
                          "Batch Size: ",
                          style: TextStyle(fontSize: 14, color: Colors.black54),
                        ),
                        Container(
                          width: 60,
                          height: 32,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            "5",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(LucideIcons.folderOpen, size: 14),
                        label: const Text("Load Existing Images"),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF4B5563),
                          side: const BorderSide(color: Color(0xFF9CA3AF)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {},
                        icon: const Icon(LucideIcons.zap, size: 14),
                        label: const Text("Generate 22 Images"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(
                            0xFF4F46E5,
                          ), // Indigo 600
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // 2. Right Panel (Scene Grid)
        Expanded(
          child: Column(
            children: [
              // Top Stats Bar
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildStatItem("Total", "${scenes.length}", Colors.blue),
                      const SizedBox(width: 24),
                      _buildStatItem(
                        "Generate",
                        "${scenes.length}",
                        Colors.orange,
                      ),
                      const SizedBox(width: 24),
                      _buildStatItem("Reuse", "0", Colors.green),
                      const SizedBox(width: 24),
                      _buildStatItem("Done", "0", Colors.purple),

                      const SizedBox(width: 32),
                      _buildToggle("Skip Mode", true, Colors.purple),
                      const SizedBox(width: 16),
                      _buildToggle("Paired Ref", false, Colors.grey),

                      const SizedBox(width: 32),
                      TextButton.icon(
                        onPressed: () {
                          if (appState.activeProject != null) {
                            PlatformUtils.openFolder(
                              appState.activeProject!.settings.exportPath ?? '',
                            );
                          }
                        },
                        icon: const Icon(LucideIcons.folderOpen, size: 14),
                        label: const Text("Open Output Folder"),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF4F46E5),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () {},
                        icon: const Icon(LucideIcons.trash2, size: 14),
                        label: const Text("Clear All Images"),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Green Action Bar
              Container(
                width: double.infinity,
                margin: const EdgeInsets.all(16),
                child: ElevatedButton.icon(
                  onPressed: () async {
                    if (projectId == null || appState.activeProject == null)
                      return;

                    final profileId = '1';

                    await ref
                        .read(sceneBuilderProvider.notifier)
                        .batchEnqueueVideos(
                          ref: ref,
                          profileId: profileId,
                          outputDir:
                              appState.activeProject!.settings.exportPath ?? '',
                          projectId: projectId,
                        );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Generating scenes in background…'),
                        ),
                      );
                    }
                  },
                  icon: const Icon(LucideIcons.clapperboard, size: 18),
                  label: const Text("Generate All Scenes with Characters"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981), // Green
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),

              // Grid
              Expanded(
                child: Container(
                  color: const Color(0xFFF8FAFC), // Slate 50
                  child: scenes.isEmpty
                      ? _buildEmptyState()
                      : GridView.builder(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 0,
                          ),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2, // 2 columns like screenshot
                                childAspectRatio:
                                    1.1, // Adjusted for card content
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                              ),
                          itemCount: scenes.length,
                          itemBuilder: (context, index) {
                            return _buildSceneCard(
                              index,
                              scenes[index],
                              taskList,
                            );
                          },
                        ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTab(String label, bool isActive) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isActive ? const Color(0xFF10B981) : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isActive ? const Color(0xFF10B981) : Colors.grey,
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildToggle(String label, bool value, Color activeColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(
            value ? LucideIcons.toggleRight : LucideIcons.toggleLeft,
            color: value ? activeColor : Colors.grey,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.layoutTemplate,
            size: 64,
            color: Colors.grey.shade200,
          ),
          const SizedBox(height: 16),
          Text(
            "No scenes generated yet",
            style: TextStyle(color: Colors.grey.shade400),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              ref
                  .read(sceneBuilderProvider.notifier)
                  .parseStory(
                    "A futuristic city skyline at night.\n\nA robot walking down the street.",
                    projectId: '',
                  );
            },
            child: const Text("Generate Demo Scenes"),
          ),
        ],
      ),
    );
  }

  Widget _buildSceneCard(
    int index,
    SceneModel scene,
    List<TaskModel> taskList,
  ) {
    final sceneTask = taskList.where((t) {
      if (t.payloadJson.isEmpty) return false;
      try {
        final payload = jsonDecode(t.payloadJson);
        return payload['sceneId'] == scene.sceneId;
      } catch (_) {
        return false;
      }
    }).lastOrNull;

    final bool isCompleted =
        sceneTask?.status == 'completed' && sceneTask?.outputPath != null;
    final bool isRunning =
        sceneTask?.status == 'running' || sceneTask?.status == 'queued';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4F46E5), // Indigo
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    "#${(index + 1).toString().padLeft(3, '0')}",
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const Icon(
                  LucideIcons.plusCircle,
                  size: 16,
                  color: Colors.orange,
                ),
              ],
            ),
          ),

          // Image / Video Placeholder or Status
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: isCompleted ? Colors.green.shade50 : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: isCompleted
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            LucideIcons.checkCircle,
                            size: 32,
                            color: Colors.green,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Ready",
                            style: TextStyle(
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      )
                    : isRunning
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            sceneTask?.status == 'running'
                                ? "Generating..."
                                : "Queued",
                            style: const TextStyle(
                              color: Colors.blue,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      )
                    : const Icon(
                        LucideIcons.image,
                        size: 48,
                        color: Colors.grey,
                      ),
              ),
            ),
          ),

          // Text Content
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 60,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      scene.generatedPrompt,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(LucideIcons.refreshCw, size: 12),
                    label: const Text("Generate"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4F46E5), // Indigo
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 0),
                      visualDensity: VisualDensity.compact,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
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
