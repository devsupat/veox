import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:veox_flutter/features/automation/services/veo_automation_service.dart';
import 'package:veox_flutter/features/automation/models/automation_state.dart';
import 'package:veox_flutter/features/workflows/providers/clone_workflow_provider.dart';
import 'package:veox_flutter/core/state/workflow_state.dart';
import 'package:veox_flutter/ui/widgets/glass_container.dart';
import 'package:veox_flutter/ui/widgets/terminal_drawer.dart';

class CloneTab extends ConsumerStatefulWidget {
  const CloneTab({super.key});

  @override
  ConsumerState<CloneTab> createState() => _CloneTabState();
}

class _CloneTabState extends ConsumerState<CloneTab> {
  final TextEditingController _urlController = TextEditingController(
    text: "https://www.youtube.com/watch?v=8A41Qka18ko",
  );
  final TextEditingController _promptController = TextEditingController(
    text: "A futuristic city with flying cars",
  );
  String _selectedStyle = "No Style";
  String _selectedModel = "Gemini 3 Flash";
  bool _voiceEnabled = false;
  bool _twoInOne = true;

  @override
  Widget build(BuildContext context) {
    final automationState = ref.watch(veoAutomationProvider);
    final workflowState = ref.watch(cloneWorkflowProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Background Image with Dark Overlay
          Positioned.fill(
            child: Image.asset(
              'assets/images/premium_bg.png',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.5),
                    Colors.black.withValues(alpha: 0.8),
                  ],
                ),
              ),
            ),
          ),

          // Main Content
          Column(
            children: [
              // Header Info
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                color: Colors.black.withValues(alpha: 0.3),
                alignment: Alignment.center,
                child: const Text(
                  "Veox AI Creative Studio — Frame Sequencer 3.0",
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white54,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    vertical: 48,
                    horizontal: 24,
                  ),
                  child: Center(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 850),
                      child: Column(
                        children: [
                          // Navigation Bar
                          _buildPremiumHeader(automationState),
                          const SizedBox(height: 60),

                          // Hero Section
                          _buildHeroSection(),
                          const SizedBox(height: 48),

                          // Glass Interface
                          AbsorbPointer(
                            absorbing: workflowState.isRunning,
                            child: Opacity(
                              opacity: workflowState.isRunning ? 0.5 : 1.0,
                              child: GlassContainer(
                                padding: const EdgeInsets.all(32),
                                blur: 20,
                                opacity: 0.08,
                                child: Column(
                                  children: [
                                    _buildInputSection(),
                                    const SizedBox(height: 24),
                                    _buildSettingsGrid(),
                                    const SizedBox(height: 32),
                                    _buildGenerateButton(
                                      automationState,
                                      workflowState,
                                      context,
                                    ),
                                    if (automationState.currentAction != null ||
                                        workflowState.currentAction != null)
                                      _buildStatusIndicator(
                                        workflowState.currentAction ??
                                            automationState.currentAction!,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 100), // Space for terminal
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Terminal Drawer
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: TerminalDrawer(),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumHeader(AutomationState automationState) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GlassContainer(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          borderRadius: 12,
          child: Row(
            children: [
              const Icon(LucideIcons.video, color: Colors.blueAccent, size: 18),
              const SizedBox(width: 10),
              const Text(
                "CineRecreate",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        Row(
          children: [
            _buildNavLink("Analyzer"),
            const SizedBox(width: 24),
            _buildNavLink("Forge"),
            const SizedBox(width: 24),
            _buildNavLink("Library"),
            const SizedBox(width: 32),
            _buildAuthChip(automationState),
            const SizedBox(width: 16),
            _buildStatusChip(automationState),
          ],
        ),
      ],
    );
  }

  Widget _buildAuthChip(AutomationState state) {
    // In a real implementation, we'd watch the active profile's auth status
    final bool isAuthorized = state.status == AutomationStatus.connected;

    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      borderRadius: 20,
      opacity: 0.1,
      border: Border.all(
        color: isAuthorized
            ? Colors.blueAccent.withValues(alpha: 0.3)
            : Colors.redAccent.withValues(alpha: 0.3),
      ),
      child: Row(
        children: [
          Icon(
            isAuthorized ? LucideIcons.userCheck : LucideIcons.userX,
            color: isAuthorized ? Colors.blueAccent : Colors.redAccent,
            size: 12,
          ),
          const SizedBox(width: 8),
          Text(
            isAuthorized ? "AUTH ACTIVE" : "AUTH REQUIRED",
            style: TextStyle(
              color: isAuthorized ? Colors.blueAccent : Colors.redAccent,
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection() {
    return Column(
      children: [
        RichText(
          textAlign: TextAlign.center,
          text: const TextSpan(
            children: [
              TextSpan(
                text: "FRAME ",
                style: TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.w200,
                  color: Colors.white,
                  letterSpacing: 4,
                ),
              ),
              TextSpan(
                text: "SEQUENCER",
                style: TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.w800,
                  color: Colors.blueAccent,
                  letterSpacing: 4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          "Automated cinema deconstruction into modular visual prompts.\nHigh-fidelity subject injection and generation orchestration.",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white54,
            height: 1.6,
            fontWeight: FontWeight.w300,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildInputSection() {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: _buildGlassInput(
            controller: _urlController,
            hintText: "Source URL (YouTube, Vimeo...)",
            icon: LucideIcons.link,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildGlassDropdown(
            value: _selectedModel,
            items: ["Gemini 3 Flash", "Gemini 1.5 Pro"],
            onChanged: (v) => setState(() => _selectedModel = v!),
            icon: LucideIcons.cpu,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsGrid() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _buildSettingItem(
          child: _buildGlassDropdown(
            value: _selectedStyle,
            items: ["No Style", "Cinematic", "Anime", "Noir"],
            onChanged: (v) => setState(() => _selectedStyle = v!),
            icon: LucideIcons.palette,
            width: 160,
          ),
        ),
        _buildSettingItem(
          child: _buildGlassAction(
            text: "Subject Reference",
            icon: LucideIcons.user,
            width: 180,
          ),
        ),
        _buildSettingItem(
          child: _buildGlassToggle(
            label: "AUTO-SYNC",
            value: _twoInOne,
            onChanged: (v) => setState(() => _twoInOne = v),
          ),
        ),
        _buildSettingItem(
          child: _buildGlassToggle(
            label: "VOICE",
            value: _voiceEnabled,
            onChanged: (v) => setState(() => _voiceEnabled = v),
          ),
        ),
      ],
    );
  }

  Widget _buildGenerateButton(
    AutomationState automationState,
    WorkflowState<CloneWorkflowData> workflowState,
    BuildContext context,
  ) {
    final isBusy =
        automationState.status == AutomationStatus.busy ||
        workflowState.isRunning;

    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: isBusy
              ? [Colors.grey.shade900, Colors.grey.shade800]
              : [Colors.blueAccent, Colors.blue.shade700],
        ),
        boxShadow: [
          if (!isBusy)
            BoxShadow(
              color: Colors.blueAccent.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
        ],
      ),
      child: ElevatedButton(
        onPressed: isBusy ? null : () => _handleAction(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: isBusy
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                workflowState.isRunning
                    ? "GENERATING..."
                    : automationState.status == AutomationStatus.connected
                    ? "GENERATE SEQUENCE"
                    : "CONNECT ENGINE",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
      ),
    );
  }

  void _handleAction(BuildContext context) async {
    final automationNotifier = ref.read(veoAutomationProvider.notifier);
    final automationState = ref.read(veoAutomationProvider);
    final workflowNotifier = ref.read(cloneWorkflowProvider.notifier);

    if (automationState.status != AutomationStatus.connected) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Please connect engine using 'Open No Login' first!"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
      return;
    }

    workflowNotifier.startGeneration();
    try {
      await automationNotifier.executeVeoAction(
        action: "generate",
        prompt: _promptController.text,
      );
      workflowNotifier.completeGeneration();
    } catch (e) {
      workflowNotifier.failGeneration(e.toString());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: $e"),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _buildStatusIndicator(String statusText) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Text(
        statusText.toUpperCase(),
        style: const TextStyle(
          color: Colors.blueAccent,
          fontSize: 10,
          letterSpacing: 1.5,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // --- Utility Widgets ---

  Widget _buildNavLink(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white60,
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 1,
      ),
    );
  }

  Widget _buildStatusChip(AutomationState state) {
    final isConnected = state.status == AutomationStatus.connected;
    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      borderRadius: 20,
      opacity: 0.1,
      border: Border.all(
        color: isConnected
            ? Colors.green.withValues(alpha: 0.5)
            : Colors.orange.withValues(alpha: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: isConnected ? Colors.green : Colors.orange,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            isConnected ? "ENGINE ACTIVE" : "ENGINE STANDBY",
            style: TextStyle(
              color: isConnected ? Colors.green : Colors.orange,
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassInput({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: Colors.white, fontSize: 13),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(color: Colors.white24),
          prefixIcon: Icon(icon, color: Colors.white38, size: 16),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  Widget _buildGlassDropdown({
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
    required IconData icon,
    double? width,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          dropdownColor: const Color(0xFF121212),
          icon: Icon(icon, color: Colors.white38, size: 16),
          isExpanded: true,
          style: const TextStyle(color: Colors.white, fontSize: 13),
          items: items
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildGlassAction({
    required String text,
    required IconData icon,
    required double width,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white38, size: 16),
          const SizedBox(width: 10),
          Text(
            text,
            style: const TextStyle(color: Colors.white38, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassToggle({
    required String label,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.blueAccent,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem({required Widget child}) => child;
}
