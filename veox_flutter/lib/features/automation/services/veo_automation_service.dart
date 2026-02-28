import 'dart:io';
import 'package:puppeteer/puppeteer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import '../models/automation_state.dart';

/// Service responsible for managing the Puppeteer browser instance
/// and executing video generation commands on Google Labs (VideoFX).
class VeoAutomationService extends StateNotifier<AutomationState> {
  Browser? _browser;
  Page? _page;
  
  // Configurable selectors - in a real app these might come from remote config
  final SelectorConfig _selectors = const SelectorConfig();

  VeoAutomationService() : super(const AutomationState());

  /// Launches a persistent browser session.
  /// Uses app support directory to store user data (cookies/login session).
  Future<void> launchBrowser({bool headless = false}) async {
    try {
      state = state.copyWith(status: AutomationStatus.connecting, currentAction: "Launching Browser...");
      
      final appDir = await getApplicationSupportDirectory();
      final userDataDir = Directory('${appDir.path}/veox_browser_data');
      if (!userDataDir.existsSync()) {
        userDataDir.createSync(recursive: true);
      }

      // Launch Puppeteer with persistent context
      _browser = await puppeteer.launch(
        headless: headless,
        userDataDir: userDataDir.path,
        args: [
          '--no-sandbox',
          '--disable-setuid-sandbox',
          '--window-size=1280,800',
        ],
      );

      // Open a new page or get the existing one
      final pages = await _browser!.pages;
      _page = pages.isNotEmpty ? pages.first : await _browser!.newPage();
      
      // Navigate to Google Labs VideoFX (or relevant URL)
      // Note: Using a placeholder URL as the actual VideoFX URL might change
      await _page!.goto('https://labs.google/videofx', wait: Until.networkIdle);

      state = state.copyWith(
        status: AutomationStatus.connected,
        isBrowserOpen: true,
        currentAction: "Browser Ready. Please Login manually if needed.",
      );
      
      // Monitor browser disconnect
      _browser!.disconnected.then((_) {
        _browser = null;
        _page = null;
        state = state.copyWith(
          status: AutomationStatus.idle,
          isBrowserOpen: false,
          currentAction: "Browser Closed",
        );
      });

    } catch (e, stack) {
      state = state.copyWith(
        status: AutomationStatus.error,
        lastError: "Failed to launch browser: $e",
        currentAction: "Error Launching",
      );
      print("VeoAutomationService Error: $e\n$stack");
    }
  }

  /// Closes the browser instance.
  Future<void> closeBrowser() async {
    if (_browser != null) {
      await _browser!.close();
      _browser = null;
      _page = null;
      state = state.copyWith(status: AutomationStatus.idle, isBrowserOpen: false);
    }
  }

  /// Automates the generation process on the page.
  /// 
  /// 1. Finds the prompt textarea.
  /// 2. Clears existing text.
  /// 3. Types the new prompt.
  /// 4. Clicks Generate.
  /// 5. Waits for generation (simplified).
  Future<void> generateVideo(String prompt) async {
    if (_browser == null || _page == null) {
      throw Exception("Browser not connected. Call launchBrowser() first.");
    }

    try {
      state = state.copyWith(status: AutomationStatus.busy, currentAction: "Inputting Prompt...");

      // 1. Focus and Type Prompt
      // Using a generic selector strategy - try multiple common textarea selectors if specific one fails
      // In production, use more robust selectors (e.g. accessibility labels)
      final promptInput = await _findPromptInput();
      if (promptInput == null) {
        throw Exception("Could not find prompt input field. Please check selectors.");
      }

      // Clear input (Select All + Backspace is often safer than .value = '')
      await promptInput.click();
      await _page!.keyboard.down(Key.meta); // Command on Mac
      await _page!.keyboard.press(Key.keyA);
      await _page!.keyboard.up(Key.meta);
      await _page!.keyboard.press(Key.backspace);

      // Type new prompt
      await _page!.keyboard.type(prompt);
      await Future.delayed(const Duration(milliseconds: 500)); // Human-like delay

      // 2. Click Generate
      state = state.copyWith(currentAction: "Clicking Generate...");
      final generateBtn = await _findGenerateButton();
      if (generateBtn == null) {
        throw Exception("Could not find Generate button.");
      }
      await generateBtn.click();

      // 3. Wait for Generation (Mock implementation for waiting logic)
      // Real implementation would look for a loading spinner to disappear or a video element to appear
      state = state.copyWith(currentAction: "Waiting for Video Generation...");
      
      // Just a simple delay for now as we don't have the real site DOM to check against
      await Future.delayed(const Duration(seconds: 10)); 

      state = state.copyWith(
        status: AutomationStatus.connected,
        currentAction: "Generation Command Sent",
        framesGenerated: state.framesGenerated + 1,
      );

    } catch (e) {
      state = state.copyWith(
        status: AutomationStatus.error,
        lastError: "Generation Failed: $e",
        currentAction: "Error during generation",
      );
      rethrow;
    }
  }

  // --- Helper Methods for Selectors ---

  Future<ElementHandle?> _findPromptInput() async {
    // Try multiple selectors
    final candidates = [
      _selectors.promptInput,
      'textarea',
      'input[type="text"]',
      '[contenteditable="true"]',
    ];

    for (final selector in candidates) {
      try {
        final element = await _page!.$(selector);
        if (element != null) return element;
      } catch (_) {}
    }
    return null;
  }

  Future<ElementHandle?> _findGenerateButton() async {
    // Try explicit selector first
    try {
      final btn = await _page!.$(_selectors.generateButton); // Puppeteer Dart might not support :has-text directly in $
      if (btn != null) return btn;
    } catch (_) {}

    // Fallback: iterate buttons and check text
    final buttons = await _page!.$$('button');
    for (final btn in buttons) {
      // Use evaluate to get innerText directly from the DOM element
      final text = await btn.evaluate('el => el.innerText');
      if (text != null && (text.toString().toLowerCase().contains('generate') || 
          text.toString().toLowerCase().contains('create'))) {
        return btn;
      }
    }
    return null;
  }
}
