import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:veox_flutter/features/story/data/project_model.dart';
import 'package:veox_flutter/features/story/presentation/scene_builder/scene_builder_provider.dart';

class SceneBuilderTab extends ConsumerStatefulWidget {
  const SceneBuilderTab({super.key});

  @override
  ConsumerState<SceneBuilderTab> createState() => _SceneBuilderTabState();
}

class _SceneBuilderTabState extends ConsumerState<SceneBuilderTab> {
  // We don't need a controller for "story input" in the new design.
  // The scenes are generated from the "Create Story" tab (previous step).
  // But for now, let's assume we just display the generated scenes in a grid.

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(sceneBuilderProvider);
    final scenes = state.scenes;

    return Column(
      children: [
        // 1. Top Bar (Stats & Actions)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
          ),
          child: Row(
            children: [
              // Stats
              _buildStatItem("Total", "${scenes.length}", Colors.blue),
              const SizedBox(width: 24),
              _buildStatItem("Generate", "${scenes.length}", Colors.orange),
              const SizedBox(width: 24),
              _buildStatItem("Reruns", "0", Colors.green),
              const SizedBox(width: 24),
              _buildStatItem("Done", "0", Colors.purple),

              const Spacer(),

              // Toggles
              _buildToggle("Skip Mode", true),
              const SizedBox(width: 16),
              _buildToggle("Paired Ref", false),
              const SizedBox(width: 16),
              
              // Actions
              TextButton.icon(
                onPressed: () {},
                icon: const Icon(LucideIcons.folderOpen, size: 16),
                label: const Text("Open Output Folder"),
                style: TextButton.styleFrom(foregroundColor: Colors.purple),
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(LucideIcons.trash2, size: 18, color: Colors.red),
              ),
            ],
          ),
        ),

        // 2. Main Action Bar
        Container(
          width: double.infinity,
          margin: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: () {
               ref.read(sceneBuilderProvider.notifier).renderAllScenes();
               ScaffoldMessenger.of(context).showSnackBar(
                 const SnackBar(content: Text('Scenes added to Render Queue')),
               );
            },
            icon: const Icon(LucideIcons.clapperboard, size: 18),
            label: const Text("Generate All Scenes with Characters"),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981), // Green
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),

        // 3. Scene Grid
        Expanded(
          child: scenes.isEmpty
              ? _buildEmptyState()
              : GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3, // 3 columns like screenshot
                    childAspectRatio: 0.85, // Taller cards for image + text
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: scenes.length,
                  itemBuilder: (context, index) {
                    return _buildSceneCard(index, scenes[index]);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildToggle(String label, bool value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(value ? LucideIcons.toggleRight : LucideIcons.toggleLeft, 
               color: value ? Colors.purple : Colors.grey, size: 20),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.layoutTemplate, size: 64, color: Colors.grey.shade200),
          const SizedBox(height: 16),
          Text("No scenes generated yet", style: TextStyle(color: Colors.grey.shade400)),
          const SizedBox(height: 8),
          TextButton(
             onPressed: () {
               // Mock generation for demo if empty
               ref.read(sceneBuilderProvider.notifier).generateScenesFromStory(
                 "A futuristic city skyline at night.\n\nA robot walking down the street."
               );
             }, 
             child: const Text("Generate Demo Scenes")
          )
        ],
      ),
    );
  }

  Widget _buildSceneCard(int index, SceneModel scene) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 4, offset: const Offset(0, 2)),
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
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    "#${(index + 1).toString().padLeft(3, '0')}",
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.purple.shade700),
                  ),
                ),
                const Icon(LucideIcons.minusCircle, size: 16, color: Colors.orange),
              ],
            ),
          ),

          // Image Placeholder
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: const Center(
                child: Icon(LucideIcons.image, size: 32, color: Colors.grey),
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
                  height: 60, // Fixed height for text area
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      scene.generatedPrompt,
                      style: const TextStyle(fontSize: 11, color: Colors.black87),
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
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 0),
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
