import { Plus, Trash2, Film, Clock, Layers, Crown } from "lucide-react";
import { Button } from "@/components/ui/button";
import type { Project, Scene } from "@/data/types";

interface Props {
  projects: Project[];
  scenesByProjectId: Record<string, Scene[]>;
  onOpenProject: (id: string) => void;
  onNewProject: () => void;
  onDeleteProject: (id: string) => void;
}

export default function ProjectDashboard({ projects, scenesByProjectId, onOpenProject, onNewProject, onDeleteProject }: Props) {
  const formatDate = (iso: string) => {
    const d = new Date(iso);
    const now = new Date();
    const diff = Math.floor((now.getTime() - d.getTime()) / (1000 * 60 * 60 * 24));
    if (diff === 0) return `Today ${d.toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" })}`;
    if (diff === 1) return "Yesterday";
    if (diff < 7) return `${diff} days ago`;
    return `${Math.floor(diff / 7)} week${diff >= 14 ? "s" : ""} ago`;
  };

  const getStats = (pid: string) => {
    const ss = scenesByProjectId[pid] ?? [];
    return {
      total: ss.length,
      done: ss.filter((s) => s.status === "completed").length,
      failed: ss.filter((s) => s.status === "failed").length,
    };
  };

  return (
    <div className="animate-fade-in">
      <div className="mb-6 flex items-center justify-between rounded-xl p-6 gradient-hero">
        <div>
          <h1 className="text-2xl font-display font-bold text-primary-foreground flex items-center gap-2">
            VEOX Studio
            <span className="flex items-center gap-1 rounded-full bg-primary-foreground/20 px-2.5 py-0.5 text-[10px] font-semibold">
              <Crown className="h-3 w-3" /> PREMIUM
            </span>
          </h1>
          <p className="text-sm text-primary-foreground/70 mt-1">Your AI Video Automation Workspace</p>
        </div>
        <Button
          variant="outline"
          className="border-primary-foreground/30 text-primary-foreground hover:bg-primary-foreground/10"
          onClick={onNewProject}
        >
          <Plus className="h-4 w-4 mr-1" /> New Project
        </Button>
      </div>

      <h2 className="text-sm font-semibold text-foreground font-display mb-3">Recent Projects</h2>
      {projects.length === 0 && (
        <p className="text-xs text-muted-foreground text-center py-8">No projects yet. Create one to get started!</p>
      )}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-3">
        {projects.map((p) => {
          const st = getStats(p.id);
          return (
            <div
              key={p.id}
              onClick={() => onOpenProject(p.id)}
              className="group cursor-pointer rounded-lg border border-border bg-card overflow-hidden shadow-card hover:border-primary/30 transition-all"
            >
              <div
                className="h-28 flex items-center justify-center"
                style={{
                  background: `linear-gradient(135deg, hsl(${(p.id.charCodeAt(0) * 40 + 220) % 360} 40% 18%), hsl(${(p.id.charCodeAt(0) * 40 + 260) % 360} 50% 12%))`,
                }}
              >
                <Film className="h-8 w-8 text-foreground/20" />
              </div>
              <div className="p-3">
                <h3 className="text-xs font-semibold text-foreground truncate">{p.name}</h3>
                <div className="flex items-center gap-2 mt-1.5 text-[10px] text-muted-foreground">
                  <Clock className="h-3 w-3" />
                  {formatDate(p.updatedAt)}
                </div>
                <div className="flex items-center justify-between mt-2">
                  <div className="flex items-center gap-2 text-[10px] text-muted-foreground">
                    <span className="flex items-center gap-0.5"><Layers className="h-3 w-3" /> {st.total}</span>
                    <span className="text-success">{st.done} done</span>
                    {st.failed > 0 && <span className="text-destructive">{st.failed} failed</span>}
                  </div>
                  <button
                    onClick={(e) => { e.stopPropagation(); onDeleteProject(p.id); }}
                    className="rounded p-1 text-muted-foreground/50 hover:text-destructive hover:bg-destructive/10 opacity-0 group-hover:opacity-100 transition-all"
                  >
                    <Trash2 className="h-3.5 w-3.5" />
                  </button>
                </div>
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
}
