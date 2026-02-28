import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class AiVoiceTab extends StatefulWidget {
  const AiVoiceTab({super.key});

  @override
  State<AiVoiceTab> createState() => _AiVoiceTabState();
}

class _AiVoiceTabState extends State<AiVoiceTab> {
  String _selectedVoice = "Male - Deep";
  String _selectedModel = "Gemini TTS";
  String _selectedPreset = "Natural";
  double _pace = 1.0;
  String _selectedTone = "Neutral";
  String _selectedStyle = "Conversational";
  final TextEditingController _textController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Voice Settings Panel
        Container(
          width: 280,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            border: Border(right: BorderSide(color: Colors.grey.shade200)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Voice Settings",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 24),
              
              _buildDropdown("VOICE", _selectedVoice, ["Male - Deep", "Female - Soft", "Male - Energetic"], (v) => setState(() => _selectedVoice = v!)),
              const SizedBox(height: 16),
              
              _buildDropdown("MODEL", _selectedModel, ["Gemini TTS", "ElevenLabs", "Azure TTS"], (v) => setState(() => _selectedModel = v!)),
              const SizedBox(height: 16),
              
              const Text("PRESETS", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ["Natural", "Energetic", "Calm", "Storyteller", "Podcast"].map((preset) {
                  final isSelected = _selectedPreset == preset;
                  return InkWell(
                    onTap: () => setState(() => _selectedPreset = preset),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.blue : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: isSelected ? Colors.blue : Colors.grey.shade300),
                      ),
                      child: Text(
                        preset,
                        style: TextStyle(
                          fontSize: 11,
                          color: isSelected ? Colors.white : Colors.grey.shade700,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              
              const Text("PACE", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
              SliderTheme(
                data: SliderThemeData(
                  trackHeight: 4,
                  activeTrackColor: Colors.blue,
                  inactiveTrackColor: Colors.grey.shade200,
                  thumbColor: Colors.blue,
                  overlayColor: Colors.blue.withValues(alpha: 0.1),
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                ),
                child: Slider(
                  value: _pace,
                  min: 0.5,
                  max: 2.0,
                  onChanged: (v) => setState(() => _pace = v),
                ),
              ),
              Text("${_pace.toStringAsFixed(1)}x", style: const TextStyle(fontSize: 10, color: Colors.grey)),
              const SizedBox(height: 16),
              
              _buildDropdown("TONE", _selectedTone, ["Neutral", "Happy", "Sad", "Angry"], (v) => setState(() => _selectedTone = v!)),
              const SizedBox(height: 16),
              
              _buildDropdown("STYLE", _selectedStyle, ["Conversational", "Narrative", "News"], (v) => setState(() => _selectedStyle = v!)),
            ],
          ),
        ),

        // Text Input Area
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(20),
            color: Colors.grey.shade50,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Text to Generate",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: TextField(
                      controller: _textController,
                      maxLines: null,
                      expands: true,
                      decoration: const InputDecoration(
                        hintText: "Enter or paste your text here...",
                        border: InputBorder.none,
                      ),
                      onChanged: (v) => setState(() {}),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "${_textController.text.length} characters",
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        // TODO: Implement generation logic
                      },
                      icon: const Icon(LucideIcons.mic, size: 16),
                      label: const Text("Generate Voice"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown(String label, String value, List<String> items, Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              icon: const Icon(LucideIcons.chevronDown, size: 16, color: Colors.grey),
              style: const TextStyle(fontSize: 13, color: Colors.black),
              items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
