import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:veox_flutter/ui/widgets/add_account_dialog.dart';
import 'package:veox_flutter/ui/widgets/assign_profile_dialog.dart';

class SettingsTab extends StatefulWidget {
  const SettingsTab({super.key});

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  String _activeSection = "Google Accounts";
  final TextEditingController _apiKeyController = TextEditingController();
  bool _showKey = false;

  // Mock Data
  final List<Map<String, dynamic>> _accounts = [
    {
      "email": "shakilbd2993@mail.com",
      "status": "Not assigned to any profile",
      "profiles": 0,
      "color": Colors.blue.shade100,
      "text_color": Colors.blue.shade800,
      "assigned_list": <String>[]
    },
    {
      "email": "miller140327@mqm.novalinecreate.com",
      "status": "Assigned to 6 profile(s)",
      "profiles": 6,
      "color": Colors.blue.shade100,
      "text_color": Colors.blue.shade800,
      "assigned_list": <String>["Default", "Profile 1", "Profile 2", "4", "Profile5", "6"]
    },
    {
      "email": "fjkdfajkhjf",
      "status": "Assigned to 1 profile(s)",
      "profiles": 1,
      "color": Colors.blue.shade100,
      "text_color": Colors.blue.shade800,
      "assigned_list": <String>["new"]
    },
  ];

  // Mock Available Profiles
  final List<String> _allProfiles = [
    "Default",
    "Profile 1",
    "Profile 2",
    "4",
    "Profile5",
    "6",
    "new"
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Settings Navigation
        Container(
          width: 240,
          color: const Color(0xFFF1F5F9), // Slate 100 sidebar
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildNavItem("Gemini API", LucideIcons.settings),
              _buildNavItem("Browser Profiles", LucideIcons.layoutTemplate),
              _buildNavItem("Google Accounts", LucideIcons.userCircle),
            ],
          ),
        ),

        // Settings Content
        Expanded(
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.all(40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_activeSection == "Google Accounts") ...[
                  const Text(
                    "Google Accounts",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B), // Slate 800
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Manage Google accounts and assign them to browser profiles",
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Header Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "${_accounts.length} Account(s)",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => AddAccountDialog(
                              onAdd: (email, password) {
                                setState(() {
                                  _accounts.add({
                                    "email": email,
                                    "status": "Not assigned to any profile",
                                    "profiles": 0,
                                    "color": Colors.blue.shade100,
                                    "text_color": Colors.blue.shade800
                                  });
                                });
                              },
                            ),
                          );
                        },
                        icon: const Icon(LucideIcons.plus, size: 16),
                        label: const Text("Add Account"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3B82F6), // Blue 500
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Account List
                  Expanded(
                    child: ListView.separated(
                      itemCount: _accounts.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final acc = _accounts[index];
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC), // Slate 50
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              // Avatar
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: acc['color'],
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    acc['email'][0].toUpperCase(),
                                    style: TextStyle(
                                      color: acc['text_color'],
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              
                              // Info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      acc['email'],
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF334155), // Slate 700
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      acc['status'],
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Actions
                              IconButton(
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AssignProfileDialog(
                                      availableProfiles: _allProfiles,
                                      assignedProfiles: (acc['assigned_list'] as List<String>?) ?? [],
                                      onSave: (selected) {
                                        setState(() {
                                          acc['assigned_list'] = selected;
                                          acc['profiles'] = selected.length;
                                          acc['status'] = selected.isEmpty 
                                              ? "Not assigned to any profile" 
                                              : "Assigned to ${selected.length} profile(s)";
                                        });
                                      },
                                    ),
                                  );
                                },
                                icon: const Icon(LucideIcons.users, size: 18, color: Colors.grey),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                onPressed: () {
                                  setState(() {
                                    _accounts.removeAt(index);
                                  });
                                },
                                icon: const Icon(LucideIcons.trash2, size: 18, color: Colors.redAccent),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ] else
                  _buildGeminiSettings(), // Fallback or other sections
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
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFE2E8F0) : Colors.transparent, // Slate 200 for active
          border: isActive ? const Border(left: BorderSide(color: Color(0xFF3B82F6), width: 4)) : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: isActive ? const Color(0xFF334155) : const Color(0xFF64748B),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: isActive ? const Color(0xFF334155) : const Color(0xFF64748B),
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                fontSize: 14,
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
        Text(
          "$_activeSection Settings",
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 24),
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
