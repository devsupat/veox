import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class SettingsTab extends StatefulWidget {
  const SettingsTab({super.key});

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  String _activeSection = "Gemini API";
  final TextEditingController _apiKeyController = TextEditingController();
  bool _showKey = false;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Settings Navigation
        Container(
          width: 240,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            border: Border(right: BorderSide(color: Colors.grey.shade200)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Settings",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 24),
              _buildNavItem("Gemini API", LucideIcons.key),
              _buildNavItem("Browser Profiles", LucideIcons.globe),
              _buildNavItem("Google Accounts", LucideIcons.user),
            ],
          ),
        ),

        // Settings Content
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "$_activeSection Configuration",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                if (_activeSection == "Gemini API") _buildGeminiSettings(),
                if (_activeSection != "Gemini API")
                  Expanded(
                    child: Center(
                      child: Text(
                        "$_activeSection settings coming soon",
                        style: TextStyle(color: Colors.grey.shade400),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNavItem(String label, IconData icon) {
    final isActive = _activeSection == label;
    return InkWell(
      onTap: () => setState(() => _activeSection = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isActive ? Colors.blue : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: isActive ? Colors.white : Colors.grey.shade600,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : Colors.grey.shade700,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGeminiSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Enter your API keys below, one per line.",
          style: TextStyle(color: Colors.grey, fontSize: 13),
        ),
        const SizedBox(height: 16),
        Container(
          height: 120,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9), // Slate 100
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: TextField(
            controller: _apiKeyController,
            obscureText: !_showKey,
            maxLines: _showKey ? null : 1,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
            decoration: const InputDecoration(
              border: InputBorder.none,
              hintText: "Paste API Keys here...",
            ),
          ),
        ),
        const SizedBox(height: 16),
        InkWell(
          onTap: () => setState(() => _showKey = !_showKey),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _showKey ? LucideIcons.eyeOff : LucideIcons.eye,
                size: 16,
                color: Colors.grey,
              ),
              const SizedBox(width: 8),
              Text(
                _showKey ? "Hide Keys" : "Show Keys",
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
