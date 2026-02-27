import { useState } from "react";
import { Key, Globe, User, Eye, EyeOff } from "lucide-react";
import { cn } from "@/lib/utils";
import { useLocalStorage } from "@/hooks/useLocalStorage";

const settingsSections = [
  { id: "gemini", label: "Gemini API", icon: Key },
  { id: "browser", label: "Browser Profiles", icon: Globe },
  { id: "google", label: "Google Accounts", icon: User },
];

export default function SettingsTab() {
  const [active, setActive] = useState("gemini");
  const [showKeys, setShowKeys] = useState(false);
  const [apiKeys, setApiKeys] = useLocalStorage("veox-api-keys", "AIzaSy_example_key_1\nAIzaSy_example_key_2\nAIzaSy_example_key_3");

  return (
    <div className="flex gap-4 h-full animate-fade-in">
      {/* Settings Sidebar */}
      <div className="w-48 rounded-lg border border-border bg-card p-2 space-y-1 shrink-0">
        <h3 className="text-sm font-semibold text-foreground font-display px-2 py-2">Settings</h3>
        {settingsSections.map(({ id, label, icon: Icon }) => (
          <button
            key={id}
            onClick={() => setActive(id)}
            className={cn(
              "flex w-full items-center gap-2 rounded-md px-3 py-2 text-xs transition-colors",
              active === id
                ? "gradient-primary text-primary-foreground"
                : "text-muted-foreground hover:text-foreground hover:bg-muted"
            )}
          >
            <Icon className="h-3.5 w-3.5" />
            {label}
          </button>
        ))}
      </div>

      {/* Main Panel */}
      <div className="flex-1 rounded-lg border border-border bg-card p-4">
        {active === "gemini" && (
          <div className="space-y-4">
            <h3 className="text-sm font-semibold text-foreground font-display">Gemini API Configuration</h3>
            <p className="text-xs text-muted-foreground">Enter your API keys below, one per line.</p>
            <textarea
              value={showKeys ? apiKeys : apiKeys.replace(/./g, "•")}
              onChange={(e) => setApiKeys(e.target.value)}
              rows={6}
              className="w-full rounded-md border border-border bg-input p-3 font-mono text-xs text-foreground placeholder:text-muted-foreground/40 resize-none focus:outline-none focus:ring-1 focus:ring-primary"
            />
            <button
              onClick={() => setShowKeys(!showKeys)}
              className="flex items-center gap-1.5 text-xs text-muted-foreground hover:text-foreground transition-colors"
            >
              {showKeys ? <EyeOff className="h-3.5 w-3.5" /> : <Eye className="h-3.5 w-3.5" />}
              {showKeys ? "Hide Keys" : "Show Keys"}
            </button>
          </div>
        )}

        {active === "browser" && (
          <div className="space-y-3">
            <h3 className="text-sm font-semibold text-foreground font-display">Browser Profiles</h3>
            <p className="text-xs text-muted-foreground">Manage your browser profiles for multi-browser automation.</p>
            <div className="space-y-2">
              {["Profile 1 – Chrome", "Profile 2 – Chrome", "Profile 3 – Firefox"].map((p, i) => (
                <div key={i} className="flex items-center gap-3 rounded-md bg-muted/50 px-3 py-2">
                  <Globe className="h-3.5 w-3.5 text-accent" />
                  <span className="text-xs text-foreground">{p}</span>
                  <span className="ml-auto text-[10px] text-success">Active</span>
                </div>
              ))}
            </div>
          </div>
        )}

        {active === "google" && (
          <div className="space-y-3">
            <h3 className="text-sm font-semibold text-foreground font-display">Google Accounts</h3>
            <p className="text-xs text-muted-foreground">Connected Google accounts for AI services.</p>
            <div className="space-y-2">
              {["user@gmail.com", "studio@gmail.com"].map((email, i) => (
                <div key={i} className="flex items-center gap-3 rounded-md bg-muted/50 px-3 py-2">
                  <User className="h-3.5 w-3.5 text-accent" />
                  <span className="text-xs text-foreground">{email}</span>
                  <span className="ml-auto text-[10px] text-success">Connected</span>
                </div>
              ))}
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
