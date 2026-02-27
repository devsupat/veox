import { useEffect, useState } from "react";
import { motion, AnimatePresence } from "framer-motion";
import { Play } from "lucide-react";

interface SplashScreenProps {
  onComplete: () => void;
}

export default function SplashScreen({ onComplete }: SplashScreenProps) {
  const [progress, setProgress] = useState(0);
  const [statusText, setStatusText] = useState("Initializing Engine...");

  useEffect(() => {
    const steps = [
      { at: 20, text: "Loading modules..." },
      { at: 50, text: "Connecting AI models..." },
      { at: 75, text: "Preparing workspace..." },
      { at: 95, text: "Almost ready..." },
    ];
    const interval = setInterval(() => {
      setProgress((p) => {
        const next = Math.min(p + Math.random() * 8 + 2, 100);
        const step = steps.find((s) => p < s.at && next >= s.at);
        if (step) setStatusText(step.text);
        if (next >= 100) {
          clearInterval(interval);
          setTimeout(onComplete, 600);
        }
        return next;
      });
    }, 80);
    return () => clearInterval(interval);
  }, [onComplete]);

  return (
    <AnimatePresence>
      <motion.div
        className="fixed inset-0 z-50 flex flex-col items-center justify-center bg-background"
        exit={{ opacity: 0 }}
        transition={{ duration: 0.6 }}
      >
        {/* Logo */}
        <motion.div
          initial={{ scale: 0.5, opacity: 0 }}
          animate={{ scale: 1, opacity: 1 }}
          transition={{ duration: 0.8, ease: "easeOut" }}
          className="mb-8"
        >
          <div className="relative flex h-24 w-24 items-center justify-center rounded-2xl gradient-primary glow-primary animate-pulse-glow">
            <Play className="h-12 w-12 text-primary-foreground ml-1" fill="currentColor" />
          </div>
        </motion.div>

        <motion.h1
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.3, duration: 0.6 }}
          className="mb-2 font-display text-4xl font-bold tracking-tight text-foreground"
        >
          VEOX Studio
        </motion.h1>

        <motion.p
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ delay: 0.6, duration: 0.6 }}
          className="mb-1 text-lg text-muted-foreground"
        >
          Unlimited AI Video Automation
        </motion.p>
        <motion.p
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ delay: 0.8, duration: 0.5 }}
          className="mb-10 text-sm text-muted-foreground/60"
        >
          No Limits
        </motion.p>

        {/* Progress */}
        <motion.div
          initial={{ opacity: 0, width: 0 }}
          animate={{ opacity: 1, width: 320 }}
          transition={{ delay: 0.5, duration: 0.5 }}
          className="mb-4"
        >
          <div className="h-1.5 w-80 overflow-hidden rounded-full bg-muted">
            <div
              className="h-full rounded-full gradient-primary transition-all duration-200 ease-out"
              style={{ width: `${progress}%` }}
            />
          </div>
        </motion.div>

        <motion.p
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ delay: 0.7 }}
          className="text-xs text-muted-foreground/60"
        >
          {statusText} {Math.round(progress)}%
        </motion.p>
      </motion.div>
    </AnimatePresence>
  );
}
