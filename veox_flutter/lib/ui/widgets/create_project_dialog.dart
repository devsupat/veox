import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:lucide_icons/lucide_icons.dart';

class CreateProjectDialog extends StatefulWidget {
  final Function(String name, String exportPath) onCreate;

  const CreateProjectDialog({super.key, required this.onCreate});

  @override
  State<CreateProjectDialog> createState() => _CreateProjectDialogState();
}

class _CreateProjectDialogState extends State<CreateProjectDialog> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _pathController = TextEditingController();
  String _baseDataPath = "";

  @override
  void initState() {
    super.initState();
    _initPaths();
    _nameController.addListener(_updatePaths);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _pathController.dispose();
    super.dispose();
  }

  Future<void> _initPaths() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      // Default export path
      _pathController.text = "${dir.path}/VEOX/videos";
      setState(() {
        _baseDataPath = "${dir.path}/VEOX/projects";
      });
    } catch (e) {
      // Fallback
      _pathController.text = "/VEOX/videos";
    }
  }

  void _updatePaths() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(LucideIcons.folderPlus, color: Colors.blue, size: 24),
                const SizedBox(width: 12),
                const Text(
                  "Create New Project",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Project Name Input
            const Text(
              "Project Name",
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: TextField(
                controller: _nameController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: "Enter project name",
                  border: InputBorder.none,
                  prefixIcon: Icon(LucideIcons.folder, size: 18, color: Colors.grey),
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Export Folder Input
            const Text(
              "Export Folder (videos will be saved here)",
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: TextField(
                controller: _pathController,
                readOnly: true, // For now, maybe editable later
                style: const TextStyle(fontSize: 13, color: Colors.grey),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  prefixIcon: Icon(LucideIcons.video, size: 18, color: Colors.grey),
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Info Text
            Text(
              "Project data will be saved to:\n$_baseDataPath/${_nameController.text.isEmpty ? '<project_name>' : _nameController.text}",
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500, height: 1.4),
            ),

            const SizedBox(height: 32),

            // Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey.shade700,
                  ),
                  child: const Text("Cancel"),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () {
                    if (_nameController.text.isNotEmpty) {
                      widget.onCreate(_nameController.text, _pathController.text);
                      Navigator.pop(context);
                    }
                  },
                  icon: const Icon(LucideIcons.plus, size: 16),
                  label: const Text("Create"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
