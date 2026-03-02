import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:veox_flutter/ui/widgets/add_account_dialog.dart';
import 'package:veox_flutter/ui/widgets/profile_assignment_dialog.dart';
import 'package:veox_flutter/features/automation/services/google_auth_service.dart';
import 'package:veox_flutter/core/database/google_account_model.dart';

class SettingsTab extends ConsumerStatefulWidget {
  const SettingsTab({super.key});

  @override
  ConsumerState<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends ConsumerState<SettingsTab> {
  String _activeSection = "Google Accounts";
  final TextEditingController _apiKeyController = TextEditingController();
  bool _showKey = false;

  @override
  Widget build(BuildContext context) {
    final accountsAsync = ref.watch(googleAccountsStreamProvider);

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
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  const SizedBox(height: 32),

                  // Header Row
                  accountsAsync.when(
                    data: (accounts) => Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "${accounts.length} Account(s)",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => _showAddAccount(context),
                          icon: const Icon(LucideIcons.plus, size: 16),
                          label: const Text("Add Account"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(
                              0xFF3B82F6,
                            ), // Blue 500
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                      ],
                    ),
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, st) => Text("Error loading accounts: $e"),
                  ),
                  const SizedBox(height: 16),

                  // Account List
                  Expanded(
                    child: accountsAsync.when(
                      data: (accounts) {
                        if (accounts.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  LucideIcons.userX,
                                  size: 48,
                                  color: Colors.grey.shade300,
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  "No accounts added yet",
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        return ListView.separated(
                          itemCount: accounts.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final acc = accounts[index];
                            final color = Colors.blue.shade100;
                            final textColor = Colors.blue.shade800;

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
                                      color: color,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        acc.email.isNotEmpty
                                            ? acc.email[0].toUpperCase()
                                            : "G",
                                        style: TextStyle(
                                          color: textColor,
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          acc.email,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            color: Color(
                                              0xFF334155,
                                            ), // Slate 700
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          "Last active: ${acc.lastLogin?.toString().split('.')[0] ?? 'Never'}",
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
                                        builder: (context) =>
                                            ProfileAssignmentDialog(
                                              account: acc,
                                            ),
                                      );
                                    },
                                    icon: const Icon(
                                      LucideIcons.users,
                                      size: 18,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    onPressed: () => _removeAccount(acc),
                                    icon: const Icon(
                                      LucideIcons.trash2,
                                      size: 18,
                                      color: Colors.redAccent,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                      loading: () => const SizedBox.shrink(),
                      error: (e, st) => const SizedBox.shrink(),
                    ),
                  ),
                ] else
                  _buildGeminiSettings(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showAddAccount(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AddAccountDialog(
        onAdd: (email, password) async {
          try {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Launching browser for guided login..."),
                duration: Duration(seconds: 3),
              ),
            );

            await ref
                .read(googleAuthProvider)
                .startGuidedLogin(email: email, password: password);

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Account added successfully")),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("Failed to add account: $e"),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
      ),
    );
  }

  Future<void> _removeAccount(GoogleAccountModel account) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Remove Account"),
        content: Text("Are you sure you want to remove ${account.email}?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Remove"),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(googleAuthProvider).removeAccount(account);
    }
  }

  Widget _buildNavItem(String label, IconData icon) {
    final isActive = _activeSection == label;
    return InkWell(
      onTap: () => setState(() => _activeSection = label),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFE2E8F0) : Colors.transparent,
          border: isActive
              ? const Border(
                  left: BorderSide(color: Color(0xFF3B82F6), width: 4),
                )
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: isActive
                  ? const Color(0xFF334155)
                  : const Color(0xFF64748B),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: isActive
                    ? const Color(0xFF334155)
                    : const Color(0xFF64748B),
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
            color: const Color(0xFFF1F5F9),
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
