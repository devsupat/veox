import { useState, useEffect } from "react";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";
import type { Scene } from "@/data/types";

interface Props {
  open: boolean;
  onClose: () => void;
  scene: Scene | null;
  onSave: (id: string, prompt: string) => void;
}

export default function EditSceneModal({ open, onClose, scene, onSave }: Props) {
  const [prompt, setPrompt] = useState("");

  useEffect(() => {
    if (scene) setPrompt(scene.prompt);
  }, [scene]);

  if (!scene) return null;

  return (
    <Dialog open={open} onOpenChange={(v) => !v && onClose()}>
      <DialogContent className="max-w-md">
        <DialogHeader>
          <DialogTitle className="font-display">Edit {scene.title}</DialogTitle>
        </DialogHeader>
        <textarea
          value={prompt}
          onChange={(e) => setPrompt(e.target.value)}
          rows={4}
          className="w-full rounded-md border border-border bg-input p-3 text-sm text-foreground resize-none focus:outline-none focus:ring-1 focus:ring-primary"
        />
        <div className="flex justify-end gap-2">
          <Button variant="outline" size="sm" onClick={onClose}>Cancel</Button>
          <Button variant="gradient" size="sm" onClick={() => { onSave(scene.id, prompt); onClose(); }}>Save</Button>
        </div>
      </DialogContent>
    </Dialog>
  );
}
