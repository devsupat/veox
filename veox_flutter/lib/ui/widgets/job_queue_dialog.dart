import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:veox_flutter/features/history/providers/scene_history_provider.dart';

class JobQueueDialog extends ConsumerWidget {
  const JobQueueDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scenesAsync = ref.watch(sceneHistoryProvider);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 600,
        height: 400,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Job Queue & History",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(LucideIcons.x),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Divider(),
            Expanded(
              child: scenesAsync.when(
                data: (scenes) {
                  if (scenes.isEmpty) {
                    return const Center(child: Text("No jobs in the queue."));
                  }

                  // Sort so most recent is top
                  final sortedScenes = List.from(scenes)
                    ..sort((a, b) => b.id.compareTo(a.id));

                  return ListView.builder(
                    itemCount: sortedScenes.length,
                    itemBuilder: (context, index) {
                      final scene = sortedScenes[index];
                      final isGenerating = scene.status == "generating";

                      return ListTile(
                        leading: isGenerating
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Icon(
                                scene.status == "failed"
                                    ? LucideIcons.xCircle
                                    : LucideIcons.checkCircle,
                                color: scene.status == "failed"
                                    ? Colors.red
                                    : Colors.green,
                              ),
                        title: Text(
                          scene.generatedPrompt.isNotEmpty
                              ? scene.generatedPrompt
                              : "Empty Prompt",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          "Status: ${scene.status} | ID: ${scene.id}",
                        ),
                        trailing: IconButton(
                          icon: const Icon(
                            LucideIcons.trash2,
                            color: Colors.red,
                          ),
                          onPressed: () {
                            // TODO: Add delete logic
                          },
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, st) =>
                    Center(child: Text("Error loading queue: $e")),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
