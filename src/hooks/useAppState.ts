import { useState, useCallback, useRef, useEffect } from "react";
import type { AppState, Project, Scene, LogEntry, SceneStatus, ProjectSettings } from "@/data/types";

const STORAGE_KEYS = {
  PROJECTS: "veox.projects",
  ACTIVE_PROJECT_ID: "veox.activeProjectId",
  SCENES: "veox.scenes",
  QUEUE: "veox.queue",
  LOGS: "veox.logs",
};
const MAX_LOGS = 500;

function generateId(): string {
  return Date.now().toString(36) + Math.random().toString(36).slice(2, 7);
}

const defaultSettings: ProjectSettings = {
  ratio: "16:9",
  model: "Veo 3.1 – Fast",
  account: "AI Ultra",
  boost: false,
};

function loadState(): AppState {
  try {
    const projectsRaw = localStorage.getItem(STORAGE_KEYS.PROJECTS);
    const activeProjectIdRaw = localStorage.getItem(STORAGE_KEYS.ACTIVE_PROJECT_ID);
    const scenesRaw = localStorage.getItem(STORAGE_KEYS.SCENES);
    const queueRaw = localStorage.getItem(STORAGE_KEYS.QUEUE);
    const logsRaw = localStorage.getItem(STORAGE_KEYS.LOGS);

    if (projectsRaw) {
      const projects = JSON.parse(projectsRaw);
      const activeProjectId = activeProjectIdRaw ? JSON.parse(activeProjectIdRaw) : null;
      const scenesByProjectId = scenesRaw ? JSON.parse(scenesRaw) : {};
      const queue = queueRaw ? JSON.parse(queueRaw) : [];
      const logs = logsRaw ? JSON.parse(logsRaw) : [];

      return { activeProjectId, projects, scenesByProjectId, queue, logs };
    }
  } catch { }

  // seed with demo data
  const demoProject: Project = {
    id: "demo",
    name: "Demo Project",
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString(),
    settings: { ...defaultSettings },
  };
  const demoScenes: Scene[] = Array.from({ length: 8 }, (_, i) => ({
    id: `s-${i}`,
    index: i,
    title: `Scene ${i + 1}`,
    promptNo: i + 1,
    status: (i < 4 ? "completed" : i < 6 ? "queued" : "idle") as SceneStatus,
    prompt: [
      "A futuristic city at dawn",
      "Ocean waves crashing on rocks",
      "Mountain peaks above clouds",
      "Neon streets in rain",
      "A robot in a garden",
      "Space station orbiting Earth",
      "Forest path in autumn",
      "Sunset over desert dunes",
    ][i],
    hue: (i * 30 + 200) % 360,
    durationSec: i < 4 ? Math.floor(Math.random() * 4) + 2 : 0,
    createdAt: new Date().toISOString(),
  }));

  return {
    activeProjectId: "demo",
    projects: [demoProject],
    scenesByProjectId: { demo: demoScenes },
    queue: demoScenes.filter(s => s.status === 'queued').map(s => s.id),
    logs: [],
  };
}

export type ProcessingStatus = "idle" | "running" | "paused";

export function useAppState() {
  const [state, setState] = useState<AppState>(loadState);
  const [processingStatus, setProcessingStatus] = useState<ProcessingStatus>("idle");
  const processingRef = useRef<{ status: ProcessingStatus; cancel: boolean }>({ status: "idle", cancel: false });

  // persist
  useEffect(() => {
    try {
      localStorage.setItem(STORAGE_KEYS.PROJECTS, JSON.stringify(state.projects));
      localStorage.setItem(STORAGE_KEYS.ACTIVE_PROJECT_ID, JSON.stringify(state.activeProjectId));
      localStorage.setItem(STORAGE_KEYS.SCENES, JSON.stringify(state.scenesByProjectId));
      localStorage.setItem(STORAGE_KEYS.QUEUE, JSON.stringify(state.queue));
      localStorage.setItem(STORAGE_KEYS.LOGS, JSON.stringify(state.logs));
    } catch { }
  }, [state]);

  const addLog = useCallback((level: LogEntry["level"], message: string) => {
    setState((prev) => ({
      ...prev,
      logs: [
        ...prev.logs.slice(-(MAX_LOGS - 1)),
        { id: generateId(), timestamp: new Date().toISOString(), level, message },
      ],
    }));
  }, []);

  const activeProject = state.projects.find((p) => p.id === state.activeProjectId) ?? null;
  const scenes = state.activeProjectId ? state.scenesByProjectId[state.activeProjectId] ?? [] : [];

  // Project actions
  const createProject = useCallback(
    (name: string) => {
      const id = generateId();
      const project: Project = {
        id,
        name,
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString(),
        settings: { ...defaultSettings },
      };
      setState((prev) => ({
        ...prev,
        activeProjectId: id,
        projects: [...prev.projects, project],
        scenesByProjectId: { ...prev.scenesByProjectId, [id]: [] },
        queue: [],
      }));
      addLog("SUCCESS", `Created project "${name}"`);
      return id;
    },
    [addLog]
  );

  const deleteProject = useCallback(
    (id: string) => {
      setState((prev) => {
        const { [id]: _, ...rest } = prev.scenesByProjectId;
        const projects = prev.projects.filter((p) => p.id !== id);
        return {
          ...prev,
          projects,
          scenesByProjectId: rest,
          activeProjectId: prev.activeProjectId === id ? null : prev.activeProjectId,
          queue: prev.activeProjectId === id ? [] : prev.queue,
        };
      });
      addLog("WARN", `Deleted project ${id}`);
    },
    [addLog]
  );

  const loadProject = useCallback(
    (id: string) => {
      setState((prev) => {
        const scenes = prev.scenesByProjectId[id] ?? [];
        const newQueue = scenes.filter(s => s.status === 'queued').map(s => s.id);
        return { ...prev, activeProjectId: id, queue: newQueue };
      });
      const p = state.projects.find((p) => p.id === id);
      addLog("INFO", `Loaded project "${p?.name ?? id}"`);
    },
    [addLog, state.projects]
  );

  const saveProject = useCallback(() => {
    if (!state.activeProjectId) return;
    setState((prev) => ({
      ...prev,
      projects: prev.projects.map((p) =>
        p.id === prev.activeProjectId ? { ...p, updatedAt: new Date().toISOString() } : p
      ),
    }));
    addLog("SUCCESS", `Saved project "${activeProject?.name}"`);
  }, [addLog, activeProject, state.activeProjectId]);

  // Scene actions
  const addScene = useCallback(
    (prompt: string, status: SceneStatus = "queued") => {
      if (!state.activeProjectId) return;
      setState((prev) => {
        if (!prev.activeProjectId) return prev;
        const current = prev.scenesByProjectId[prev.activeProjectId] ?? [];
        const idx = current.length;
        const scene: Scene = {
          id: generateId(),
          index: idx,
          title: `Scene ${idx + 1}`,
          promptNo: idx + 1,
          status,
          prompt,
          hue: (idx * 30 + 200) % 360,
          durationSec: 0,
          createdAt: new Date().toISOString(),
        };
        const nextQueue = status === "queued" ? [...prev.queue, scene.id] : prev.queue;
        return {
          ...prev,
          scenesByProjectId: { ...prev.scenesByProjectId, [prev.activeProjectId]: [...current, scene] },
          queue: nextQueue
        };
      });
      addLog("INFO", `Added scene: "${prompt.slice(0, 40)}..."`);
    },
    [state.activeProjectId, addLog]
  );

  const pastePrompts = useCallback(
    (text: string) => {
      const lines = text.split("\n").map((l) => l.trim()).filter(Boolean);
      lines.forEach((line) => addScene(line, "queued"));
      addLog("SUCCESS", `Pasted ${lines.length} prompts`);
    },
    [addScene, addLog]
  );

  const deleteScene = useCallback(
    (sceneId: string) => {
      setState((prev) => {
        if (!prev.activeProjectId) return prev;
        const current = prev.scenesByProjectId[prev.activeProjectId] ?? [];
        const nextScenes = current.filter((s) => s.id !== sceneId);
        const nextQueue = prev.queue.filter(id => id !== sceneId);
        return {
          ...prev,
          scenesByProjectId: { ...prev.scenesByProjectId, [prev.activeProjectId]: nextScenes },
          queue: nextQueue
        };
      });
      addLog("INFO", `Deleted scene ${sceneId}`);
    },
    [addLog]
  );

  const updateScenePrompt = useCallback(
    (sceneId: string, prompt: string) => {
      setState((prev) => {
        if (!prev.activeProjectId) return prev;
        const current = prev.scenesByProjectId[prev.activeProjectId] ?? [];
        const nextScenes = current.map((s) => (s.id === sceneId ? { ...s, prompt } : s));
        return {
          ...prev,
          scenesByProjectId: { ...prev.scenesByProjectId, [prev.activeProjectId]: nextScenes },
        };
      });
    },
    []
  );

  const retryScene = useCallback(
    (sceneId: string) => {
      setState((prev) => {
        if (!prev.activeProjectId) return prev;
        const current = prev.scenesByProjectId[prev.activeProjectId] ?? [];
        const nextScenes = current.map((s) => (s.id === sceneId && s.status === "failed" ? { ...s, status: "queued" as SceneStatus } : s));

        let nextQueue = prev.queue;
        const scene = current.find(s => s.id === sceneId);
        if (scene && scene.status === "failed" && !nextQueue.includes(sceneId)) {
          nextQueue = [...nextQueue, sceneId];
        }

        return {
          ...prev,
          scenesByProjectId: { ...prev.scenesByProjectId, [prev.activeProjectId]: nextScenes },
          queue: nextQueue
        };
      });
      addLog("INFO", `Retrying scene ${sceneId}`);
    },
    [addLog]
  );

  const retryAllFailed = useCallback(() => {
    setState((prev) => {
      if (!prev.activeProjectId) return prev;
      const current = prev.scenesByProjectId[prev.activeProjectId] ?? [];
      const failedIds = current.filter(s => s.status === "failed").map(s => s.id);

      const nextScenes = current.map((s) => (s.status === "failed" ? { ...s, status: "queued" as SceneStatus } : s));
      const nextQueue = [...prev.queue, ...failedIds.filter(id => !prev.queue.includes(id))];

      return {
        ...prev,
        scenesByProjectId: { ...prev.scenesByProjectId, [prev.activeProjectId]: nextScenes },
        queue: nextQueue
      };
    });
    addLog("INFO", "Retried all failed scenes");
  }, [addLog]);

  // Processing queue
  const processQueue = useCallback(async () => {
    processingRef.current = { status: "running", cancel: false };
    setProcessingStatus("running");
    addLog("INFO", "Processing started");

    while (true) {
      if (processingRef.current.cancel) break;
      if (processingRef.current.status === "paused") {
        await new Promise((r) => setTimeout(r, 200));
        continue;
      }

      let nextSceneId: string | null = null;
      let nextScenePrompt: string = "";

      // Atomic pop from queue and set status
      setState((prev) => {
        if (prev.queue.length === 0) return prev;
        if (!prev.activeProjectId) return prev;

        const [first, ...rest] = prev.queue;
        nextSceneId = first;

        const current = prev.scenesByProjectId[prev.activeProjectId] ?? [];
        const scene = current.find(s => s.id === first);
        if (scene) nextScenePrompt = scene.prompt;

        const nextScenes = current.map(s => s.id === first ? { ...s, status: "running" as SceneStatus } : s);

        return {
          ...prev,
          queue: rest,
          scenesByProjectId: { ...prev.scenesByProjectId, [prev.activeProjectId]: nextScenes }
        };
      });

      if (!nextSceneId) break;

      addLog("INFO", `Processing scene: ${nextScenePrompt.slice(0, 40)}...`);

      const duration = Math.floor(Math.random() * 3000) + 2000;
      await new Promise((r) => setTimeout(r, duration));

      if (processingRef.current.cancel) {
        // Revert status to queued and put back in queue
        setState((prev) => {
          if (!prev.activeProjectId) return prev;
          const ss = prev.scenesByProjectId[prev.activeProjectId] ?? [];
          return {
            ...prev,
            queue: [nextSceneId!, ...prev.queue],
            scenesByProjectId: {
              ...prev.scenesByProjectId,
              [prev.activeProjectId]: ss.map((s) => (s.id === nextSceneId && s.status === "running" ? { ...s, status: "queued" as SceneStatus } : s)),
            },
          };
        });
        break;
      }

      const durationSec = Math.round(duration / 1000);
      const success = Math.random() > 0.1;

      setState((prev) => {
        if (!prev.activeProjectId) return prev;
        const ss = prev.scenesByProjectId[prev.activeProjectId] ?? [];
        return {
          ...prev,
          scenesByProjectId: {
            ...prev.scenesByProjectId,
            [prev.activeProjectId]: ss.map((s) =>
              s.id === nextSceneId
                ? { ...s, status: (success ? "completed" : "failed") as SceneStatus, durationSec: success ? durationSec : 0 }
                : s
            ),
          },
        };
      });
      addLog(success ? "SUCCESS" : "ERROR", `Scene ${nextSceneId} ${success ? "completed" : "failed"} (${durationSec}s)`);
    }

    processingRef.current = { status: "idle", cancel: false };
    setProcessingStatus("idle");
    addLog("INFO", "Processing stopped");
  }, [addLog]);

  const startProcessing = useCallback(() => {
    if (processingRef.current.status === "idle") {
      processQueue();
    }
  }, [processQueue]);

  const pauseProcessing = useCallback(() => {
    processingRef.current.status = "paused";
    setProcessingStatus("paused");
    addLog("WARN", "Processing paused");
  }, [addLog]);

  const resumeProcessing = useCallback(() => {
    if (processingRef.current.status === "paused") {
      processingRef.current.status = "running";
      setProcessingStatus("running");
      addLog("INFO", "Processing resumed");
    } else if (processingRef.current.status === "idle") {
      processQueue();
    }
  }, [addLog, processQueue]);

  const stopProcessing = useCallback(() => {
    processingRef.current.cancel = true;
    addLog("WARN", "Processing stopped");
  }, [addLog]);

  // Stats
  const stats = {
    total: scenes.length,
    done: scenes.filter((s) => s.status === "completed").length,
    active: scenes.filter((s) => s.status === "running").length,
    failed: scenes.filter((s) => s.status === "failed").length,
  };

  return {
    state,
    activeProject,
    scenes,
    stats,
    processingStatus,
    logs: state.logs,
    createProject,
    deleteProject,
    loadProject,
    saveProject,
    addScene,
    pastePrompts,
    deleteScene,
    updateScenePrompt,
    retryScene,
    retryAllFailed,
    startProcessing,
    pauseProcessing,
    resumeProcessing,
    stopProcessing,
    addLog,
  };
}
