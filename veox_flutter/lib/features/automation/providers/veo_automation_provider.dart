import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/automation_state.dart';
import '../services/veo_automation_service.dart';

final veoAutomationProvider = StateNotifierProvider<VeoAutomationService, AutomationState>((ref) {
  return VeoAutomationService();
});
