import {
  FilePlus, FileText, ClipboardPaste, Save, FolderOpen,
  ImagePlus, ImageDown, Zap, Info, PanelLeftClose, PanelLeft
} from "lucide-react";
import { cn } from "@/lib/utils";

interface SidebarItem {
  icon: React.ElementType;
  label: string;
  action?: string;
}

const fileOps: SidebarItem[] = [
  { icon: FilePlus, label: "Create New Project", action: "create" },
  { icon: FileText, label: "Load Prompts", action: "load" },
  { icon: ClipboardPaste, label: "Paste Prompts", action: "paste" },
  { icon: Save, label: "Save Project", action: "save" },
  { icon: FolderOpen, label: "Open Output", action: "output" },
];

const frameOps: SidebarItem[] = [
  { icon: ImagePlus, label: "Import First Frames" },
  { icon: ImageDown, label: "Import Last Frames" },
];

const actions: SidebarItem[] = [
  { icon: Zap, label: "Heavy Bulk Tasks" },
];

interface LeftSidebarProps {
  collapsed: boolean;
  onToggle: () => void;
  onAction: (action: string) => void;
}

function Section({ title, items, onAction }: { title: string; items: SidebarItem[]; onAction: (a: string) => void }) {
  return (
    <div className="mb-4">
      <h3 className="mb-1.5 px-3 text-[10px] font-semibold uppercase tracking-wider text-muted-foreground/60">
        {title}
      </h3>
      {items.map(({ icon: Icon, label, action }) => (
        <button
          key={label}
          onClick={() => action && onAction(action)}
          className="flex w-full items-center gap-2 rounded-md px-3 py-1.5 text-xs text-sidebar-foreground hover:bg-sidebar-accent transition-colors"
        >
          <Icon className="h-3.5 w-3.5 text-muted-foreground" />
          {label}
        </button>
      ))}
    </div>
  );
}

export default function LeftSidebar({ collapsed, onToggle, onAction }: LeftSidebarProps) {
  if (collapsed) {
    return (
      <aside className="flex w-10 flex-col items-center border-r border-border bg-sidebar py-2 shrink-0">
        <button onClick={onToggle} className="mb-4 p-1 text-muted-foreground hover:text-foreground">
          <PanelLeft className="h-4 w-4" />
        </button>
        {[...fileOps, ...frameOps, ...actions].map(({ icon: Icon, label, action }) => (
          <button key={label} onClick={() => action && onAction(action)}
            className="mb-1 rounded p-1.5 text-muted-foreground hover:bg-sidebar-accent hover:text-foreground" title={label}>
            <Icon className="h-3.5 w-3.5" />
          </button>
        ))}
      </aside>
    );
  }

  return (
    <aside className="flex w-48 flex-col border-r border-border bg-sidebar shrink-0">
      <div className="flex items-center justify-between border-b border-border px-3 py-2">
        <span className="text-xs font-semibold text-foreground">Navigator</span>
        <button onClick={onToggle} className="p-0.5 text-muted-foreground hover:text-foreground">
          <PanelLeftClose className="h-3.5 w-3.5" />
        </button>
      </div>
      <div className="flex-1 overflow-y-auto p-2 scrollbar-thin">
        <Section title="File Operations" items={fileOps} onAction={onAction} />
        <Section title="Frame Operations" items={frameOps} onAction={onAction} />
        <Section title="Actions" items={actions} onAction={onAction} />
      </div>
      <div className="border-t border-border px-3 py-2 flex items-center gap-1.5 text-muted-foreground/50">
        <Info className="h-3 w-3" />
        <span className="text-[10px]">v1.0.0 beta</span>
      </div>
    </aside>
  );
}
