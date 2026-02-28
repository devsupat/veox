import { useState, useCallback, useEffect } from "react";
import {
  Plus, Film, Check, Mic, Video, Sparkles,
  Clapperboard, MoreHorizontal, Image as ImageIcon,
  Trash2, Eye, RotateCcw
} from "lucide-react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";
import { Switch } from "@/components/ui/switch";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { cn } from "@/lib/utils";
import { toast } from "sonner";
import type { ReelProject, ReelTemplate, ReelsState } from "@/data/types";
import { useLocalStorage } from "@/hooks/useLocalStorage";

// Default templates seed
const defaultTemplates: ReelTemplate[] = [
  { id: "t1", name: "Boy Saves Animal", color: 263, image: "bg-gradient-to-br from-purple-500 to-indigo-600", createdAt: new Date().toISOString() },
  { id: "t2", name: "Angry Food", color: 142, image: "bg-gradient-to-br from-green-500 to-emerald-700", createdAt: new Date().toISOString() },
  { id: "t3", name: "Courtroom Drama", color: 38, image: "bg-gradient-to-br from-orange-400 to-red-500", createdAt: new Date().toISOString() },
  { id: "t4", name: "Space Adventure", color: 200, image: "bg-gradient-to-br from-blue-400 to-cyan-600", createdAt: new Date().toISOString() },
];

function generateId(): string {
  return Date.now().toString(36) + Math.random().toString(36).slice(2, 7);
}

export default function ReelsTab() {
  // Persistence
  const [templates, setTemplates] = useLocalStorage<ReelTemplate[]>("veox.reels.templates", defaultTemplates);
  const [projects, setProjects] = useLocalStorage<ReelProject[]>("veox.reels.projects", []);

  // UI State
  const [selectedTemplateId, setSelectedTemplateId] = useState<string>(templates[0]?.id || "");
  const [topic, setTopic] = useState("");
  const [character, setCharacter] = useState("Boy");
  const [mode, setMode] = useState<"single" | "perLine">("single");
  const [counts, setCounts] = useState({ reels: 1, stories: 1, scenes: 12 });
  const [videoVoice, setVideoVoice] = useState(true);
  const [voiceLang, setVoiceLang] = useState("English");
  const [dubbing, setDubbing] = useState(false);
  const [isGenerating, setIsGenerating] = useState(false);

  // Right panel view state
  const [activeProjectId, setActiveProjectId] = useState<string | null>(null);

  // New Template Modal
  const [showNewTemplateModal, setShowNewTemplateModal] = useState(false);
  const [newTemplateName, setNewTemplateName] = useState("");
  const [newTemplateColor, setNewTemplateColor] = useState(263);

  const activeProject = projects.find(p => p.id === activeProjectId) || null;

  // Auto-select first template if none selected and templates exist
  useEffect(() => {
    if (!selectedTemplateId && templates.length > 0) {
      setSelectedTemplateId(templates[0].id);
    }
  }, [templates, selectedTemplateId]);

  const handleGenerate = () => {
    if (!selectedTemplateId) {
      toast.error("Please select a template first");
      return;
    }

    if (mode === "single" && !topic.trim()) {
      toast.error("Please enter a topic");
      return;
    }

    if (mode === "perLine" && !topic.trim()) {
      toast.error("Please enter at least one topic (one per line)");
      return;
    }

    setIsGenerating(true);

    // Fake loading
    setTimeout(() => {
      const template = templates.find(t => t.id === selectedTemplateId);
      const templateName = template?.name || "Unknown Template";
      const commonProps = {
        templateId: selectedTemplateId,
        templateName,
        character,
        reelsCount: counts.reels,
        storiesPerHint: counts.stories,
        scenesCount: counts.scenes,
        videoVoiceEnabled: videoVoice,
        voiceLanguage: voiceLang,
        externalDubbingEnabled: dubbing,
        status: "generated" as const,
        generatedAt: new Date().toISOString(),
      };

      let newProjects: ReelProject[] = [];

      if (mode === "single") {
        newProjects.push({
          id: generateId(),
          createdAt: new Date().toISOString(),
          topic: topic.trim(),
          topicMode: "single",
          ...commonProps
        });
      } else {
        const lines = topic.split("\n").map(l => l.trim()).filter(Boolean);
        newProjects = lines.map(line => ({
          id: generateId(),
          createdAt: new Date().toISOString(),
          topic: line,
          topicMode: "perLine",
          ...commonProps
        }));
      }

      setProjects(prev => [...newProjects, ...prev]);
      setActiveProjectId(newProjects[0].id);
      setIsGenerating(false);
      toast.success(`Created ${newProjects.length} reel project(s)!`);
    }, 300);
  };

  const handleCreateTemplate = () => {
    if (!newTemplateName.trim()) return;
    const newT: ReelTemplate = {
      id: generateId(),
      name: newTemplateName,
      color: newTemplateColor,
      image: `bg-gradient-to-br from-[hsl(${newTemplateColor},70%,60%)] to-[hsl(${newTemplateColor + 40},70%,40%)]`,
      createdAt: new Date().toISOString()
    };
    setTemplates(prev => [...prev, newT]);
    setSelectedTemplateId(newT.id);
    setNewTemplateName("");
    setShowNewTemplateModal(false);
    toast.success("Template created");
  };

  const handleDeleteProject = (e: React.MouseEvent, id: string) => {
    e.stopPropagation();
    setProjects(prev => prev.filter(p => p.id !== id));
    if (activeProjectId === id) setActiveProjectId(null);
    toast.info("Project deleted");
  };

  const handleClearForm = () => {
    setTopic("");
    setCharacter("Boy");
    setMode("single");
    setCounts({ reels: 1, stories: 1, scenes: 12 });
    setVideoVoice(true);
    setDubbing(false);
    toast.info("Form reset");
  };

  return (
    <div className="flex h-full w-full overflow-hidden animate-fade-in bg-background">
      {/* Left Panel */}
      <aside className="w-[420px] flex-shrink-0 flex flex-col border-r border-border bg-sidebar/30 h-full overflow-y-auto scrollbar-thin">
        <div className="p-5 space-y-6">

          {/* Templates Section */}
          <div className="space-y-3">
            <div className="flex items-center justify-between">
              <label className="text-xs font-semibold text-muted-foreground uppercase tracking-wider">Reel/Shorts Templates</label>
            </div>

            <div className="flex gap-3 overflow-x-auto pb-4 -mx-1 px-1 scrollbar-thin">
              {templates.map((t) => {
                const isSelected = selectedTemplateId === t.id;
                return (
                  <div
                    key={t.id}
                    onClick={() => setSelectedTemplateId(t.id)}
                    className={cn(
                      "group relative flex-shrink-0 w-28 h-40 rounded-2xl cursor-pointer overflow-hidden transition-all duration-300 border-2",
                      isSelected
                        ? "border-primary shadow-[0_0_15px_-3px_hsl(var(--primary)/0.5)] scale-[1.02]"
                        : "border-transparent hover:border-primary/50"
                    )}
                  >
                    <div className={cn("absolute inset-0 transition-transform duration-500 group-hover:scale-110", t.image)} />
                    <div className="absolute inset-0 bg-gradient-to-t from-black/80 via-transparent to-transparent" />
                    {isSelected && (
                      <div className="absolute inset-0 bg-black/20 flex items-center justify-center animate-fade-in">
                        <div className="h-8 w-8 rounded-full bg-primary text-primary-foreground flex items-center justify-center shadow-lg">
                          <Check className="h-5 w-5" strokeWidth={3} />
                        </div>
                      </div>
                    )}
                    <span className="absolute bottom-3 left-3 right-3 text-[11px] font-bold text-white leading-tight">
                      {t.name}
                    </span>
                  </div>
                );
              })}

              <button
                onClick={() => setShowNewTemplateModal(true)}
                className="flex-shrink-0 w-28 h-40 rounded-2xl border-2 border-dashed border-border flex flex-col items-center justify-center gap-2 text-muted-foreground hover:text-primary hover:border-primary/50 hover:bg-primary/5 transition-all"
              >
                <div className="h-10 w-10 rounded-full bg-muted flex items-center justify-center group-hover:bg-primary/20">
                  <Plus className="h-6 w-6" />
                </div>
                <span className="text-xs font-medium">New</span>
              </button>
            </div>
            {!selectedTemplateId && <p className="text-[10px] text-destructive font-medium">Please select a template above</p>}
          </div>

          {/* Form Section */}
          <div className="space-y-5 bg-card/50 rounded-xl p-4 border border-border/50 shadow-sm">
            <div className="space-y-2">
              <Textarea
                value={topic}
                onChange={(e) => setTopic(e.target.value)}
                placeholder={mode === 'single' ? "Enter topic (e.g., A boy saves a dolphin...)" : "Enter topics (one per line)..."}
                className="min-h-[100px] resize-none text-sm bg-input/50 border-border/60 focus:bg-input transition-colors"
              />
              {!topic && <p className="text-[10px] text-muted-foreground italic">Topic is required</p>}
            </div>

            <div className="space-y-1.5">
              <div className="flex items-center gap-2">
                <span className="text-xs font-medium text-muted-foreground w-20">Character:</span>
                <Select value={character} onValueChange={setCharacter}>
                  <SelectTrigger className="h-8 text-xs bg-input/50 border-border/60">
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="Boy">Boy</SelectItem>
                    <SelectItem value="Girl">Girl</SelectItem>
                    <SelectItem value="Robot">Robot</SelectItem>
                    <SelectItem value="Cat">Cat</SelectItem>
                  </SelectContent>
                </Select>
              </div>
            </div>

            <div className="space-y-1.5">
              <div className="flex items-center gap-2">
                <span className="text-xs font-medium text-muted-foreground w-20">Topic Mode:</span>
                <div className="flex-1 flex bg-muted/50 rounded-lg p-0.5 border border-border/50">
                  <button
                    onClick={() => setMode("single")}
                    className={cn(
                      "flex-1 flex items-center justify-center gap-1.5 py-1 text-[10px] font-medium rounded-md transition-all",
                      mode === "single" ? "bg-background text-foreground shadow-sm" : "text-muted-foreground hover:text-foreground"
                    )}
                  >
                    <Check className={cn("h-3 w-3", mode === "single" ? "opacity-100" : "opacity-0")} />
                    Single Topic
                  </button>
                  <button
                    onClick={() => setMode("perLine")}
                    className={cn(
                      "flex-1 flex items-center justify-center gap-1.5 py-1 text-[10px] font-medium rounded-md transition-all",
                      mode === "perLine" ? "bg-background text-foreground shadow-sm" : "text-muted-foreground hover:text-foreground"
                    )}
                  >
                    <Check className={cn("h-3 w-3", mode === "perLine" ? "opacity-100" : "opacity-0")} />
                    One per Line
                  </button>
                </div>
              </div>
            </div>

            <div className="flex items-center gap-3 py-1">
              <div className="flex items-center gap-2 flex-1">
                <span className="text-xs font-bold text-foreground">Reels:</span>
                <Input
                  type="number"
                  value={counts.reels}
                  onChange={(e) => setCounts({ ...counts, reels: +e.target.value })}
                  className="h-7 w-12 px-1 text-center text-xs bg-input/50"
                />
              </div>
              <div className="flex items-center gap-2 flex-1">
                <span className="text-[10px] font-medium text-muted-foreground whitespace-nowrap">Stories/Hint:</span>
                <Select defaultValue="1">
                  <SelectTrigger className="h-7 w-12 px-1 text-xs bg-input/50">
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="1">1</SelectItem>
                    <SelectItem value="2">2</SelectItem>
                  </SelectContent>
                </Select>
              </div>
              <div className="flex items-center gap-2 flex-1 justify-end">
                <span className="text-[10px] font-medium text-muted-foreground">Scenes:</span>
                <span className="text-xs font-bold">{counts.scenes}</span>
                <MoreHorizontal className="h-3 w-3 text-muted-foreground" />
              </div>
            </div>

            <div className="space-y-3 pt-2 border-t border-border/50">
              <div className="flex items-center justify-between p-2 rounded-lg bg-muted/30 border border-border/30">
                <div className="flex items-center gap-2 flex-1">
                  <Video className="h-4 w-4 text-blue-500" />
                  <span className="text-xs font-medium">Video Voice <span className="text-muted-foreground text-[10px]">(Veo3)</span></span>
                  <Select value={voiceLang} onValueChange={setVoiceLang} disabled={!videoVoice}>
                    <SelectTrigger className="h-6 w-24 text-[10px] border-0 bg-transparent focus:ring-0 px-2 ml-2">
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="English">English</SelectItem>
                      <SelectItem value="Indonesian">Indonesian</SelectItem>
                      <SelectItem value="Spanish">Spanish</SelectItem>
                      <SelectItem value="French">French</SelectItem>
                    </SelectContent>
                  </Select>
                </div>
                <Switch checked={videoVoice} onCheckedChange={setVideoVoice} className="scale-75 origin-right" />
              </div>

              <div className="flex items-center justify-between p-2 rounded-lg bg-muted/30 border border-border/30">
                <div className="flex items-center gap-2">
                  <Mic className="h-4 w-4 text-purple-500" />
                  <span className="text-xs font-medium">External Dubbing</span>
                </div>
                <Switch checked={dubbing} onCheckedChange={setDubbing} className="scale-75 origin-right" />
              </div>
            </div>

            <div className="flex items-center gap-2">
              <Button
                onClick={handleGenerate}
                disabled={isGenerating || !topic || !selectedTemplateId}
                className="flex-1 h-11 text-sm font-semibold shadow-lg shadow-primary/20 gradient-primary"
              >
                {isGenerating ? (
                  <>
                    <Sparkles className="h-4 w-4 mr-2 animate-spin" /> Generating...
                  </>
                ) : (
                  <>
                    <Clapperboard className="h-4 w-4 mr-2" /> Generate Content
                  </>
                )}
              </Button>
              <Button variant="ghost" size="icon" className="h-11 w-11 shrink-0" onClick={handleClearForm} title="Clear Form">
                <RotateCcw className="h-4 w-4 text-muted-foreground" />
              </Button>
            </div>
          </div>
        </div>
      </aside>

      {/* Right Panel (Main Content) */}
      <main className="flex-1 flex flex-col relative bg-background/50 overflow-hidden">
        {projects.length === 0 ? (
          <>
            <div className="absolute top-4 right-4 text-xs text-muted-foreground">
              Add a reel project to get started
            </div>
            <div className="flex-1 flex items-center justify-center p-10">
              <div className="text-center space-y-4 opacity-50 max-w-sm">
                <div className="h-32 w-full bg-muted/20 rounded-2xl border-2 border-dashed border-border flex items-center justify-center mx-auto">
                  <ImageIcon className="h-10 w-10 text-muted-foreground/50" />
                </div>
                <p className="text-sm text-muted-foreground font-medium">
                  Select a template and enter a topic to generate your first Reel
                </p>
              </div>
            </div>
          </>
        ) : activeProject ? (
          // Active Project Details View
          <div className="flex-1 p-8 overflow-y-auto scrollbar-thin animate-fade-in">
            <div className="max-w-4xl mx-auto space-y-6">
              <div className="flex items-center justify-between">
                <h2 className="text-2xl font-display font-bold">Project Details</h2>
                <Button variant="ghost" size="sm" onClick={() => setActiveProjectId(null)}>Back to List</Button>
              </div>

              <div className="bg-card rounded-xl border border-border shadow-xl overflow-hidden">
                <div className="h-2 bg-gradient-to-r from-primary to-purple-500" />
                <div className="p-6 space-y-6">
                  <div>
                    <h3 className="text-xl font-bold font-display mb-1">{activeProject.topic}</h3>
                    <div className="flex items-center gap-3 text-xs text-muted-foreground">
                      <span className="flex items-center gap-1"><Film className="h-3 w-3" /> {activeProject.templateName}</span>
                      <span className="w-1 h-1 rounded-full bg-border" />
                      <span>{activeProject.character}</span>
                      <span className="w-1 h-1 rounded-full bg-border" />
                      <span>{new Date(activeProject.createdAt).toLocaleString()}</span>
                    </div>
                  </div>

                  <div className="grid grid-cols-3 gap-4">
                    <div className="p-4 rounded-lg bg-muted/30 border border-border/50 text-center">
                      <div className="text-3xl font-bold text-primary">{activeProject.reelsCount}</div>
                      <div className="text-[10px] text-muted-foreground uppercase tracking-wider font-semibold">Reels</div>
                    </div>
                    <div className="p-4 rounded-lg bg-muted/30 border border-border/50 text-center">
                      <div className="text-3xl font-bold text-primary">{activeProject.storiesPerHint}</div>
                      <div className="text-[10px] text-muted-foreground uppercase tracking-wider font-semibold">Stories</div>
                    </div>
                    <div className="p-4 rounded-lg bg-muted/30 border border-border/50 text-center">
                      <div className="text-3xl font-bold text-primary">{activeProject.scenesCount}</div>
                      <div className="text-[10px] text-muted-foreground uppercase tracking-wider font-semibold">Scenes</div>
                    </div>
                  </div>

                  <div className="flex gap-4 p-4 rounded-lg bg-muted/30 border border-border/50">
                    <div className="flex items-center gap-2 text-sm">
                      <Video className="h-4 w-4 text-blue-500" />
                      <span className="text-muted-foreground">Voice:</span>
                      <span className="font-medium">{activeProject.videoVoiceEnabled ? `On (${activeProject.voiceLanguage})` : "Off"}</span>
                    </div>
                    <div className="w-px bg-border/50" />
                    <div className="flex items-center gap-2 text-sm">
                      <Mic className="h-4 w-4 text-purple-500" />
                      <span className="text-muted-foreground">Dubbing:</span>
                      <span className="font-medium">{activeProject.externalDubbingEnabled ? "On" : "Off"}</span>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        ) : (
          // Project List View
          <div className="flex-1 p-8 overflow-y-auto scrollbar-thin">
            <h2 className="text-lg font-semibold mb-4">Reel Projects ({projects.length})</h2>
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
              {projects.map((p) => (
                <div key={p.id} className="group bg-card border border-border rounded-xl p-4 hover:border-primary/50 transition-all shadow-sm">
                  <div className="flex justify-between items-start mb-2">
                    <span className="text-[10px] font-bold uppercase tracking-wider text-primary bg-primary/10 px-2 py-0.5 rounded-full">
                      {p.templateName}
                    </span>
                    <div className="flex gap-1 opacity-0 group-hover:opacity-100 transition-opacity">
                      <Button variant="ghost" size="icon" className="h-6 w-6" onClick={() => setActiveProjectId(p.id)} title="View">
                        <Eye className="h-3.5 w-3.5" />
                      </Button>
                      <Button variant="ghost" size="icon" className="h-6 w-6 text-destructive hover:text-destructive" onClick={(e) => handleDeleteProject(e, p.id)} title="Delete">
                        <Trash2 className="h-3.5 w-3.5" />
                      </Button>
                    </div>
                  </div>
                  <h3 className="font-bold text-sm line-clamp-2 mb-2 h-10">{p.topic}</h3>
                  <div className="flex items-center justify-between text-[11px] text-muted-foreground">
                    <span>{new Date(p.createdAt).toLocaleDateString()}</span>
                    <span>{p.character} • {p.scenesCount} scenes</span>
                  </div>
                </div>
              ))}
            </div>
          </div>
        )}
      </main>

      {/* New Template Modal */}
      <Dialog open={showNewTemplateModal} onOpenChange={setShowNewTemplateModal}>
        <DialogContent className="max-w-sm">
          <DialogHeader>
            <DialogTitle>New Template</DialogTitle>
          </DialogHeader>
          <div className="space-y-4 py-2">
            <div className="space-y-2">
              <label className="text-xs font-medium">Template Name</label>
              <Input value={newTemplateName} onChange={(e) => setNewTemplateName(e.target.value)} placeholder="e.g. History Facts" />
            </div>
            <div className="space-y-2">
              <label className="text-xs font-medium">Accent Color</label>
              <div className="flex gap-2">
                {[263, 142, 38, 200, 340, 20].map((c) => (
                  <button
                    key={c}
                    onClick={() => setNewTemplateColor(c)}
                    className={cn(
                      "h-6 w-6 rounded-full transition-transform hover:scale-110 ring-2 ring-offset-2 ring-offset-background",
                      newTemplateColor === c ? "ring-primary scale-110" : "ring-transparent"
                    )}
                    style={{ background: `hsl(${c}, 70%, 50%)` }}
                  />
                ))}
              </div>
            </div>
            <Button onClick={handleCreateTemplate} className="w-full" disabled={!newTemplateName.trim()}>Create Template</Button>
          </div>
        </DialogContent>
      </Dialog>
    </div>
  );
}
