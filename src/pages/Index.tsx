import { useState, useCallback } from "react";
import { motion } from "framer-motion";
import { toast } from "sonner";
import SplashScreen from "@/components/veox/SplashScreen";
import TopNav from "@/components/veox/TopNav";
import LeftSidebar from "@/components/veox/LeftSidebar";
import StatusPanel from "@/components/veox/StatusPanel";
import HomeTab from "@/components/veox/HomeTab";
import AIVoiceTab from "@/components/veox/AIVoiceTab";
import ReelsTab from "@/components/veox/ReelsTab";
import SettingsTab from "@/components/veox/SettingsTab";
import ProjectDashboard from "@/components/veox/ProjectDashboard";
import TerminalDrawer from "@/components/veox/TerminalDrawer";
import CreateProjectModal from "@/components/veox/modals/CreateProjectModal";
import LoadProjectModal from "@/components/veox/modals/LoadProjectModal";
import PastePromptsModal from "@/components/veox/modals/PastePromptsModal";
import type { TabId } from "@/data/types";
import { useLocalStorage } from "@/hooks/useLocalStorage";
import { useAppState } from "@/hooks/useAppState";
import { Wrench } from "lucide-react";

function ComingSoon({ label }: { label: string }) {
  return (
    <div className="flex flex-1 flex-col items-center justify-center text-muted-foreground gap-3 animate-fade-in">
      <Wrench className="h-10 w-10 text-muted-foreground/30" />
      <h2 className="text-lg font-display font-semibold">{label}</h2>
      <p className="text-xs text-muted-foreground/60">Coming soon in the next update</p>
    </div>
  );
}

export default function Index() {
  const [showSplash, setShowSplash] = useState(true);
  const [activeTab, setActiveTab] = useLocalStorage<TabId>("veox-tab", "home");
  const [sidebarCollapsed, setSidebarCollapsed] = useState(false);
  const [statusCollapsed, setStatusCollapsed] = useState(false);

  // Modals
  const [showCreateModal, setShowCreateModal] = useState(false);
  const [showLoadModal, setShowLoadModal] = useState(false);
  const [showPasteModal, setShowPasteModal] = useState(false);

  const app = useAppState();

  const handleSplashComplete = useCallback(() => setShowSplash(false), []);

  const handleSidebarAction = useCallback((action: string) => {
    switch (action) {
      case "create":
        setShowCreateModal(true);
        break;
      case "load":
        setShowLoadModal(true);
        break;
      case "paste":
        setShowPasteModal(true);
        break;
      case "save":
        app.saveProject();
        toast.success("Project saved!");
        break;
      case "output":
        toast.info("Output folder: /output (stub)");
        app.addLog("INFO", "Opened output folder (stub)");
        break;
    }
  }, [app]);

  const handleCreateProject = useCallback((name: string) => {
    app.createProject(name);
    setActiveTab("home");
  }, [app, setActiveTab]);

  const handleLoadProject = useCallback((id: string) => {
    app.loadProject(id);
    setActiveTab("home");
  }, [app, setActiveTab]);

  const handleOpenProjectFromDashboard = useCallback((id: string) => {
    app.loadProject(id);
    setActiveTab("home");
  }, [app, setActiveTab]);

  if (showSplash) {
    return <SplashScreen onComplete={handleSplashComplete} />;
  }

  const tabLabels: Record<string, string> = {
    character: "Character Studio",
    "scene-builder": "Scene Builder",
    "clone-youtube": "Clone YouTube",
    mastering: "Mastering",
    "av-match": "AV Match",
    export: "Export",
    "more-tools": "More Tools",
  };

  const renderContent = () => {
    switch (activeTab) {
      case "home":
        return (
          <HomeTab
            scenes={app.scenes}
            processingStatus={app.processingStatus}
            onAddScene={app.addScene}
            onDeleteScene={app.deleteScene}
            onUpdateScenePrompt={app.updateScenePrompt}
            onRetryScene={app.retryScene}
            onRetryAllFailed={app.retryAllFailed}
            onStart={app.startProcessing}
            onPause={app.pauseProcessing}
            onStop={app.stopProcessing}
            onResume={app.resumeProcessing}
          />
        );
      case "ai-voice":
        return <AIVoiceTab />;
      case "reels":
        return <ReelsTab />;
      case "settings":
        return <SettingsTab />;
      case "projects":
        return (
          <ProjectDashboard
            projects={app.state.projects}
            scenesByProjectId={app.state.scenesByProjectId}
            onOpenProject={handleOpenProjectFromDashboard}
            onNewProject={() => setShowCreateModal(true)}
            onDeleteProject={app.deleteProject}
          />
        );
      default:
        return <ComingSoon label={tabLabels[activeTab] || activeTab} />;
    }
  };

  return (
    <motion.div
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      transition={{ duration: 0.5 }}
      className="flex h-screen flex-col bg-background overflow-hidden"
    >
      <TopNav activeTab={activeTab} onTabChange={setActiveTab} />

      <div className="flex flex-1 overflow-hidden">
        <LeftSidebar
          collapsed={sidebarCollapsed}
          onToggle={() => setSidebarCollapsed(!sidebarCollapsed)}
          onAction={handleSidebarAction}
        />

        <main className="flex-1 overflow-y-auto p-4 scrollbar-thin">
          {renderContent()}
        </main>

        <StatusPanel
          collapsed={statusCollapsed}
          onToggle={() => setStatusCollapsed(!statusCollapsed)}
          stats={app.stats}
        />
      </div>

      <TerminalDrawer logs={app.logs} />

      {/* Modals */}
      <CreateProjectModal open={showCreateModal} onClose={() => setShowCreateModal(false)} onCreate={handleCreateProject} />
      <LoadProjectModal open={showLoadModal} onClose={() => setShowLoadModal(false)} projects={app.state.projects} onLoad={handleLoadProject} />
      <PastePromptsModal open={showPasteModal} onClose={() => setShowPasteModal(false)} onPaste={app.pastePrompts} />
    </motion.div>
  );
}
