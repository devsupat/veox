import { useState } from "react";
import { Plus, Film } from "lucide-react";
import { Button } from "@/components/ui/button";
import { cn } from "@/lib/utils";

const templates = [
  { id: "t1", name: "Motivational", color: 263 },
  { id: "t2", name: "Tech Review", color: 220 },
  { id: "t3", name: "Story Time", color: 340 },
];

export default function ReelsTab() {
  const [mode, setMode] = useState<"single" | "perline">("single");
  const [videoVoice, setVideoVoice] = useState(true);
  const [dubbing, setDubbing] = useState(false);

  return (
    <div className="space-y-4 animate-fade-in">
      {/* Templates */}
      <div className="flex items-center gap-3 overflow-x-auto pb-2 scrollbar-thin">
        {templates.map((t) => (
          <div
            key={t.id}
            className="flex-shrink-0 w-36 h-20 rounded-lg border border-border flex flex-col items-center justify-center cursor-pointer hover:border-primary/40 transition-colors"
            style={{ background: `linear-gradient(135deg, hsl(${t.color} 50% 18%), hsl(${t.color} 60% 12%))` }}
          >
            <Film className="h-5 w-5 text-foreground/50 mb-1" />
            <span className="text-xs text-foreground/70">{t.name}</span>
          </div>
        ))}
        <button className="flex-shrink-0 w-36 h-20 rounded-lg border border-dashed border-border flex flex-col items-center justify-center text-muted-foreground hover:text-foreground hover:border-primary/40 transition-colors">
          <Plus className="h-5 w-5 mb-1" />
          <span className="text-xs">New Template</span>
        </button>
      </div>

      {/* Form */}
      <div className="rounded-lg border border-border bg-card p-4 max-w-2xl space-y-4">
        <div>
          <label className="text-[10px] uppercase tracking-wider text-muted-foreground/60 mb-1 block">Topic</label>
          <input
            placeholder="Enter topic here..."
            className="w-full rounded-md border border-border bg-input px-3 py-2 text-sm text-foreground placeholder:text-muted-foreground/40 focus:outline-none focus:ring-1 focus:ring-primary"
          />
        </div>

        <div className="grid grid-cols-2 gap-4">
          <div>
            <label className="text-[10px] uppercase tracking-wider text-muted-foreground/60 mb-1 block">Character</label>
            <select className="w-full rounded-md border border-border bg-input px-3 py-1.5 text-xs text-foreground">
              <option>Boy</option>
              <option>Girl</option>
              <option>Robot</option>
              <option>Narrator</option>
            </select>
          </div>
          <div>
            <label className="text-[10px] uppercase tracking-wider text-muted-foreground/60 mb-1 block">Mode</label>
            <div className="flex gap-3">
              {(["single", "perline"] as const).map((m) => (
                <label key={m} className="flex items-center gap-1.5 text-xs text-muted-foreground cursor-pointer">
                  <div className={cn("h-3.5 w-3.5 rounded-full border-2 transition-colors",
                    mode === m ? "border-primary bg-primary" : "border-muted-foreground"
                  )} />
                  {m === "single" ? "Single Topic" : "One Per Line"}
                </label>
              ))}
            </div>
          </div>
        </div>

        <div className="grid grid-cols-3 gap-4">
          <div>
            <label className="text-[10px] uppercase tracking-wider text-muted-foreground/60 mb-1 block">Reels</label>
            <input type="number" defaultValue={1} className="w-full rounded-md border border-border bg-input px-3 py-1.5 text-xs text-foreground" />
          </div>
          <div>
            <label className="text-[10px] uppercase tracking-wider text-muted-foreground/60 mb-1 block">Stories/Hint</label>
            <input type="number" defaultValue={1} className="w-full rounded-md border border-border bg-input px-3 py-1.5 text-xs text-foreground" />
          </div>
          <div>
            <label className="text-[10px] uppercase tracking-wider text-muted-foreground/60 mb-1 block">Scenes</label>
            <input type="number" defaultValue={12} className="w-full rounded-md border border-border bg-input px-3 py-1.5 text-xs text-foreground" />
          </div>
        </div>

        {/* Toggles */}
        <div className="flex gap-6">
          {[
            { label: "Video Voice", val: videoVoice, set: setVideoVoice },
            { label: "External Dubbing", val: dubbing, set: setDubbing },
          ].map(({ label, val, set }) => (
            <label key={label} className="flex items-center gap-2 text-xs text-muted-foreground cursor-pointer">
              <button
                onClick={() => set(!val)}
                className={cn(
                  "relative h-5 w-9 rounded-full transition-colors",
                  val ? "bg-primary" : "bg-muted"
                )}
              >
                <div className={cn(
                  "absolute top-0.5 h-4 w-4 rounded-full bg-foreground transition-transform",
                  val ? "left-4.5 translate-x-0" : "left-0.5"
                )} />
              </button>
              {label}
            </label>
          ))}
        </div>

        <Button variant="gradient" className="gap-1.5">
          <Film className="h-4 w-4" /> Generate Content
        </Button>
      </div>
    </div>
  );
}
