import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class MasteringTab extends StatefulWidget {
  const MasteringTab({super.key});

  @override
  State<MasteringTab> createState() => _MasteringTabState();
}

class _MasteringTabState extends State<MasteringTab> {
  final String _bgMusicPrompt = "Upbeat synthwave with driving bassline";

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Upper Section (3 Panels)
        Expanded(
          flex: 3,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Left Media & Generators
              Container(
                width: 300,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    right: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Media",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Media Buttons Grid
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      childAspectRatio: 2.5,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _buildMediaBtn("Video", LucideIcons.video, Colors.blue),
                        _buildMediaBtn(
                          "Audio",
                          LucideIcons.music,
                          Colors.green,
                        ),
                        _buildMediaBtn("Image", LucideIcons.image, Colors.teal),
                        _buildMediaBtn("Text", LucideIcons.type, Colors.orange),
                        _buildMediaBtn(
                          "Intro",
                          LucideIcons.playCircle,
                          Colors.amber,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // BG Music Generator
                    const Text(
                      "BG Music Generator",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: const Text(
                        "Upbeat electronic music with driving bass",
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {},
                        icon: const Icon(LucideIcons.music, size: 16),
                        label: const Text("Generate"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          foregroundColor: Colors.white,
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
                        icon: const Icon(LucideIcons.folderOpen, size: 16),
                        label: const Text("Story AI Music"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),
                    const Text(
                      "Voice Audio Generator",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {},
                        icon: const Icon(LucideIcons.mic, size: 16),
                        label: const Text("Generate Audio Clips"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 2. Middle Preview
              Expanded(
                child: Container(
                  color: const Color(0xFFF1F5F9), // Slate 100
                  child: Row(
                    children: [
                      // Defeats Sidebar (Vertical)
                      Container(
                        width: 60,
                        color: Colors.white,
                        child: Column(
                          children: [
                            Container(
                              width: double.infinity,
                              color: Colors.blue,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: const Text(
                                "Defeits",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildVerticalTool(
                              "Text",
                              LucideIcons.arrowRight,
                              Colors.blue,
                            ),
                            const SizedBox(height: 8),
                            _buildVerticalTool("Intro", null, Colors.blue),
                            const SizedBox(height: 8),
                            _buildVerticalTool(
                              "Outro",
                              LucideIcons.video,
                              Colors.purple,
                            ),
                            const SizedBox(height: 8),
                            _buildVerticalTool(
                              "Tatto",
                              null,
                              Colors.grey,
                              label2: "OFF 0.2",
                            ),
                          ],
                        ),
                      ),

                      // Video Player Area
                      Expanded(
                        child: Column(
                          children: [
                            Expanded(
                              child: Container(
                                color: Colors.black,
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        LucideIcons.clapperboard,
                                        size: 64,
                                        color: Colors.grey.shade700,
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        "Import videos to get started",
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            // Player Controls
                            Container(
                              height: 48,
                              color: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: Row(
                                children: [
                                  const Text(
                                    "00:00:00",
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  const Icon(LucideIcons.skipBack, size: 16),
                                  const SizedBox(width: 16),
                                  const Icon(
                                    LucideIcons.playCircle,
                                    size: 24,
                                    color: Colors.green,
                                  ),
                                  const SizedBox(width: 16),
                                  const Icon(LucideIcons.skipForward, size: 16),
                                  const SizedBox(width: 16),
                                  const Icon(
                                    LucideIcons.trash2,
                                    size: 16,
                                    color: Colors.red,
                                  ),
                                  const Spacer(),
                                  const Icon(LucideIcons.volume2, size: 16),
                                  const SizedBox(width: 8),
                                  Container(
                                    width: 80,
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade300,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: Container(
                                        width: 40,
                                        height: 4,
                                        color: Colors.blue,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 3. Right Music Controls
              Container(
                width: 320,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(left: BorderSide(color: Colors.grey.shade200)),
                ),
                child: Column(
                  children: [
                    // Tabs
                    Row(
                      children: [
                        _buildRightTab("All Music", true),
                        _buildRightTab("Clip", false),
                        _buildRightTab("Color", false),
                        _buildRightTab("Audio", false),
                        _buildRightTab("Logo", false),
                      ],
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Status Header
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Tooltip(
                                  message:
                                      "Mastering features are coming in Phase 3.",
                                  child: ElevatedButton.icon(
                                    onPressed: null,
                                    icon: const Icon(
                                      LucideIcons.play,
                                      size: 12,
                                    ),
                                    label: const Text("Start"),
                                    style: ElevatedButton.styleFrom(
                                      disabledBackgroundColor:
                                          Colors.blue.shade100,
                                      disabledForegroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                      ),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                  ),
                                ),
                                const Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      "All Music",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue,
                                      ),
                                    ),
                                    Text(
                                      "Ready",
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.orange,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Generate Button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () {},
                                icon: const Icon(
                                  LucideIcons.bookOpen,
                                  size: 16,
                                ),
                                label: const Text("Generate from Story Prompt"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // JSON Actions
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                TextButton.icon(
                                  onPressed: () {},
                                  icon: const Icon(LucideIcons.code, size: 14),
                                  label: const Text("Paste JSON"),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.blue,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                TextButton.icon(
                                  onPressed: () {},
                                  icon: const Icon(
                                    LucideIcons.upload,
                                    size: 14,
                                  ),
                                  label: const Text("Import JSON"),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.purple,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Manual Prompt
                            const Text(
                              "Or configure manually",
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Manual Prompt",
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(
                                        LucideIcons.pencil,
                                        size: 14,
                                        color: Colors.grey,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _bgMusicPrompt,
                                          style: const TextStyle(
                                            color: Colors.blue,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Sliders
                            _buildSlider("BPM: 120", 0.6),
                            const SizedBox(height: 16),
                            _buildSlider("Density: 0.5", 0.5),
                            const SizedBox(height: 16),
                            _buildSlider("Bright: 0.5", 0.5),

                            const SizedBox(height: 24),

                            // Record Button
                            Center(
                              child: ElevatedButton.icon(
                                onPressed: null, // Disabled in screenshot
                                icon: const Icon(LucideIcons.circle, size: 12),
                                label: const Text("Record to Timeline"),
                                style: ElevatedButton.styleFrom(
                                  disabledBackgroundColor: Colors.grey.shade200,
                                  disabledForegroundColor: Colors.grey,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Timeline (Bottom)
        Container(
          height: 200,
          color: const Color(0xFF1E293B), // Dark slate
          child: Column(
            children: [
              // Timeline Header
              Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: const BoxDecoration(
                  color: Color(0xFF334155),
                  border: Border(bottom: BorderSide(color: Color(0xFF475569))),
                ),
                child: Row(
                  children: [
                    const Icon(LucideIcons.menu, color: Colors.white, size: 16),
                    const SizedBox(width: 16),
                    const Text(
                      "Ripple Fill",
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    const SizedBox(width: 16),
                    const Icon(
                      LucideIcons.arrowLeft,
                      color: Colors.white,
                      size: 16,
                    ),
                    const Spacer(),
                    const Icon(
                      LucideIcons.maximize,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 16),
                    const Icon(
                      LucideIcons.minusCircle,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Container(width: 100, height: 4, color: Colors.grey),
                    const SizedBox(width: 8),
                    const Icon(
                      LucideIcons.plusCircle,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      "100%",
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
              ),

              // Tracks
              Expanded(
                child: Row(
                  children: [
                    // Track Heads
                    Container(
                      width: 60,
                      color: const Color(0xFF334155),
                      child: Column(
                        children: [
                          _buildTrackHead("Video", "100%", Colors.white),
                          _buildTrackHead("Audio", "50%", Colors.blue.shade200),
                        ],
                      ),
                    ),

                    // Timeline Area
                    Expanded(
                      child: Stack(
                        children: [
                          // Grid Lines
                          Row(
                            children: List.generate(
                              20,
                              (index) => Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    border: Border(
                                      right: BorderSide(
                                        color: Colors.white.withValues(
                                          alpha: 0.05,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // Time Markers
                          const Positioned(
                            top: 4,
                            left: 100,
                            child: Text(
                              "5s",
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 10,
                              ),
                            ),
                          ),
                          const Positioned(
                            top: 4,
                            left: 200,
                            child: Text(
                              "10s",
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 10,
                              ),
                            ),
                          ),

                          // Playhead
                          Positioned(
                            left: 40,
                            top: 0,
                            bottom: 0,
                            child: Container(width: 2, color: Colors.white),
                          ),
                          Positioned(
                            left: 35,
                            top: 0,
                            child: Container(
                              width: 12,
                              height: 12,
                              color: Colors.white,
                            ),
                          ),

                          // Tracks Content
                          Column(
                            children: [
                              Container(height: 60), // Video Track space
                              Container(
                                height: 30,
                                margin: const EdgeInsets.only(left: 2),
                                width: double.infinity,
                                color: Colors.green.withValues(alpha: 0.2),
                                alignment: Alignment.centerLeft,
                                padding: const EdgeInsets.only(left: 8),
                                child: const Row(
                                  children: [
                                    Icon(
                                      LucideIcons.check,
                                      size: 12,
                                      color: Colors.green,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      "Audio 0 Clips",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMediaBtn(String label, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalTool(
    String label,
    IconData? icon,
    Color color, {
    String? label2,
  }) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) Icon(icon, size: 14, color: Colors.white),
          if (label2 != null)
            Text(
              label2,
              style: const TextStyle(fontSize: 8, color: Colors.white),
            ),
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildRightTab(String label, bool isActive) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isActive ? Colors.blue : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            color: isActive ? Colors.blue : Colors.grey,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildSlider(String label, double value) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
        SizedBox(
          height: 24,
          child: Slider(
            value: value,
            onChanged: (v) {},
            activeColor: const Color(0xFF3B82F6),
          ),
        ),
      ],
    );
  }

  Widget _buildTrackHead(String label, String value, Color color) {
    return Container(
      height: 60,
      width: double.infinity,
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF475569))),
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(color: color.withValues(alpha: 0.7), fontSize: 10),
          ),
        ],
      ),
    );
  }
}
