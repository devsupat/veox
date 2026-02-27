import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";
import type { Project } from "@/data/types";
import { FolderOpen } from "lucide-react";

interface Props {
  open: boolean;
  onClose: () => void;
  projects: Project[];
  onLoad: (id: string) => void;
}

export default function LoadProjectModal({ open, onClose, projects, onLoad }: Props) {
  return (
    <Dialog open={open} onOpenChange={(v) => !v && onClose()}>
      <DialogContent className="max-w-md">
        <DialogHeader>
          <DialogTitle className="font-display">Load Project</DialogTitle>
        </DialogHeader>
        <div className="space-y-2 max-h-60 overflow-y-auto scrollbar-thin">
          {projects.length === 0 && (
            <p className="text-xs text-muted-foreground text-center py-4">No saved projects.</p>
          )}
          {projects.map((p) => (
            <button
              key={p.id}
              onClick={() => { onLoad(p.id); onClose(); }}
              className="flex w-full items-center gap-3 rounded-lg border border-border bg-muted/30 px-3 py-2.5 text-left hover:border-primary/30 transition-colors"
            >
              <FolderOpen className="h-4 w-4 text-accent shrink-0" />
              <div className="flex-1 min-w-0">
                <p className="text-xs font-medium text-foreground truncate">{p.name}</p>
                <p className="text-[10px] text-muted-foreground">Updated {new Date(p.updatedAt).toLocaleDateString()}</p>
              </div>
            </button>
          ))}
        </div>
      </DialogContent>
    </Dialog>
  );
}
