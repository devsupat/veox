import { useState, useRef, useEffect } from "react";
import { ChevronUp, ChevronDown, Terminal, Trash2 } from "lucide-react";
import { cn } from "@/lib/utils";
import type { LogEntry } from "@/data/types";

const levelColors: Record<LogEntry["level"], string> = {
  INFO: "text-blue-400",
  SUCCESS: "text-green-400",
  WARN: "text-yellow-400",
  ERROR: "text-red-400",
};

interface TerminalDrawerProps {
  logs: LogEntry[];
}

export default function TerminalDrawer({ logs }: TerminalDrawerProps) {
  const [expanded, setExpanded] = useState(false);
  const bottomRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (expanded) {
      bottomRef.current?.scrollIntoView({ behavior: "smooth" });
    }
  }, [logs.length, expanded]);

  const formatTime = (iso: string) => {
    const d = new Date(iso);
    return d.toLocaleTimeString([], { hour: "2-digit", minute: "2-digit", second: "2-digit" });
  };

  return (
    <div
      className={cn(
        "border-t border-zinc-800 bg-zinc-950 text-zinc-100 shrink-0 flex flex-col transition-all duration-300",
        expanded ? "h-[30vh]" : "h-10"
      )}
    >
      {/* Header */}
      <button
        onClick={() => setExpanded(!expanded)}
        className="flex items-center gap-2 px-3 py-2 text-xs font-medium text-zinc-400 hover:text-zinc-100 shrink-0 transition-colors"
      >
        <Terminal className="h-3.5 w-3.5" />
        <span className="font-display">Terminal / Logs</span>
        <span className="ml-1 rounded-full bg-zinc-800 px-1.5 py-0.5 text-[10px] text-zinc-300">{logs.length}</span>
        <div className="flex-1" />
        {expanded ? <ChevronDown className="h-3.5 w-3.5" /> : <ChevronUp className="h-3.5 w-3.5" />}
      </button>

      {/* Log content */}
      {expanded && (
        <div className="flex-1 overflow-y-auto px-3 pb-2 font-mono text-[11px] scrollbar-thin scrollbar-thumb-zinc-700 scrollbar-track-transparent">
          {logs.length === 0 && (
            <p className="text-zinc-600 py-4 text-center">No logs yet.</p>
          )}
          {logs.map((log) => (
            <div key={log.id} className="flex gap-2 py-0.5 leading-relaxed border-b border-zinc-900/50 last:border-0">
              <span className="text-zinc-500 shrink-0 select-none">{formatTime(log.timestamp)}</span>
              <span className={cn("shrink-0 w-14 font-bold", levelColors[log.level])}>[{log.level}]</span>
              <span className="text-zinc-300 break-all">{log.message}</span>
            </div>
          ))}
          <div ref={bottomRef} />
        </div>
      )}
    </div>
  );
}
