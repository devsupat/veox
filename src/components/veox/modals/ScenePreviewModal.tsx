import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { Play } from "lucide-react";
import type { Scene } from "@/data/types";

interface Props {
  open: boolean;
  onClose: () => void;
  scene: Scene | null;
}

export default function ScenePreviewModal({ open, onClose, scene }: Props) {
  if (!scene) return null;
  return (
    <Dialog open={open} onOpenChange={(v) => !v && onClose()}>
      <DialogContent className="max-w-lg">
        <DialogHeader>
          <DialogTitle className="font-display">{scene.title} – Preview</DialogTitle>
        </DialogHeader>
        <div
          className="aspect-video rounded-lg flex items-center justify-center"
          style={{
            background: `linear-gradient(135deg, hsl(${scene.hue} 60% 20%), hsl(${(scene.hue + 40) % 360} 70% 15%))`,
          }}
        >
          <Play className="h-12 w-12 text-foreground/30" />
        </div>
        <p className="text-xs text-muted-foreground">{scene.prompt}</p>
        <p className="text-[10px] text-muted-foreground/50">
          Status: {scene.status} {scene.durationSec > 0 && `• Duration: ${scene.durationSec}s`}
        </p>
      </DialogContent>
    </Dialog>
  );
}
