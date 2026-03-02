import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:veox_flutter/core/database/browser_profile_model.dart';
import 'package:veox_flutter/core/database/google_account_model.dart';
import 'package:veox_flutter/core/database/isar_service.dart';

class ProfileAssignmentDialog extends ConsumerStatefulWidget {
  final GoogleAccountModel account;

  const ProfileAssignmentDialog({super.key, required this.account});

  @override
  ConsumerState<ProfileAssignmentDialog> createState() =>
      _ProfileAssignmentDialogState();
}

class _ProfileAssignmentDialogState
    extends ConsumerState<ProfileAssignmentDialog> {
  List<BrowserProfileModel> _profiles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfiles();
  }

  Future<void> _loadProfiles() async {
    final isarService = ref.read(isarServiceProvider);
    final profiles = await isarService.getAllBrowserProfiles();

    // Ensure the IsarLinks are loaded so we can accurately check assignments
    for (var profile in profiles) {
      await profile.googleAccount.load();
    }

    if (mounted) {
      setState(() {
        _profiles = profiles;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleAssignment(
    BrowserProfileModel profile,
    bool assign,
  ) async {
    final isarService = ref.read(isarServiceProvider);

    setState(() => _isLoading = true);

    try {
      if (assign) {
        await isarService.updateProfileGoogleAccount(profile, widget.account);
      } else {
        await isarService.updateProfileGoogleAccount(profile, null);
      }

      // Reload links to reflect new state
      await profile.googleAccount.load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update assignment: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Assign ${widget.account.email}"),
      content: SizedBox(
        width: 400,
        height: 300,
        child: _isLoading && _profiles.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : _profiles.isEmpty
            ? const Center(
                child: Text(
                  "No browser profiles found. Create a profile in the 'Browser Profiles' tab first.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              )
            : Stack(
                children: [
                  ListView.separated(
                    itemCount: _profiles.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final profile = _profiles[index];
                      final isAssigned =
                          profile.googleAccount.value?.id == widget.account.id;
                      final otherAssignedEmail =
                          profile.googleAccount.value?.email;
                      late final String subtitle;

                      if (isAssigned) {
                        subtitle = "Assigned to this account";
                      } else if (otherAssignedEmail != null) {
                        subtitle = "Currently assigned to: $otherAssignedEmail";
                      } else {
                        subtitle = "Unassigned";
                      }

                      return CheckboxListTile(
                        title: Text(
                          profile.name,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        subtitle: Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 12,
                            color: isAssigned ? Colors.blue : Colors.grey,
                          ),
                        ),
                        value: isAssigned,
                        activeColor: Colors.blue,
                        onChanged: _isLoading
                            ? null
                            : (bool? value) {
                                if (value != null) {
                                  _toggleAssignment(profile, value);
                                }
                              },
                      );
                    },
                  ),
                  if (_isLoading && _profiles.isNotEmpty)
                    Container(
                      color: Colors.white.withOpacity(0.5),
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                ],
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Done"),
        ),
      ],
    );
  }
}
