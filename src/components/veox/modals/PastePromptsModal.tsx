import { useState } from "react";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";

interface Props {
  open: boolean;
  onClose: () => void;
  onPaste: (text: string) => void;
}

export default function PastePromptsModal({ open, onClose, onPaste }: Props) {
  const [text, setText] = useState("");

  const handleSubmit = () => {
    if (text.trim()) {
      onPaste(text);
      setText("");
      onClose();
    }
  };

  return (
    <Dialog open={open} onOpenChange={(v) => !v && onClose()}>
      <DialogContent className="max-w-lg">
        <DialogHeader>
          <DialogTitle className="font-display">Paste Prompts</DialogTitle>
        </DialogHeader>
        <p className="text-xs text-muted-foreground">Enter one prompt per line. Each line becomes a new queued scene.</p>
        <textarea
          value={text}
          onChange={(e) => setText(e.target.value)}
          rows={8}
          placeholder="A cinematic shot of a futuristic city&#10;Ocean waves at sunset&#10;Mountains above the clouds"
          className="w-full rounded-md border border-border bg-input p-3 text-sm text-foreground placeholder:text-muted-foreground/40 resize-none focus:outline-none focus:ring-1 focus:ring-primary"
        />
        <div className="flex justify-end gap-2">
          <Button variant="outline" size="sm" onClick={onClose}>Cancel</Button>
          <Button variant="gradient" size="sm" onClick={handleSubmit}>
            Add {text.split("\n").filter((l) => l.trim()).length} Scenes
          </Button>
        </div>
      </DialogContent>
    </Dialog>
  );
}
