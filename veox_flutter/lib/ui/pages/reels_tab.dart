import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:veox_flutter/providers/app_state.dart';
import 'package:veox_flutter/models/types.dart';
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
  String _mode = "single";
  int _reelsCount = 1;
  int _storiesCount = 1;
  int _scenesCount = 12;
  bool _videoVoice = true;
  String _voiceLang = "English";
  bool _dubbing = false;
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

    return Row(
      children: [
        // Left Panel
        Container(
          width: 420,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(right: BorderSide(color: Colors.grey.shade200)),
          ),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text(
                "REEL/SHORTS TEMPLATES",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 12),

              SizedBox(
                height: 160,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: templates.length + 1,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    if (index == templates.length) {
                      return _buildNewTemplateCard(context);
                    }
                    final t = templates[index];
                    return _buildTemplateCard(t, _selectedTemplateId == t.id);
                  },
                ),
              ),

              const SizedBox(height: 24),

              // Form
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _topicController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText:
                            "Enter topic (e.g., A boy saves a dolphin...)",
                        hintStyle: TextStyle(fontSize: 12),
                      ),
                      onChanged: (v) => setState(() => _topic = v),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        const SizedBox(
                          width: 80,
                          child: Text(
                            "Character:",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _character,
                            decoration: const InputDecoration(
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 0,
                              ),
                              border: OutlineInputBorder(),
                            ),
                            items: ["Boy", "Girl", "Robot", "Cat"]
                                .map(
                                  (e) => DropdownMenuItem(
                                    value: e,
                                    child: Text(
                                      e,
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) => setState(() => _character = v!),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        const SizedBox(
                          width: 80,
                          child: Text(
                            "Topic Mode:",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.all(2),
                            child: Row(
                              children: [
                                Expanded(
                                  child: _buildModeBtn(
                                    "single",
                                    "Single Topic",
                                  ),
                                ),
                                Expanded(
                                  child: _buildModeBtn(
                                    "perLine",
                                    "One per Line",
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        _buildNumberInput(
                          "Reels",
                          _reelsCount,
                          (v) => setState(() => _reelsCount = v),
                        ),
                        const SizedBox(width: 8),
                        _buildNumberInput(
                          "Stories",
                          _storiesCount,
                          (v) => setState(() => _storiesCount = v),
                        ),
                        const SizedBox(width: 8),
                        _buildNumberInput(
                          "Scenes",
                          _scenesCount,
                          (v) => setState(() => _scenesCount = v),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),

                    // Toggles
                    _buildToggleRow(
                      "Video Voice",
                      _videoVoice,
                      (v) => setState(() => _videoVoice = v),
                      child: DropdownButton<String>(
                        value: _voiceLang,
                        underline: const SizedBox(),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black,
                        ),
                        items: ["English", "Indonesian", "Spanish"]
                            .map(
                              (e) => DropdownMenuItem(value: e, child: Text(e)),
                            )
                            .toList(),
                        onChanged: _videoVoice
                            ? (v) => setState(() => _voiceLang = v!)
                            : null,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildToggleRow(
                      "External Dubbing",
                      _dubbing,
                      (v) => setState(() => _dubbing = v),
                    ),

                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: _isGenerating ? null : _handleGenerate,
                        icon: _isGenerating
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(LucideIcons.clapperboard, size: 18),
                        label: Text(
                          _isGenerating ? "Generating..." : "Generate Content",
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
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
        ),

        // Right Panel
        Expanded(
          child: Container(
            color: Colors.grey.shade50,
            child: appState.reelProjects.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          LucideIcons.image,
                          size: 64,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "Add a reel project to get started",
                          style: TextStyle(color: Colors.grey.shade400),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(24),
                    itemCount: appState.reelProjects.length,
                    itemBuilder: (context, index) {
                      final p = appState.reelProjects[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(
                              context,
                            ).primaryColor.withValues(alpha: 0.1),
                            child: Icon(
                              LucideIcons.film,
                              color: Theme.of(context).primaryColor,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            p.topic,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            "${p.templateName} • ${p.character} • ${p.scenesCount} scenes",
                          ),
                          trailing: IconButton(
                            icon: const Icon(
                              LucideIcons.trash2,
                              size: 18,
                              color: Colors.red,
                            ),
                            onPressed: () => appState.deleteReelProject(p.id),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildTemplateCard(ReelTemplate t, bool isSelected) {
    return InkWell(
      onTap: () => setState(() => _selectedTemplateId = t.id),
      child: Container(
        width: 100,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: isSelected
              ? Border.all(color: Theme.of(context).primaryColor, width: 2)
              : null,
          gradient: LinearGradient(
            colors: [
              HSLColor.fromAHSL(1, t.color.toDouble(), 0.6, 0.4).toColor(),
              HSLColor.fromAHSL(1, t.color.toDouble() + 40, 0.6, 0.3).toColor(),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Theme.of(context).primaryColor.withOpacity(0.3),
                    blurRadius: 12,
                  ),
                ]
              : [],
        ),
        child: Stack(
          children: [
            if (isSelected)
              Center(
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    LucideIcons.check,
                    size: 16,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
            Positioned(
              bottom: 12,
              left: 8,
              right: 8,
              child: Text(
                t.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewTemplateCard(BuildContext context) {
    return InkWell(
      onTap: () {
        // TODO: Show dialog
        context.read<AppState>().addReelTemplate(
          ReelTemplate(
            id: const Uuid().v4(),
            name: "Custom",
            color: 300,
            image: "bg-pink",
            createdAt: DateTime.now().toIso8601String(),
          ),
        );
      },
      child: Container(
        width: 100,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.grey.shade300,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.plus, size: 20, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            const Text(
              "New",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeBtn(String mode, String label) {
    final selected = _mode == mode;
    return InkWell(
      onTap: () => setState(() => _mode = mode),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 2,
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (selected) const Icon(LucideIcons.check, size: 12),
            if (selected) const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                color: selected ? Colors.black : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNumberInput(String label, int value, Function(int) onChanged) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 32,
            child: TextField(
              controller: TextEditingController(text: value.toString()),
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: (v) => onChanged(int.tryParse(v) ?? 0),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleRow(
    String label,
    bool value,
    Function(bool) onChanged, {
    Widget? child,
  }) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (child != null) ...[const SizedBox(width: 8), child],
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Theme.of(context).primaryColor,
          ),
        ],
      ),
    );
  }

  void _handleGenerate() {
    if (_topic.isEmpty) return;
    setState(() => _isGenerating = true);

    // Simulate delay
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;

      final appState = context.read<AppState>();
      final template = appState.reelTemplates.firstWhere(
        (t) => t.id == _selectedTemplateId,
      );

      final project = ReelProject(
        id: const Uuid().v4(),
        createdAt: DateTime.now().toIso8601String(),
        templateId: template.id,
        templateName: template.name,
        topic: _topic,
        character: _character,
        topicMode: _mode,
        reelsCount: _reelsCount,
        storiesPerHint: _storiesCount,
        scenesCount: _scenesCount,
        videoVoiceEnabled: _videoVoice,
        voiceLanguage: _voiceLang,
        externalDubbingEnabled: _dubbing,
        status: "generated",
      );

      appState.addReelProject(project);
      setState(() => _isGenerating = false);
    });
  }
}
