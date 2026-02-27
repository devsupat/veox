import {
  Home, Users, Layers, Video, Sliders, Film, AudioLines,
  Settings, Download, Mic, MoreHorizontal, RefreshCw, Crown
} from "lucide-react";
import type { TabId } from "@/data/types";
import { cn } from "@/lib/utils";

const tabs: { id: TabId; label: string; icon: React.ElementType }[] = [
  { id: "home", label: "HOME", icon: Home },
  { id: "character", label: "Character Studio", icon: Users },
  { id: "scene-builder", label: "Scene Builder", icon: Layers },
  { id: "clone-youtube", label: "Clone YouTube", icon: Video },
  { id: "mastering", label: "Mastering", icon: Sliders },
  { id: "reels", label: "Reels", icon: Film },
  { id: "av-match", label: "AV Match", icon: AudioLines },
  { id: "settings", label: "Settings", icon: Settings },
  { id: "export", label: "Export", icon: Download },
  { id: "ai-voice", label: "AI Voice", icon: Mic },
  { id: "more-tools", label: "More", icon: MoreHorizontal },
];

interface TopNavProps {
  activeTab: TabId;
  onTabChange: (tab: TabId) => void;
}

export default function TopNav({ activeTab, onTabChange }: TopNavProps) {
  return (
    <header className="flex h-12 items-center border-b border-primary/20 bg-primary px-2 shrink-0 shadow-sm text-primary-foreground">
      {/* Logo */}
      <button
        onClick={() => onTabChange("projects")}
        className="mr-3 flex items-center gap-1.5 px-2 text-sm font-display font-bold tracking-tight text-primary-foreground hover:opacity-80"
      >
        <div className="h-6 w-6 rounded bg-primary-foreground flex items-center justify-center text-primary">
          <span className="text-xs font-bold">V</span>
        </div>
        VEOX
      </button>

      {/* Tabs */}
      <nav className="flex items-center gap-1 overflow-x-auto scrollbar-thin flex-1">
        {tabs.map(({ id, label, icon: Icon }) => (
          <button
            key={id}
            onClick={() => onTabChange(id)}
            className={cn(
              "flex items-center gap-1.5 rounded-md px-3 py-1.5 text-xs font-medium transition-all whitespace-nowrap",
              activeTab === id
                ? "bg-primary-foreground text-primary shadow-sm font-semibold"
                : "text-primary-foreground/80 hover:text-primary-foreground hover:bg-primary-foreground/10"
            )}
          >
            <Icon className="h-3.5 w-3.5" />
            <span className="hidden lg:inline">{label}</span>
          </button>
        ))}
      </nav>

      {/* Right */}
      <div className="flex items-center gap-2 ml-2">
        <button className="flex items-center gap-1 rounded-md bg-primary-foreground/10 px-2.5 py-1 text-xs text-primary-foreground hover:bg-primary-foreground/20 transition-colors border border-primary-foreground/20">
          <RefreshCw className="h-3 w-3" />
          Update
        </button>
        <div className="flex items-center gap-1 rounded-full bg-white/20 px-2.5 py-0.5 text-[10px] font-semibold text-white border border-white/20">
          <Crown className="h-3 w-3 text-yellow-300" />
          PREMIUM
        </div>
        <div className="flex gap-1 ml-1">
          {["bg-green-400", "bg-yellow-400", "bg-red-400"].map((c, i) => (
            <div key={i} className={`h-2.5 w-2.5 rounded-full ${c} shadow-sm border border-black/10`} />
          ))}
        </div>
      </div>
    </header>
  );
}
