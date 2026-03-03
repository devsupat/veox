import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Manages the currently active tab in the MainLayout.
final activeTabProvider = StateProvider<String>((ref) => 'home');
