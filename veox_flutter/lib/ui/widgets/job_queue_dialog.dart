import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:veox_flutter/features/queue/presentation/queue_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class JobQueueDialog extends ConsumerWidget {
  const JobQueueDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(taskListProvider);

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
              child: tasksAsync.when(
                data: (tasks) {
                  if (tasks.isEmpty) {
                    return const Center(child: Text("No jobs in the queue."));
                  }

                  // Sort so most recent is top
                  final sortedTasks = List.from(tasks)
                    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

                  return ListView.builder(
                    itemCount: sortedTasks.length,
                    itemBuilder: (context, index) {
                      final task = sortedTasks[index];
                      final isGenerating =
                          task.status == "running" ||
                          task.status == "pending" ||
                          task.status == 'retrying';

                      IconData statusIcon = LucideIcons.circle;
                      Color statusColor = Colors.grey;

                      if (task.status == 'running') {
                        statusIcon = LucideIcons.loader;
                        statusColor = Colors.blue;
                      } else if (task.status == 'completed') {
                        statusIcon = LucideIcons.checkCircle;
                        statusColor = Colors.green;
                      } else if (task.status == 'failed') {
                        statusIcon = LucideIcons.xCircle;
                        statusColor = Colors.red;
                      } else if (task.status == 'canceled') {
                        statusIcon = LucideIcons.minusCircle;
                        statusColor = Colors.grey;
                      } else if (task.status == 'paused_needs_login') {
                        statusIcon = LucideIcons.pauseCircle;
                        statusColor = Colors.orange;
                      }

                      // Error tag
                      String statusText = task.status;
                      if (task.status == 'failed' &&
                          task.errorCategory != null) {
                        statusText = "failed (${task.errorCategory})";
                      }

                      // Debug Artifact action
                      Widget? subtitleAction;
                      if (task.status == 'failed') {
                        // Check if debug folder exists
                        subtitleAction = InkWell(
                          onTap: () async {
                            // Use url_launcher to open the directory
                            final appDocDir =
                                await getApplicationDocumentsDirectory();
                            final debugDir = Directory(
                              p.join(appDocDir.path, 'VEOX', 'videos', 'debug'),
                            );
                            if (debugDir.existsSync()) {
                              final uri = Uri.directory(debugDir.path);
                              if (await canLaunchUrl(uri)) {
                                await launchUrl(uri);
                              }
                            }
                          },
                          child: const Text(
                            ' Open Debug',
                            style: TextStyle(
                              color: Colors.blue,
                              fontSize: 12,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        );
                      }

                      return ListTile(
                        leading: isGenerating
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Icon(statusIcon, color: statusColor),
                        title: Text(
                          task.type,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Row(
                          children: [
                            Text(
                              "Status: $statusText | ID: ${task.taskId.substring(0, 8)}...",
                            ),
                            if (subtitleAction != null) subtitleAction,
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(
                            LucideIcons.trash2,
                            color: Colors.red,
                          ),
                          onPressed: () {
                            // TODO: Add delete logic via QueueService
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
