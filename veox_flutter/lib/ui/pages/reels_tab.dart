import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:veox_flutter/providers/app_state.dart';
import 'package:veox_flutter/models/types.dart';
import 'package:veox_flutter/ui/widgets/create_reel_template_dialog.dart';
import 'package:uuid/uuid.dart';

class ReelsTab extends StatefulWidget {
  const ReelsTab({super.key});

  @override
  State<ReelsTab> createState() => _ReelsTabState();
}

class _ReelsTabState extends State<ReelsTab> {
  String? _selectedTemplateId;
  String _topic = "";
  String _character = "Boy";
  String _voiceLang = "English";
  String _mode = "single";
  int _reelsCount = 1;
  int _storiesCount = 1;
  int _scenesCount = 12;
  bool _voiceCue = true;
  bool _isGenerating = false;

  final TextEditingController _topicController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appState = Provider.of<AppState>(context, listen: false);
      if (appState.reelTemplates.isNotEmpty) {
        setState(() {
          _selectedTemplateId = appState.reelTemplates.first.id;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final templates = appState.reelTemplates;

    return Column(
      children: [
        // Blue Header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          color: const Color(0xFF93C5FD), // Light blue from screenshot
          child: const Row(
            children: [
              Icon(
                LucideIcons.clapperboard,
                size: 20,
                color: Color(0xFF1E293B),
              ),
              SizedBox(width: 12),
              Text(
                "Bulk Reels/Shorts Create",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left Panel (Controls)
              Container(
                width: 380,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    right: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Topic Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Topic",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const Icon(
                          LucideIcons.folder,
                          size: 16,
                          color: Colors.grey,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Template Selector
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Template:",
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        Row(
                          children: [
                            InkWell(
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (context) =>
                                      CreateReelTemplateDialog(
                                        onSave: (name) {
                                          final appState = context
                                              .read<AppState>();
                                          appState.addReelTemplate(
                                            ReelTemplate(
                                              id: const Uuid().v4(),
                                              name: name,
                                              color: 200,
                                              image: "bg-blue",
                                              createdAt: DateTime.now()
                                                  .toIso8601String(),
                                            ),
                                          );
                                        },
                                      ),
                                );
                              },
                              child: const Icon(
                                LucideIcons.plusCircle,
                                size: 16,
                                color: Colors.purple,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              LucideIcons.moreHorizontal,
                              size: 16,
                              color: Colors.grey,
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Template Card (Selected)
                    if (templates.isNotEmpty)
                      Container(
                        width: 100,
                        height: 140,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          image: const DecorationImage(
                            image: NetworkImage(
                              "https://picsum.photos/200/300",
                            ), // Placeholder
                            fit: BoxFit.cover,
                          ),
                          border: Border.all(color: Colors.purple, width: 2),
                        ),
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          color: Colors.black54,
                          child: const Text(
                            "Boy Saves Anim...",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white, fontSize: 10),
                          ),
                        ),
                      ),

                    const SizedBox(height: 16),

                    // Topic Input
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: TextField(
                        controller: _topicController,
                        maxLines: 2,
                        style: const TextStyle(fontSize: 13),
                        decoration: const InputDecoration(
                          hintText:
                              "Enter topic (e.g., A boy saves a dolphin...)",
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.all(12),
                        ),
                        onChanged: (v) => setState(() => _topic = v),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Browser Connected Status
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5), // Light green
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFD1FAE5)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            LucideIcons.checkCircle,
                            size: 14,
                            color: Colors.green,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            "1 browser(s) connected",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: Colors.green.withValues(alpha: 0.3),
                              ),
                            ),
                            child: const Row(
                              children: [
                                Icon(
                                  LucideIcons.link,
                                  size: 10,
                                  color: Colors.grey,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  "Connect All",
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Character & Voice Over
                    Row(
                      children: [
                        Expanded(
                          child: _buildInlineInput("Character:", _character),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildInlineInput(
                            "Voice Over Language:",
                            _voiceLang,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Topic Mode
                    Row(
                      children: [
                        const Text(
                          "Topic Mode: ",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            children: [
                              _buildModeBtn("single", "Single Topic", true),
                              _buildModeBtn("perLine", "One per Line", false),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Settings Row
                    Row(
                      children: [
                        _buildSmallInput("Reels:", "$_reelsCount"),
                        const SizedBox(width: 8),
                        _buildSmallInput("Stories/Hint:", "$_storiesCount"),
                        const SizedBox(width: 8),
                        _buildSmallInput("Scenes:", "$_scenesCount"),
                        const SizedBox(width: 12),
                        const Text(
                          "Voice Cue:",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Switch(
                          value: _voiceCue,
                          onChanged: (v) => setState(() => _voiceCue = v),
                          activeColor: const Color(0xFF3B648F),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    _buildInlineInput("Voice Cue Language:", "English"),
                    const Spacer(),

                    // Generate Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isGenerating ? null : _handleGenerate,
                        icon: const Icon(LucideIcons.clapperboard, size: 16),
                        label: Text(
                          _isGenerating ? "Generating..." : "Generate Content",
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6366F1), // Indigo
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Right Panel (Preview)
              Expanded(
                child: Container(
                  color: const Color(0xFFF8FAFC),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          LucideIcons.image,
                          size: 48,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "image to video",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.yellow.shade700,
                            shadows: const [
                              Shadow(
                                offset: Offset(0, 1),
                                blurRadius: 2,
                                color: Colors.black12,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInlineInput(String label, String value) {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8, right: 4),
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: TextField(
              controller: TextEditingController(text: value),
              style: const TextStyle(fontSize: 12),
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.only(bottom: 12, left: 4),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallInput(String label, String value) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.grey,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 4),
        Container(
          width: 30,
          height: 24,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(value, style: const TextStyle(fontSize: 11)),
        ),
      ],
    );
  }

  Widget _buildModeBtn(String mode, String label, bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isActive
            ? const Color(0xFFDBEAFE)
            : Colors.transparent, // Light blue active
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          if (isActive)
            const Icon(LucideIcons.check, size: 10, color: Colors.blue),
          if (isActive) const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isActive ? Colors.blue.shade800 : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  void _handleGenerate() {
    if (_topic.isEmpty) return;
    setState(() => _isGenerating = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _isGenerating = false);
    });
  }
}
