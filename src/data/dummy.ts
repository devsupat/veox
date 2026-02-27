import type { VoiceFile, QueueItem } from "./types";

export const dummyVoiceFiles: VoiceFile[] = [
  { id: "v1", name: "intro_narration.wav", duration: "0:32", status: "completed" },
  { id: "v2", name: "scene_dialogue.wav", duration: "1:05", status: "completed" },
  { id: "v3", name: "outro_voice.wav", duration: "0:18", status: "processing" },
  { id: "v4", name: "chapter2_voice.wav", duration: "0:45", status: "queued" },
];

export const dummyQueue: QueueItem[] = [
  { id: "q1", label: "Voice Generation", status: "done" },
  { id: "q2", label: "Audio Processing", status: "processing" },
  { id: "q3", label: "Noise Reduction", status: "idle" },
];
