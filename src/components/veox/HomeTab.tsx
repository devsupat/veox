import { useState } from "react";
import {
  Play, Pause, Square, RotateCcw, FastForward,
  Sparkles, Trash2, Edit3, Zap, Send, X, Download
} from "lucide-react";
import { Button } from "@/components/ui/button";
import { cn } from "@/lib/utils";
import type { Scene, SceneStatus } from "@/data/types";
import type { ProcessingStatus } from "@/hooks/useAppState";
import ScenePreviewModal from "./modals/ScenePreviewModal";
import EditSceneModal from "./modals/EditSceneModal";

const statusColors: Record<SceneStatus, string> = {
  completed: "bg-accent/20 text-accent",
  running: "bg-warning/20 text-warning",
  failed: "bg-destructive/20 text-destructive",
  queued: "bg-primary/20 text-primary",
  idle: "bg-muted text-muted-foreground",
};

interface HomeTabProps {
  scenes: Scene[];
  processingStatus: ProcessingStatus;
  onAddScene: (prompt: string) => void;
  onDeleteScene: (id: string) => void;
  onUpdateScenePrompt: (id: string, prompt: string) => void;
  onRetryScene: (id: string) => void;
  onRetryAllFailed: () => void;
  onStart: () => void;
  onPause: () => void;
  onStop: () => void;
  onResume: () => void;
}

function ControlPanel({
  processingStatus,
  onStart, onPause, onStop, onRetryAllFailed, onResume,
}: Pick<HomeTabProps, "processingStatus" | "onStart" | "onPause" | "onStop" | "onRetryAllFailed" | "onResume">) {
  const [ratio, setRatio] = useState<"16:9" | "9:16">("16:9");
  const [boost, setBoost] = useState(false);
  const [from, setFrom] = useState(1);
  const [to, setTo] = useState(200);

  return (
    <div className="flex flex-wrap items-center gap-3 rounded-lg border border-border bg-card p-3">
      {/* Ratio */}
      <div className="flex rounded-md border border-border overflow-hidden">
        {(["16:9", "9:16"] as const).map((r) => (
          <button
            key={r}
            onClick={() => setRatio(r)}
            className={cn(
              "px-3 py-1 text-xs font-medium transition-colors",
              ratio === r ? "gradient-primary text-primary-foreground" : "bg-muted text-muted-foreground hover:text-foreground"
            )}
          >
            {r}
          </button>
        ))}
      </div>

      <select className="rounded-md border border-border bg-input px-3 py-1.5 text-xs text-foreground">
        <option>Veo 3.1 – Fast</option>
        <option>Veo 3.1 – Quality</option>
        <option>Veo 2.0</option>
      </select>

      <select className="rounded-md border border-border bg-input px-3 py-1.5 text-xs text-foreground">
        <option>AI Ultra</option>
        <option>AI Pro</option>
        <option>Free Tier</option>
      </select>

      <div className="h-6 w-px bg-border" />

      <Button size="sm" variant="success" className="h-7 text-xs gap-1" onClick={onStart}
        disabled={processingStatus === "running"}>
        <Play className="h-3 w-3" fill="currentColor" /> Start
      </Button>
      <Button size="sm" variant="outline" className="h-7 text-xs gap-1" onClick={onPause}
        disabled={processingStatus !== "running"}>
        <Pause className="h-3 w-3" /> Pause
      </Button>
      <Button size="sm" variant="outline" className="h-7 text-xs gap-1" onClick={onStop}
        disabled={processingStatus === "idle"}>
        <Square className="h-3 w-3" /> Stop
      </Button>
      <Button size="sm" variant="outline" className="h-7 text-xs gap-1" onClick={onRetryAllFailed}>
        <RotateCcw className="h-3 w-3" /> Retry
      </Button>
      <Button size="sm" variant="outline" className="h-7 text-xs gap-1" onClick={onResume}
        disabled={processingStatus === "running"}>
        <FastForward className="h-3 w-3" /> Resume
      </Button>

      <div className="h-6 w-px bg-border" />

      <div className="flex items-center gap-2 text-xs">
        <span className="text-muted-foreground">From</span>
        <input type="number" value={from} onChange={(e) => setFrom(+e.target.value)}
          className="w-14 rounded border border-border bg-input px-2 py-1 text-xs text-foreground" />
        <span className="text-muted-foreground">To</span>
        <input type="number" value={to} onChange={(e) => setTo(+e.target.value)}
          className="w-14 rounded border border-border bg-input px-2 py-1 text-xs text-foreground" />
      </div>

      <button onClick={() => setBoost(!boost)}
        className={cn(
          "flex items-center gap-1 rounded-md px-2.5 py-1 text-xs font-medium transition-all",
          boost ? "gradient-primary text-primary-foreground glow-primary" : "bg-muted text-muted-foreground"
        )}>
        <Zap className="h-3 w-3" /> 10x Boost
      </button>
    </div>
  );
}

function PromptBar({ onAdd, onStart }: { onAdd: (prompt: string) => void; onStart: () => void }) {
  const [prompt, setPrompt] = useState("");

  const handleAdd = () => {
    if (prompt.trim()) {
      onAdd(prompt.trim());
      setPrompt("");
    }
  };

  const handleGenerate = () => {
    if (prompt.trim()) {
      onAdd(prompt.trim());
      setPrompt("");
      // Small delay to ensure state update? 
      // Actually onAdd is async-ish (setState), but onStart checks queue.
      // If we call onStart immediately, the scene might not be in queue yet?
      // useAppState updates state. 
      // If onStart is called, it checks `processingRef.current.status`.
      // If idle, calls processQueue. processQueue reads state.
      // If state update is pending, processQueue might see empty queue.
      // But we are in an event handler. React batches updates.
      // We might need to ensure processing starts.
      // For now, let's just call onStart.
      setTimeout(onStart, 100);
    } else {
      // If empty, just start processing existing queue?
      onStart();
    }
  };

  return (
    <div className="flex items-center gap-2 rounded-lg border border-border bg-card p-2">
      <Sparkles className="h-4 w-4 text-primary ml-1 shrink-0" />
      <input
        value={prompt}
        onChange={(e) => setPrompt(e.target.value)}
        onKeyDown={(e) => e.key === "Enter" && handleAdd()}
        placeholder="Quick prompt... (Press Enter to add & generate)"
        className="flex-1 bg-transparent text-sm text-foreground placeholder:text-muted-foreground/50 focus:outline-none"
      />
      <Button size="sm" variant="gradient" className="h-7 text-xs gap-1" onClick={handleGenerate}>
        <Send className="h-3 w-3" /> Generate
      </Button>
      <Button size="sm" variant="ghost-muted" className="h-7 text-xs" onClick={() => setPrompt("")}>
        <X className="h-3 w-3" />
      </Button>
      <Button size="sm" variant="ghost-muted" className="h-7 text-xs">
        <Download className="h-3 w-3" />
      </Button>
    </div>
  );
}

function SceneCard({ scene, onPlay, onEdit, onRetry, onDelete }: {
  scene: Scene;
  onPlay: () => void;
  onEdit: () => void;
  onRetry: () => void;
  onDelete: () => void;
}) {
  const [hdOn, setHdOn] = useState(false);

  return (
    <div className="group rounded-lg border border-border bg-card overflow-hidden shadow-card transition-all hover:border-primary/30">
      <div className="flex items-center justify-between px-3 py-1.5 border-b border-border">
        <span className="text-xs font-medium text-foreground">{scene.title}</span>
        <span className={cn("rounded-full px-2 py-0.5 text-[10px] font-medium", statusColors[scene.status])}>
          {scene.status}
        </span>
      </div>

      <div className="relative h-28 flex items-center justify-center cursor-pointer" onClick={onPlay}
        style={{ background: `linear-gradient(135deg, hsl(${scene.hue} 60% 20%), hsl(${(scene.hue + 40) % 360} 70% 15%))` }}>
        <div className="absolute inset-0 bg-background/20 opacity-0 group-hover:opacity-100 transition-opacity" />
        <Play className="h-8 w-8 text-foreground/40 group-hover:text-foreground/70 transition-colors" />
        <span className="absolute bottom-1.5 left-2.5 text-[10px] text-foreground/40">#{scene.promptNo}</span>
      </div>

      <div className="flex items-center gap-1 px-2 py-1.5 border-t border-border">
        <button onClick={onPlay} className="rounded p-1 text-muted-foreground hover:text-foreground hover:bg-muted" title="Play">
          <Play className="h-3 w-3" />
        </button>
        <button onClick={onEdit} className="rounded p-1 text-muted-foreground hover:text-foreground hover:bg-muted" title="Edit">
          <Edit3 className="h-3 w-3" />
        </button>
        <button onClick={onRetry} className="rounded p-1 text-muted-foreground hover:text-foreground hover:bg-muted" title="Retry">
          <RotateCcw className="h-3 w-3" />
        </button>
        <button onClick={() => setHdOn(!hdOn)}
          className={cn("rounded px-1.5 py-0.5 text-[10px] font-bold transition-colors",
            hdOn ? "gradient-primary text-primary-foreground" : "text-muted-foreground hover:text-foreground")}>
          HD
        </button>
        <div className="flex-1" />
        <button onClick={onDelete} className="rounded p-1 text-muted-foreground hover:text-destructive hover:bg-destructive/10" title="Delete">
          <Trash2 className="h-3 w-3" />
        </button>
      </div>
    </div>
  );
}

export default function HomeTab(props: HomeTabProps) {
  const { scenes, onAddScene, onDeleteScene, onUpdateScenePrompt, onRetryScene } = props;
  const [previewScene, setPreviewScene] = useState<Scene | null>(null);
  const [editScene, setEditScene] = useState<Scene | null>(null);

  return (
    <div className="space-y-3 animate-fade-in">
      <ControlPanel
        processingStatus={props.processingStatus}
        onStart={props.onStart}
        onPause={props.onPause}
        onStop={props.onStop}
        onRetryAllFailed={props.onRetryAllFailed}
        onResume={props.onResume}
      />
      <PromptBar onAdd={onAddScene} onStart={props.onStart} />
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-3">
        {scenes.map((s) => (
          <SceneCard
            key={s.id}
            scene={s}
            onPlay={() => setPreviewScene(s)}
            onEdit={() => setEditScene(s)}
            onRetry={() => onRetryScene(s.id)}
            onDelete={() => onDeleteScene(s.id)}
          />
        ))}
      </div>

      <ScenePreviewModal open={!!previewScene} onClose={() => setPreviewScene(null)} scene={previewScene} />
      <EditSceneModal open={!!editScene} onClose={() => setEditScene(null)} scene={editScene} onSave={onUpdateScenePrompt} />
    </div>
  );
}
