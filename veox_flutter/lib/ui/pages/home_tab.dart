import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:veox_flutter/models/types.dart';
import 'package:veox_flutter/providers/app_state.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final TextEditingController _promptController = TextEditingController();
  String _aspectRatio = "16:9";
  String _selectedModel = "Veo 3.1 - Fast (Lower Priority)";
  String _selectedQuality = "AI Ultra (25,000 cr)";

  // Range inputs
  final TextEditingController _fromController = TextEditingController(
    text: "1",
  );
  final TextEditingController _toController = TextEditingController(
    text: "999",
  );
  bool _isBoost = false;
  String _upscale = "1080p"; // 1080p or 4K

  // Browser Controls
  int _browserCount = 2;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final scenes = appState.activeScenes;
    final isRunning = appState.isRunning;

    return Column(
      children: [
        // 1. Control Panel
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Panel: Generation Settings
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Row 1: Ratio & Model
                    Row(
                      children: [
                        const Text(
                          "Ratio: ",
                          style: TextStyle(color: Colors.grey),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            children: [
                              _buildToggleBtn(
                                "16:9",
                                _aspectRatio == "16:9",
                                (v) => setState(() => _aspectRatio = "16:9"),
                              ),
                              _buildToggleBtn(
                                "9:16",
                                _aspectRatio == "9:16",
                                (v) => setState(() => _aspectRatio = "9:16"),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Text(
                          "Model: ",
                          style: TextStyle(color: Colors.grey),
                        ),
                        Expanded(
                          child: Container(
                            height: 32,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedModel,
                                isExpanded: true,
                                items:
                                    [
                                          "Veo 3.1 - Fast (Lower Priority)",
                                          "Veo 2.0",
                                          "Gemini 1.5 Pro",
                                          "Groq Llama 3",
                                        ]
                                        .map(
                                          (e) => DropdownMenuItem(
                                            value: e,
                                            child: Text(
                                              e,
                                              style: const TextStyle(
                                                fontSize: 13,
                                              ),
                                            ),
                                          ),
                                        )
                                        .toList(),
                                onChanged: (v) =>
                                    setState(() => _selectedModel = v!),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Row 2: Frame Ops & Upscale
                    Row(
                      children: [
                        _buildOutlineBtn("First Frames", LucideIcons.image),
                        const SizedBox(width: 8),
                        _buildOutlineBtn("Last Frames", LucideIcons.image),
                        const SizedBox(width: 16),
                        const Text(
                          "Upscale: ",
                          style: TextStyle(color: Colors.grey),
                        ),
                        _buildToggleBtn(
                          "1080p",
                          _upscale == "1080p",
                          (v) => setState(() => _upscale = "1080p"),
                          color: Colors.blue,
                        ),
                        _buildToggleBtn(
                          "4K",
                          _upscale == "4K",
                          (v) => setState(() => _upscale = "4K"),
                          color: Colors.purple,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Row 3: Playback Controls
                    Row(
                      children: [
                        _buildControlBtn(
                          "Start",
                          LucideIcons.play,
                          Colors.green.shade50,
                          Colors.green,
                          () => appState.startGeneration(),
                        ),
                        const SizedBox(width: 8),
                        _buildControlBtn(
                          "Pause",
                          LucideIcons.pause,
                          Colors.grey.shade100,
                          Colors.grey,
                          null,
                        ),
                        const SizedBox(width: 8),
                        _buildControlBtn(
                          "Stop",
                          LucideIcons.square,
                          Colors.grey.shade100,
                          Colors.grey,
                          () => appState.stopGeneration(),
                        ),
                        const SizedBox(width: 8),
                        _buildControlBtn(
                          "Retry",
                          LucideIcons.refreshCw,
                          Colors.orange.shade50,
                          Colors.orange,
                          null,
                        ),
                        const SizedBox(width: 8),
                        _buildControlBtn(
                          "Resumes",
                          LucideIcons.rotateCcw,
                          Colors.grey.shade100,
                          Colors.grey,
                          null,
                        ),
                        const SizedBox(width: 8),
                        Container(
                          height: 32,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Center(
                            child: Text(
                              "1",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Row 4: Range & Boost
                    Row(
                      children: [
                        const Text(
                          "From: ",
                          style: TextStyle(color: Colors.grey),
                        ),
                        SizedBox(
                          width: 50,
                          child: _buildInput(_fromController),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          "To: ",
                          style: TextStyle(color: Colors.grey),
                        ),
                        SizedBox(width: 50, child: _buildInput(_toController)),
                        const SizedBox(width: 16),
                        const Text(
                          "10x Boost ",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Switch(
                          value: _isBoost,
                          onChanged: (v) => setState(() => _isBoost = v),
                          activeColor: Colors.purple,
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),
                    // Prompt Input
                    Container(
                      height: 40,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: TextField(
                        controller: _promptController,
                        decoration: const InputDecoration(
                          hintText:
                              "Quick prompt... e.g. A cyberpunk city in rain",
                          border: InputBorder.none,
                          hintStyle: TextStyle(
                            color: Colors.grey,
                            fontSize: 13,
                          ),
                        ),
                        onSubmitted: (val) {
                          if (val.isNotEmpty) {
                            appState.addScene(val);
                            _promptController.clear();
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 24),

              // Right Panel: Credits & Browser
              SizedBox(
                width: 300,
                child: Column(
                  children: [
                    // Credits
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.purple.shade50,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.purple.shade100),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  LucideIcons.star,
                                  size: 14,
                                  color: Colors.purple,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _selectedQuality,
                                    style: const TextStyle(
                                      color: Colors.purple,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedQuality,
                              icon: const Icon(
                                LucideIcons.chevronDown,
                                size: 14,
                              ),
                              isDense: true,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black,
                              ),
                              items:
                                  [
                                        "AI Ultra (25,000 cr)",
                                        "AI Pro (10,000 cr)",
                                        "Free Tier (Daily Limit)",
                                        "Groq (Free)",
                                      ]
                                      .map(
                                        (e) => DropdownMenuItem(
                                          value: e,
                                          child: Text(e),
                                        ),
                                      )
                                      .toList(),
                              onChanged: (v) =>
                                  setState(() => _selectedQuality = v!),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Multi-Browser Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade200),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "MULTI-BROWSER",
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Text("Count: "),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  children: [
                                    Text("$_browserCount"),
                                    const Icon(
                                      LucideIcons.chevronDown,
                                      size: 12,
                                    ),
                                  ],
                                ),
                              ),
                              const Spacer(),
                              _buildStatusBadge("Login", Colors.orange),
                              const SizedBox(width: 4),
                              _buildStatusBadge("ALL", Colors.green),
                              const SizedBox(width: 4),
                              const Icon(
                                LucideIcons.stopCircle,
                                color: Colors.red,
                                size: 20,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {},
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 0,
                                    ),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                  child: const Text(
                                    "Connect Opened",
                                    style: TextStyle(fontSize: 11),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {},
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.grey.shade700,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 0,
                                    ),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                  child: const Text(
                                    "Open No Login",
                                    style: TextStyle(fontSize: 11),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Generate Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => appState.startGeneration(),
                        icon: const Icon(LucideIcons.sparkles, size: 16),
                        label: const Text("Generate"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981), // Green
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const Icon(
                          LucideIcons.trash2,
                          size: 12,
                          color: Colors.red,
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          "Clear",
                          style: TextStyle(color: Colors.red, fontSize: 12),
                        ),
                        const SizedBox(width: 16),
                        const Icon(
                          LucideIcons.download,
                          size: 12,
                          color: Colors.blue,
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          "Export",
                          style: TextStyle(color: Colors.blue, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // 2. Scene Grid
        Expanded(
          child: Container(
            color: const Color(0xFFF9FAFB),
            padding: const EdgeInsets.all(16),
            child: scenes.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          LucideIcons.playSquare,
                          size: 64,
                          color: Colors.grey.shade200,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "Generated scenes will appear here",
                          style: TextStyle(color: Colors.grey.shade400),
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 1.2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                    itemCount: scenes.length,
                    itemBuilder: (context, index) {
                      return _buildSceneCard(scenes[index]);
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildToggleBtn(
    String label,
    bool isSelected,
    Function(bool) onTap, {
    Color color = Colors.blue,
  }) {
    return InkWell(
      onTap: () => onTap(!isSelected),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : Colors.black54,
          ),
        ),
      ),
    );
  }

  Widget _buildOutlineBtn(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.blue),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Icon(icon, size: 12, color: Colors.blue),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.blue,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlBtn(
    String label,
    IconData icon,
    Color bg,
    Color fg,
    VoidCallback? onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: fg),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: fg,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInput(TextEditingController controller) {
    return Container(
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(4),
      ),
      child: TextField(
        controller: controller,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 12),
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.only(bottom: 14),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.check, size: 10, color: Colors.white),
          const SizedBox(width: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 9,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSceneCard(Scene scene) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 30,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                  color: Colors.purple.shade50,
                  child: Text(
                    "#${scene.index.toString().padLeft(3, '0')}",
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.purple.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Icon(
                  LucideIcons.minusCircle,
                  size: 14,
                  color: Colors.orange,
                ),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: Icon(
                LucideIcons.image,
                size: 40,
                color: Colors.grey.shade200,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  scene.prompt,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11),
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
                      padding: EdgeInsets.zero,
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
