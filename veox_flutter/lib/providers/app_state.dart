import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:veox_flutter/models/types.dart';

class AppState extends ChangeNotifier {
  List<Project> _projects = [];
  String? _activeProjectId;
  Map<String, List<Scene>> _scenesByProjectId = {};
  final List<String> _queue = []; // List of Scene IDs
  List<LogEntry> _logs = [];

  // Reels State
  List<ReelTemplate> _reelTemplates = [];
  List<ReelProject> _reelProjects = [];

  bool _isRunning = false;
  Timer? _generationTimer;

  // Getters
  List<Project> get projects => _projects;
  String? get activeProjectId => _activeProjectId;
  List<LogEntry> get logs => _logs;
  List<ReelTemplate> get reelTemplates => _reelTemplates;
  List<ReelProject> get reelProjects => _reelProjects;
  bool get isRunning => _isRunning;

  Project? get activeProject {
    if (_activeProjectId == null) return null;
    try {
      return _projects.firstWhere((p) => p.id == _activeProjectId);
    } catch (e) {
      return null;
    }
  }

  List<Scene> get activeScenes {
    if (_activeProjectId == null) return [];
    return _scenesByProjectId[_activeProjectId] ?? [];
  }

  Map<String, int> get stats {
    final scenes = activeScenes;
    return {
      'total': scenes.length,
      'done': scenes.where((s) => s.status == SceneStatus.completed).length,
      'active': scenes
          .where(
            (s) =>
                s.status == SceneStatus.running ||
                s.status == SceneStatus.queued,
          )
          .length,
      'failed': scenes.where((s) => s.status == SceneStatus.failed).length,
    };
  }

  AppState() {
    _init();
  }

  Future<void> _init() async {
    await _load();
    // Seed templates if empty
    if (_reelTemplates.isEmpty) {
      _seedTemplates();
    }
  }

  void _seedTemplates() {
    _reelTemplates = [
      ReelTemplate(
        id: const Uuid().v4(),
        name: "Motivation",
        color: 260, // Purple
        image: "bg-purple",
        createdAt: DateTime.now().toIso8601String(),
      ),
      ReelTemplate(
        id: const Uuid().v4(),
        name: "Facts",
        color: 200, // Blue
        image: "bg-blue",
        createdAt: DateTime.now().toIso8601String(),
      ),
      ReelTemplate(
        id: const Uuid().v4(),
        name: "Story",
        color: 30, // Orange
        image: "bg-orange",
        createdAt: DateTime.now().toIso8601String(),
      ),
    ];
    _save();
    notifyListeners();
  }

  // LOGS
  void addLog(String level, String message) {
    final log = LogEntry(
      id: const Uuid().v4(),
      timestamp: DateTime.now().toIso8601String(),
      level: level,
      message: message,
    );
    _logs.insert(0, log);
    if (_logs.length > 500) {
      _logs = _logs.sublist(0, 500);
    }
    _save(); // Maybe don't save every log for perf? But requirement says persist.
    notifyListeners();
  }

  // PROJECTS
  void createProject(String name, {String? exportPath}) {
    final newProject = Project(
      id: const Uuid().v4(),
      name: name,
      createdAt: DateTime.now().toIso8601String(),
      updatedAt: DateTime.now().toIso8601String(),
      settings: ProjectSettings(exportPath: exportPath),
    );
    _projects.insert(0, newProject);
    _activeProjectId = newProject.id;
    _scenesByProjectId[newProject.id] = [];

    addLog('SUCCESS', 'Created project: $name');
    _save();
    notifyListeners();
  }

  void setActiveProject(String id) {
    _activeProjectId = id;
    addLog(
      'INFO',
      'Switched to project: ${_projects.firstWhere((p) => p.id == id).name}',
    );
    _save();
    notifyListeners();
  }

  void deleteProject(String id) {
    final pIndex = _projects.indexWhere((p) => p.id == id);
    if (pIndex == -1) return;

    final name = _projects[pIndex].name;
    _projects.removeAt(pIndex);
    _scenesByProjectId.remove(id);

    if (_activeProjectId == id) {
      _activeProjectId = _projects.isNotEmpty ? _projects.first.id : null;
    }

    addLog('WARN', 'Deleted project: $name');
    _save();
    notifyListeners();
  }

  // SCENES
  void addScene(String prompt) {
    if (_activeProjectId == null) return;

    final scenes = _scenesByProjectId[_activeProjectId] ?? [];
    final newScene = Scene(
      id: const Uuid().v4(),
      index: scenes.length + 1,
      title: "Scene ${scenes.length + 1}",
      promptNo: scenes.length + 1,
      status: SceneStatus.queued,
      prompt: prompt,
      hue: (scenes.length * 137.5) % 360,
      durationSec: 0,
      createdAt: DateTime.now().toIso8601String(),
    );

    if (_scenesByProjectId[_activeProjectId!] == null) {
      _scenesByProjectId[_activeProjectId!] = [];
    }
    _scenesByProjectId[_activeProjectId!]!.add(newScene);
    _queue.add(newScene.id);

    addLog(
      'INFO',
      'Added scene: "${prompt.length > 20 ? '${prompt.substring(0, 20)}...' : prompt}"',
    );
    _save();
    notifyListeners();
  }

  void updateScene(Scene updatedScene) {
    if (_activeProjectId == null) return;
    final scenes = _scenesByProjectId[_activeProjectId];
    if (scenes == null) return;

    final index = scenes.indexWhere((s) => s.id == updatedScene.id);
    if (index != -1) {
      scenes[index] = updatedScene;
      _save();
      notifyListeners();
    }
  }

  void deleteScene(String id) {
    if (_activeProjectId == null) return;
    final scenes = _scenesByProjectId[_activeProjectId];
    if (scenes == null) return;

    scenes.removeWhere((s) => s.id == id);
    _queue.remove(id);
    _save();
    notifyListeners();
  }

  // GENERATION LOOP
  void startGeneration() {
    if (_isRunning) return;
    _isRunning = true;
    addLog('INFO', 'Started generation queue');
    notifyListeners();
    _processQueue();
  }

  void stopGeneration() {
    _isRunning = false;
    _generationTimer?.cancel();
    addLog('WARN', 'Stopped generation');
    notifyListeners();
  }

  void _processQueue() async {
    if (!_isRunning) return;

    // Find next queued scene
    String? nextSceneId;
    if (_queue.isNotEmpty) {
      nextSceneId = _queue.first;
    } else {
      // Check if any scenes are queued but not in queue list (sync issue)
      // Or just loop through all projects? For now assume only active project or global queue
      // Let's look for queued scenes in the active project for simplicity
      if (_activeProjectId != null) {
        final scenes = _scenesByProjectId[_activeProjectId]!;
        final queued = scenes
            .where((s) => s.status == SceneStatus.queued)
            .toList();
        if (queued.isNotEmpty) {
          nextSceneId = queued.first.id;
        }
      }
    }

    if (nextSceneId == null) {
      // Queue empty
      stopGeneration();
      addLog('SUCCESS', 'Queue finished');
      return;
    }

    // Find the scene object (search in all projects or active?)
    // Assuming we only process active project for now as per UI context,
    // but a real queue might be global. Let's search in active project.
    if (_activeProjectId == null) {
      stopGeneration();
      return;
    }

    final scenes = _scenesByProjectId[_activeProjectId]!;
    final sceneIndex = scenes.indexWhere((s) => s.id == nextSceneId);

    if (sceneIndex == -1) {
      _queue.remove(nextSceneId); // Invalid ID
      _processQueue();
      return;
    }

    final scene = scenes[sceneIndex];

    // Update to Running
    scenes[sceneIndex] = Scene(
      id: scene.id,
      index: scene.index,
      title: scene.title,
      promptNo: scene.promptNo,
      status: SceneStatus.running,
      prompt: scene.prompt,
      hue: scene.hue,
      durationSec: scene.durationSec,
      createdAt: scene.createdAt,
    );
    notifyListeners();
    addLog('INFO', 'Processing scene: ${scene.index}');

    // Simulate work (2-5 seconds)
    final duration = 2000 + Random().nextInt(3000);
    _generationTimer = Timer(Duration(milliseconds: duration), () {
      if (!_isRunning) return;

      // Update to Completed
      final completedScene = Scene(
        id: scene.id,
        index: scene.index,
        title: scene.title,
        promptNo: scene.promptNo,
        status: SceneStatus.completed,
        prompt: scene.prompt,
        hue: scene.hue,
        durationSec: duration ~/ 1000,
        createdAt: scene.createdAt,
      );

      scenes[sceneIndex] = completedScene;
      _queue.remove(scene.id);

      addLog(
        'SUCCESS',
        'Completed scene: ${scene.index} (${duration ~/ 1000}s)',
      );
      _save();
      notifyListeners();

      // Next
      _processQueue();
    });
  }

  // REELS
  void addReelTemplate(ReelTemplate t) {
    _reelTemplates.add(t);
    _save();
    notifyListeners();
  }

  void addReelProject(ReelProject p) {
    _reelProjects.insert(0, p);
    addLog('SUCCESS', 'Generated Reel Project: ${p.topic}');
    _save();
    notifyListeners();
  }

  void deleteReelProject(String id) {
    _reelProjects.removeWhere((p) => p.id == id);
    _save();
    notifyListeners();
  }

  // PERSISTENCE
  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();

    // Projects
    prefs.setString(
      'veox_projects',
      jsonEncode(_projects.map((e) => e.toJson()).toList()),
    );
    if (_activeProjectId != null) {
      prefs.setString('veox_activeProjectId', _activeProjectId!);
    }

    // Scenes
    final scenesMap = _scenesByProjectId.map(
      (k, v) => MapEntry(k, v.map((e) => e.toJson()).toList()),
    );
    prefs.setString('veox_scenes', jsonEncode(scenesMap));

    // Logs
    prefs.setString(
      'veox_logs',
      jsonEncode(_logs.map((e) => e.toJson()).toList()),
    );

    // Reels
    prefs.setString(
      'veox_reel_templates',
      jsonEncode(_reelTemplates.map((e) => e.toJson()).toList()),
    );
    prefs.setString(
      'veox_reel_projects',
      jsonEncode(_reelProjects.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();

    // Projects
    final projectsJson = prefs.getString('veox_projects');
    if (projectsJson != null) {
      final List<dynamic> list = jsonDecode(projectsJson);
      _projects = list.map((e) => Project.fromJson(e)).toList();
    }

    _activeProjectId = prefs.getString('veox_activeProjectId');

    // Scenes
    final scenesJson = prefs.getString('veox_scenes');
    if (scenesJson != null) {
      final Map<String, dynamic> map = jsonDecode(scenesJson);
      _scenesByProjectId = map.map((k, v) {
        final List<dynamic> list = v;
        return MapEntry(k, list.map((e) => Scene.fromJson(e)).toList());
      });
    }

    // Logs
    final logsJson = prefs.getString('veox_logs');
    if (logsJson != null) {
      final List<dynamic> list = jsonDecode(logsJson);
      _logs = list.map((e) => LogEntry.fromJson(e)).toList();
    }

    // Reels
    final templatesJson = prefs.getString('veox_reel_templates');
    if (templatesJson != null) {
      final List<dynamic> list = jsonDecode(templatesJson);
      _reelTemplates = list.map((e) => ReelTemplate.fromJson(e)).toList();
    }

    final reelProjectsJson = prefs.getString('veox_reel_projects');
    if (reelProjectsJson != null) {
      final List<dynamic> list = jsonDecode(reelProjectsJson);
      _reelProjects = list.map((e) => ReelProject.fromJson(e)).toList();
    }

    notifyListeners();
  }
}
