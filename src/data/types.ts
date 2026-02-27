export type SceneStatus = "idle" | "queued" | "running" | "completed" | "failed";

export interface Scene {
  id: string;
  index: number;
  title: string;
  promptNo: number;
  status: SceneStatus;
  prompt: string;
  hue: number;
  durationSec: number;
  createdAt: string;
}

export interface ProjectSettings {
  ratio: "16:9" | "9:16";
  model: string;
  account: string;
  boost: boolean;
}

export interface Project {
  id: string;
  name: string;
  createdAt: string;
  updatedAt: string;
  settings: ProjectSettings;
}

export interface LogEntry {
  id: string;
  timestamp: string;
  level: "INFO" | "SUCCESS" | "WARN" | "ERROR";
  message: string;
}

export interface AppState {
  activeProjectId: string | null;
  projects: Project[];
  scenesByProjectId: Record<string, Scene[]>;
  queue: string[]; // Ordered list of scene IDs
  logs: LogEntry[];
}

export interface VoiceFile {
  id: string;
  name: string;
  duration: string;
  status: "completed" | "processing" | "queued";
}

export interface QueueItem {
  id: string;
  label: string;
  status: "idle" | "processing" | "done" | "error";
}

export type TabId =
  | "home"
  | "character"
  | "scene-builder"
  | "clone-youtube"
  | "mastering"
  | "reels"
  | "av-match"
  | "settings"
  | "export"
  | "ai-voice"
  | "more-tools"
  | "projects";
