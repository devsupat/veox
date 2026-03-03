import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:veox_flutter/providers/app_state.dart';
import 'package:veox_flutter/providers/navigation_provider.dart';
import 'package:veox_flutter/ui/pages/home_tab.dart';
import 'package:veox_flutter/ui/pages/reels_tab.dart';
import 'package:veox_flutter/ui/pages/projects_tab.dart';
import 'package:veox_flutter/ui/pages/ai_voice_tab.dart';
import 'package:veox_flutter/ui/pages/settings_tab.dart';
import 'package:veox_flutter/ui/pages/mastering_tab.dart';
import 'package:veox_flutter/features/story/presentation/character_studio_tab.dart';
import 'package:veox_flutter/features/story/presentation/scene_builder/scene_builder_tab.dart';
import 'package:veox_flutter/ui/pages/clone_tab.dart';
import 'package:veox_flutter/ui/widgets/create_project_dialog.dart';
import 'package:veox_flutter/ui/widgets/paste_prompts_dialog.dart';

class MainLayout extends ConsumerStatefulWidget {
  const MainLayout({super.key});

  @override
  ConsumerState<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends ConsumerState<MainLayout> {
  bool _terminalExpanded = false;

  @override
  void initState() {
    super.initState();
    // Default to projects if no active project
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appState = context.read<AppState>();
      if (appState.activeProjectId == null) {
        ref.read(activeTabProvider.notifier).state = 'projects';
      }
    });
  }

  void _handleSidebarAction(String action) {
    if (action == "paste_prompts") {
      showDialog(
        context: context,
        builder: (context) => PastePromptsDialog(
          onPromptsAdded: (prompts) {
            final appState = context.read<AppState>();
            for (final prompt in prompts) {
              appState.addScene(prompt);
            }
          },
        ),
      );
    } else if (action == "create_project") {
      showDialog(
        context: context,
        builder: (context) => CreateProjectDialog(
          onCreate: (name, path) {
            context.read<AppState>().createProject(name, exportPath: path);
          },
        ),
      );
    }
  }

  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final activeTab = ref.watch(activeTabProvider);

    Widget content;
    switch (activeTab) {
      case 'home':
        content = const HomeTab();
        break;
      case 'clone':
        content = const CloneTab();
        break;
      case 'mastering':
        content = const MasteringTab();
        break;
      case 'reels':
        content = const ReelsTab();
        break;
      case 'projects':
        content = ProjectsTab(
          onProjectSelected: () =>
              ref.read(activeTabProvider.notifier).state = 'home',
        );
        break;
      case 'aivoice':
        content = const AiVoiceTab();
        break;
      case 'settings':
        content = const SettingsTab();
        break;
      case 'character':
        content = const CharacterStudioTab();
        break;
      case 'scene':
        content = const SceneBuilderTab();
        break;
      default:
        content = Center(child: Text("Coming Soon: $activeTab"));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Slate 50 background
      body: Column(
        children: [
          // Top Nav
          _buildTopNav(context),

          // Main Body
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Sidebar (Navigator) - Hide for clone and mastering tab
                if (activeTab != 'clone' && activeTab != 'mastering')
                  _buildLeftSidebar(context, appState),

                // Content
                Expanded(
                  child: (activeTab == 'clone' || activeTab == 'mastering')
                      ? content // Full width/height for immersive tabs
                      : Container(
                          margin: const EdgeInsets.all(16),
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
                          clipBehavior: Clip.antiAlias,
                          child: content,
                        ),
                ),

                // Right Sidebar (Status) - Hide for clone and mastering tab
                if (activeTab != 'clone' && activeTab != 'mastering')
                  _buildRightSidebar(context, appState),
              ],
            ),
          ),

          // Terminal Drawer
          _buildTerminalDrawer(context, appState),
        ],
      ),
    );
  }

  Widget _buildTopNav(BuildContext context) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Logo
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              "VEOX",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontFamily: 'Space Grotesk',
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 24),

          // Navigation Items
          Expanded(
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildTab("home", "Home", LucideIcons.home),
                _buildTab("character", "Character Studio", LucideIcons.users),
                _buildTab("scene", "Scene Builder", LucideIcons.clapperboard),
                _buildTab("clone", "Clone Youtube", LucideIcons.youtube),
                _buildTab("mastering", "Mastering", LucideIcons.sliders),
                _buildTab("reels", "Reels", LucideIcons.film),
                _buildTab("avmatch", "AV Match", LucideIcons.zap),
                _buildTab("settings", "Settings", LucideIcons.settings),
                _buildTab("export", "Export", LucideIcons.download),
                _buildTab("aivoice", "AI Voice", LucideIcons.mic),
                _buildTab("more", "More", LucideIcons.moreHorizontal),
              ],
            ),
          ),

          const SizedBox(width: 16),
          // Right Controls
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(LucideIcons.refreshCw, size: 14),
            label: const Text("Update", style: TextStyle(fontSize: 12)),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Colors.orange, Colors.amber],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              children: [
                Icon(LucideIcons.crown, size: 12, color: Colors.white),
                SizedBox(width: 4),
                Text(
                  "PREMIUM",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          const CircleAvatar(
            radius: 16,
            backgroundColor: Colors.grey,
            child: Icon(LucideIcons.user, size: 16, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildLeftSidebar(BuildContext context, AppState appState) {
    return Container(
      width: 240,
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Navigator",
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          _buildSidebarSection("FILE OPERATIONS"),
          _buildSidebarItem(
            LucideIcons.folderPlus,
            "Create New Project",
            onTap: () => _handleSidebarAction("create_project"),
          ),
          _buildSidebarItem(LucideIcons.upload, "Load Prompts", onTap: () {}),
          _buildSidebarItem(
            LucideIcons.clipboard,
            "Paste Prompts",
            onTap: () => _handleSidebarAction("paste_prompts"),
          ),
          _buildSidebarItem(LucideIcons.save, "Save Project", onTap: () {}),
          _buildSidebarItem(
            LucideIcons.folderOpen,
            "Open Output",
            onTap: () {},
          ),

          const SizedBox(height: 24),
          _buildSidebarSection("FRAME OPERATIONS"),
          _buildSidebarItem(
            LucideIcons.image,
            "Import First Frames",
            onTap: () {},
          ),
          _buildSidebarItem(
            LucideIcons.image,
            "Import Last Frames",
            onTap: () {},
          ),

          const SizedBox(height: 24),
          _buildSidebarSection("ACTIONS"),
          _buildSidebarItem(LucideIcons.zap, "Heavy Bulk Tasks", onTap: () {}),
        ],
      ),
    );
  }

  Widget _buildRightSidebar(BuildContext context, AppState appState) {
    final stats = appState.stats;

    return Container(
      width: 280,
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatusCard("Processing Queue", [
            _buildQueueItem(Colors.green, "Voice Generation", true),
            _buildQueueItem(
              Colors.orange,
              "Audio Processing",
              appState.isRunning,
            ),
            _buildQueueItem(Colors.grey, "Noise Reduction", false),
          ]),
          const SizedBox(height: 16),
          _buildStatusCard("Generated Files", [
            _buildFileItem("intro_narration.wav", "0:32"),
            _buildFileItem("scene_dialogue.wav", "1:05"),
            _buildFileItem("outro_voice.wav", "0:10"),
          ]),
          const SizedBox(height: 16),
          const Text(
            "Status",
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem("Total", stats['total'] ?? 0),
                    _buildStatItem("Done", stats['done'] ?? 0),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem("Active", stats['active'] ?? 0),
                    _buildStatItem(
                      "Failed",
                      stats['failed'] ?? 0,
                      isError: true,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            "MULTI-BROWSER",
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(LucideIcons.logIn, size: 14),
              label: const Text("Login"),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Row(
              children: [
                Icon(LucideIcons.circle, size: 8, color: Colors.green),
                SizedBox(width: 8),
                Text(
                  "Connected 2/2",
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTerminalDrawer(BuildContext context, AppState appState) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: _terminalExpanded ? MediaQuery.of(context).size.height * 0.3 : 33,
      decoration: BoxDecoration(
        color: const Color(0xFF09090B), // Zinc 950
        border: Border(top: BorderSide(color: Colors.grey.shade800)),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _terminalExpanded = !_terminalExpanded),
            child: Container(
              height: 32,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  const Icon(
                    LucideIcons.terminal,
                    size: 12,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    "Terminal / Logs",
                    style: TextStyle(color: Colors.grey, fontSize: 11),
                  ),
                  const Spacer(),
                  Icon(
                    _terminalExpanded
                        ? LucideIcons.chevronDown
                        : LucideIcons.chevronUp,
                    size: 12,
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
          ),
          if (_terminalExpanded)
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: appState.logs.length,
                itemBuilder: (context, index) {
                  final log = appState.logs[index];
                  Color color = Colors.blue;
                  if (log.level == 'ERROR') color = Colors.red;
                  if (log.level == 'SUCCESS') color = Colors.green;
                  if (log.level == 'WARN') color = Colors.orange;

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          log.timestamp.split('T')[1].split('.')[0],
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 11,
                            fontFamily: 'monospace',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "[${log.level}]",
                          style: TextStyle(
                            color: color,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            log.message,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTab(String id, String label, IconData icon) {
    final activeTab = ref.watch(activeTabProvider);
    final isActive = activeTab == id;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
      child: TextButton.icon(
        onPressed: () => ref.read(activeTabProvider.notifier).state = id,
        style: TextButton.styleFrom(
          backgroundColor: isActive
              ? Theme.of(context).primaryColor
              : Colors.transparent,
          foregroundColor: isActive ? Colors.white : Colors.grey.shade700,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          padding: const EdgeInsets.symmetric(horizontal: 12),
        ),
        icon: Icon(icon, size: 14),
        label: Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildSidebarSection(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade400,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildSidebarItem(
    IconData icon,
    String label, {
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(icon, size: 16, color: Colors.grey.shade600),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildQueueItem(Color color, String label, bool active) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: active ? color : Colors.grey.shade200,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: active ? Colors.black : Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileItem(String name, String duration) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const Icon(LucideIcons.fileAudio, size: 14, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            duration,
            style: const TextStyle(fontSize: 10, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, int value, {bool isError = false}) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isError ? Colors.red : Colors.black,
          ),
        ),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }
}
