import { ChevronRight, Wifi, LogIn, PanelRightClose, PanelRight } from "lucide-react";
import { Button } from "@/components/ui/button";

interface StatusPanelProps {
  collapsed: boolean;
  onToggle: () => void;
  stats: { total: number; done: number; active: number; failed: number };
}

export default function StatusPanel({ collapsed, onToggle, stats }: StatusPanelProps) {
  const statItems = [
    { label: "Total", value: stats.total, color: "text-foreground" },
    { label: "Done", value: stats.done, color: "text-success" },
    { label: "Active", value: stats.active, color: "text-accent" },
    { label: "Failed", value: stats.failed, color: "text-destructive" },
  ];

  if (collapsed) {
    return (
      <aside className="flex w-10 flex-col items-center border-l border-border bg-sidebar py-2 shrink-0">
        <button onClick={onToggle} className="p-1 text-muted-foreground hover:text-foreground">
          <PanelRight className="h-4 w-4" />
        </button>
      </aside>
    );
  }

  return (
    <aside className="flex w-56 flex-col border-l border-border bg-sidebar shrink-0">
      <div className="flex items-center justify-between border-b border-border px-3 py-2">
        <span className="text-xs font-semibold text-foreground">Status</span>
        <button onClick={onToggle} className="p-0.5 text-muted-foreground hover:text-foreground">
          <PanelRightClose className="h-3.5 w-3.5" />
        </button>
      </div>

      <div className="flex-1 overflow-y-auto p-3 space-y-4 scrollbar-thin">
        <div className="grid grid-cols-2 gap-2">
          {statItems.map((s) => (
            <div key={s.label} className="rounded-lg bg-muted/50 p-2.5 text-center">
              <p className={`text-lg font-display font-bold ${s.color}`}>{s.value}</p>
              <p className="text-[10px] text-muted-foreground">{s.label}</p>
            </div>
          ))}
        </div>

        <div>
          <h4 className="mb-2 text-[10px] font-semibold uppercase tracking-wider text-muted-foreground/60">
            Multi-Browser
          </h4>
          <div className="space-y-2">
            <div className="flex items-center justify-between">
              <span className="text-xs text-muted-foreground">Count</span>
              <select className="rounded bg-input px-2 py-0.5 text-xs text-foreground border border-border">
                <option>2</option><option>4</option><option>6</option><option>8</option>
              </select>
            </div>
            <Button size="sm" variant="outline" className="w-full text-xs h-7">
              <LogIn className="h-3 w-3 mr-1" /> Login
            </Button>
            <Button size="sm" variant="ghost-muted" className="w-full text-xs h-7">
              <Wifi className="h-3 w-3 mr-1" /> Connect Opened
            </Button>
            <div className="flex items-center gap-1.5 rounded-md bg-success/10 px-2 py-1">
              <div className="h-2 w-2 rounded-full bg-success animate-pulse" />
              <span className="text-[11px] text-success font-medium">Connected 2/2</span>
            </div>
          </div>
        </div>
      </div>
    </aside>
  );
}
