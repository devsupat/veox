enum AutomationStatus { idle, connecting, connected, busy, error }

class AutomationState {
  final AutomationStatus status;
  final String? lastError;
  final String? currentAction;
  final bool isBrowserOpen;
  final int framesGenerated;

  const AutomationState({
    this.status = AutomationStatus.idle,
    this.lastError,
    this.currentAction,
    this.isBrowserOpen = false,
    this.framesGenerated = 0,
  });

  AutomationState copyWith({
    AutomationStatus? status,
    String? lastError,
    String? currentAction,
    bool? isBrowserOpen,
    int? framesGenerated,
  }) {
    return AutomationState(
      status: status ?? this.status,
      lastError: lastError, // Allow clearing error by passing null explicitly if needed, but here standard copyWith logic
      currentAction: currentAction ?? this.currentAction,
      isBrowserOpen: isBrowserOpen ?? this.isBrowserOpen,
      framesGenerated: framesGenerated ?? this.framesGenerated,
    );
  }
}

class SelectorConfig {
  final String promptInput;
  final String generateButton;
  final String downloadButton;
  final String loginButton;
  
  // Default selectors for Google Labs VideoFX (hypothetical, user to update)
  const SelectorConfig({
    this.promptInput = 'textarea[placeholder*="Describe"]', 
    this.generateButton = 'button:has-text("Generate")',
    this.downloadButton = 'button[aria-label="Download"]',
    this.loginButton = 'a[href*="accounts.google.com"]',
  });
}
