import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:veox_flutter/features/automation/services/automation_bridge_service.dart';
import 'dart:ui';

class TerminalDrawer extends ConsumerStatefulWidget {
  const TerminalDrawer({super.key});

  @override
  ConsumerState<TerminalDrawer> createState() => _TerminalDrawerState();
}

class _TerminalDrawerState extends ConsumerState<TerminalDrawer> {
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _logs = [];
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    ref.read(automationBridgeProvider).logs.listen((log) {
      if (mounted) {
        setState(() {
          _logs.add(log);
          if (_logs.length > 200) _logs.removeAt(0);
        });
        _scrollToBottom();
      }
    });
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: _isExpanded ? 300 : 41,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.8),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
      ),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Column(
            children: [
              // Header / Drag Handle
              GestureDetector(
                onTap: () => setState(() => _isExpanded = !_isExpanded),
                child: Container(
                  height: 40,
                  width: double.infinity,
                  color: Colors.transparent,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.terminal,
                        size: 14,
                        color: _isExpanded ? Colors.blue : Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "AUTOMATION TERMINAL",
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                          color: _isExpanded ? Colors.white : Colors.grey,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        _isExpanded
                            ? Icons.keyboard_arrow_down
                            : Icons.keyboard_arrow_up,
                        size: 16,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                ),
              ),
              if (_isExpanded)
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: ListView.builder(
                      controller: _scrollController,
                      itemCount: _logs.length,
                      itemBuilder: (context, index) {
                        final log = _logs[index];
                        final level = log['level'] ?? 'info';
                        final message = log['message'] ?? '';
                        final timestamp = DateTime.fromMillisecondsSinceEpoch(
                          log['timestamp'] ??
                              DateTime.now().millisecondsSinceEpoch,
                        );

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: RichText(
                            text: TextSpan(
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 11,
                                height: 1.4,
                              ),
                              children: [
                                TextSpan(
                                  text:
                                      "[${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}:${timestamp.second.toString().padLeft(2, '0')}] ",
                                  style: const TextStyle(color: Colors.grey),
                                ),
                                TextSpan(
                                  text: "${level.toUpperCase()} ",
                                  style: TextStyle(
                                    color: _getLevelColor(level),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                TextSpan(
                                  text: message,
                                  style: const TextStyle(color: Colors.white70),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getLevelColor(String level) {
    switch (level) {
      case 'error':
        return Colors.redAccent;
      case 'warn':
        return Colors.orangeAccent;
      case 'success':
        return Colors.greenAccent;
      default:
        return Colors.blueAccent;
    }
  }
}
