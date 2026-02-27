import { useState } from "react";
import { Mic, Volume2, FileAudio, Loader2 } from "lucide-react";
import { Button } from "@/components/ui/button";
import { cn } from "@/lib/utils";
import { dummyVoiceFiles, dummyQueue } from "@/data/dummy";

const presets = ["Natural", "Energetic", "Calm", "Storyteller", "Podcast"];

export default function AIVoiceTab() {
  const [preset, setPreset] = useState("Natural");
  const [text, setText] = useState("");
  const [pace, setPace] = useState(1.0);
  const [tone, setTone] = useState("Neutral");
  const [style, setStyle] = useState("Conversational");

  return (
    <div className="grid grid-cols-[240px_1fr_240px] gap-4 h-full animate-fade-in">
      {/* Left: Voice Settings */}
      <div className="space-y-4 rounded-lg border border-border bg-card p-4">
        <h3 className="text-sm font-semibold text-foreground font-display">Voice Settings</h3>

        <div className="space-y-3">
          <div>
            <label className="text-[10px] uppercase tracking-wider text-muted-foreground/60 mb-1 block">Voice</label>
            <select className="w-full rounded-md border border-border bg-input px-3 py-1.5 text-xs text-foreground">
              <option>Male – Deep</option>
              <option>Male – Neutral</option>
              <option>Female – Warm</option>
              <option>Female – Clear</option>
            </select>
          </div>

          <div>
            <label className="text-[10px] uppercase tracking-wider text-muted-foreground/60 mb-1 block">Model</label>
            <select className="w-full rounded-md border border-border bg-input px-3 py-1.5 text-xs text-foreground">
              <option>Gemini TTS</option>
              <option>ElevenLabs</option>
              <option>OpenAI TTS</option>
            </select>
          </div>

          <div>
            <label className="text-[10px] uppercase tracking-wider text-muted-foreground/60 mb-2 block">Presets</label>
            <div className="flex flex-wrap gap-1.5">
              {presets.map((p) => (
                <button
                  key={p}
                  onClick={() => setPreset(p)}
                  className={cn(
                    "rounded-full px-2.5 py-1 text-[11px] font-medium transition-all",
                    preset === p
                      ? "gradient-primary text-primary-foreground glow-primary"
                      : "bg-muted text-muted-foreground hover:text-foreground"
                  )}
                >
                  {p}
                </button>
              ))}
            </div>
          </div>

          <div>
            <label className="text-[10px] uppercase tracking-wider text-muted-foreground/60 mb-1 block">Pace</label>
            <input
              type="range"
              min={0.5}
              max={2}
              step={0.1}
              value={pace}
              onChange={(e) => setPace(+e.target.value)}
              className="w-full accent-primary"
            />
            <span className="text-[10px] text-muted-foreground">{pace.toFixed(1)}x</span>
          </div>

          <div>
            <label className="text-[10px] uppercase tracking-wider text-muted-foreground/60 mb-1 block">Tone</label>
            <select
              value={tone}
              onChange={(e) => setTone(e.target.value)}
              className="w-full rounded-md border border-border bg-input px-3 py-1.5 text-xs text-foreground"
            >
              <option>Neutral</option>
              <option>Warm</option>
              <option>Authoritative</option>
              <option>Friendly</option>
            </select>
          </div>

          <div>
            <label className="text-[10px] uppercase tracking-wider text-muted-foreground/60 mb-1 block">Style</label>
            <select
              value={style}
              onChange={(e) => setStyle(e.target.value)}
              className="w-full rounded-md border border-border bg-input px-3 py-1.5 text-xs text-foreground"
            >
              <option>Conversational</option>
              <option>Narration</option>
              <option>News</option>
              <option>Dramatic</option>
            </select>
          </div>
        </div>
      </div>

      {/* Center: Text Area */}
      <div className="flex flex-col rounded-lg border border-border bg-card p-4">
        <h3 className="text-sm font-semibold text-foreground font-display mb-3">Text to Generate</h3>
        <textarea
          value={text}
          onChange={(e) => setText(e.target.value)}
          placeholder="Enter or paste your text here..."
          className="flex-1 rounded-md border border-border bg-input p-3 text-sm text-foreground placeholder:text-muted-foreground/40 resize-none focus:outline-none focus:ring-1 focus:ring-primary"
        />
        <div className="flex items-center justify-between mt-3">
          <span className="text-[10px] text-muted-foreground">{text.length} characters</span>
          <Button variant="gradient" size="sm" className="gap-1.5">
            <Mic className="h-3.5 w-3.5" /> Generate Voice
          </Button>
        </div>
      </div>

      {/* Right: Queue & Files */}
      <div className="space-y-4">
        <div className="rounded-lg border border-border bg-card p-4">
          <h3 className="text-sm font-semibold text-foreground font-display mb-3">Processing Queue</h3>
          <div className="space-y-2">
            {dummyQueue.map((q) => (
              <div key={q.id} className="flex items-center gap-2 text-xs">
                {q.status === "processing" ? (
                  <Loader2 className="h-3 w-3 text-warning animate-spin" />
                ) : q.status === "done" ? (
                  <div className="h-3 w-3 rounded-full bg-success" />
                ) : (
                  <div className="h-3 w-3 rounded-full bg-muted" />
                )}
                <span className="text-muted-foreground">{q.label}</span>
              </div>
            ))}
          </div>
        </div>

        <div className="rounded-lg border border-border bg-card p-4">
          <h3 className="text-sm font-semibold text-foreground font-display mb-3">Generated Files</h3>
          <div className="space-y-1.5">
            {dummyVoiceFiles.map((f) => (
              <div key={f.id} className="flex items-center gap-2 rounded-md bg-muted/50 px-2.5 py-1.5">
                <FileAudio className="h-3.5 w-3.5 text-accent" />
                <span className="text-xs text-foreground truncate flex-1">{f.name}</span>
                <span className="text-[10px] text-muted-foreground">{f.duration}</span>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}
