enum SceneStatus { idle, queued, running, completed, failed }

class Scene {
  final String id;
  final int index;
  final String title;
  final int promptNo;
  final SceneStatus status;
  final String prompt;
  final double hue;
  final int durationSec;
  final String createdAt;

  Scene({
    required this.id,
    required this.index,
    required this.title,
    required this.promptNo,
    required this.status,
    required this.prompt,
    required this.hue,
    required this.durationSec,
    required this.createdAt,
  });

  factory Scene.fromJson(Map<String, dynamic> json) {
    return Scene(
      id: json['id'],
      index: json['index'],
      title: json['title'],
      promptNo: json['promptNo'],
      status: SceneStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => SceneStatus.idle,
      ),
      prompt: json['prompt'],
      hue: json['hue'].toDouble(),
      durationSec: json['durationSec'],
      createdAt: json['createdAt'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'index': index,
    'title': title,
    'promptNo': promptNo,
    'status': status.name,
    'prompt': prompt,
    'hue': hue,
    'durationSec': durationSec,
    'createdAt': createdAt,
  };
}

class ProjectSettings {
  final String ratio;
  final String model;
  final String account;
  final bool boost;
  final String? exportPath;

  ProjectSettings({
    this.ratio = "16:9",
    this.model = "Veo 3.1 – Fast",
    this.account = "AI Ultra",
    this.boost = false,
    this.exportPath,
  });

  factory ProjectSettings.fromJson(Map<String, dynamic> json) {
    return ProjectSettings(
      ratio: json['ratio'],
      model: json['model'],
      account: json['account'],
      boost: json['boost'],
      exportPath: json['exportPath'],
    );
  }

  Map<String, dynamic> toJson() => {
    'ratio': ratio,
    'model': model,
    'account': account,
    'boost': boost,
    'exportPath': exportPath,
  };
}

class Project {
  final String id;
  final String name;
  final String createdAt;
  final String updatedAt;
  final ProjectSettings settings;

  Project({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    required this.settings,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'],
      name: json['name'],
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
      settings: ProjectSettings.fromJson(json['settings']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
    'settings': settings.toJson(),
  };
}

class LogEntry {
  final String id;
  final String timestamp;
  final String level;
  final String message;

  LogEntry({
    required this.id,
    required this.timestamp,
    required this.level,
    required this.message,
  });

  factory LogEntry.fromJson(Map<String, dynamic> json) {
    return LogEntry(
      id: json['id'],
      timestamp: json['timestamp'],
      level: json['level'],
      message: json['message'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'timestamp': timestamp,
    'level': level,
    'message': message,
  };
}

class ReelTemplate {
  final String id;
  final String name;
  final int color;
  final String image;
  final String createdAt;

  ReelTemplate({
    required this.id,
    required this.name,
    required this.color,
    required this.image,
    required this.createdAt,
  });

  factory ReelTemplate.fromJson(Map<String, dynamic> json) {
    return ReelTemplate(
      id: json['id'],
      name: json['name'],
      color: json['color'],
      image: json['image'],
      createdAt: json['createdAt'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'color': color,
    'image': image,
    'createdAt': createdAt,
  };
}

class ReelProject {
  final String id;
  final String createdAt;
  final String templateId;
  final String templateName;
  final String topic;
  final String character;
  final String topicMode;
  final int reelsCount;
  final int storiesPerHint;
  final int scenesCount;
  final bool videoVoiceEnabled;
  final String voiceLanguage;
  final bool externalDubbingEnabled;
  final String status;
  final String? generatedAt;

  ReelProject({
    required this.id,
    required this.createdAt,
    required this.templateId,
    required this.templateName,
    required this.topic,
    required this.character,
    required this.topicMode,
    required this.reelsCount,
    required this.storiesPerHint,
    required this.scenesCount,
    required this.videoVoiceEnabled,
    required this.voiceLanguage,
    required this.externalDubbingEnabled,
    required this.status,
    this.generatedAt,
  });

  factory ReelProject.fromJson(Map<String, dynamic> json) {
    return ReelProject(
      id: json['id'],
      createdAt: json['createdAt'],
      templateId: json['templateId'],
      templateName: json['templateName'],
      topic: json['topic'],
      character: json['character'],
      topicMode: json['topicMode'],
      reelsCount: json['reelsCount'],
      storiesPerHint: json['storiesPerHint'],
      scenesCount: json['scenesCount'],
      videoVoiceEnabled: json['videoVoiceEnabled'],
      voiceLanguage: json['voiceLanguage'],
      externalDubbingEnabled: json['externalDubbingEnabled'],
      status: json['status'],
      generatedAt: json['generatedAt'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'createdAt': createdAt,
    'templateId': templateId,
    'templateName': templateName,
    'topic': topic,
    'character': character,
    'topicMode': topicMode,
    'reelsCount': reelsCount,
    'storiesPerHint': storiesPerHint,
    'scenesCount': scenesCount,
    'videoVoiceEnabled': videoVoiceEnabled,
    'voiceLanguage': voiceLanguage,
    'externalDubbingEnabled': externalDubbingEnabled,
    'status': status,
    'generatedAt': generatedAt,
  };
}
