"use client";

import { MotionConfig } from "motion/react";
import { useEffect, type ReactNode } from "react";
import { SvgDefs } from "@/components/illustrations/Illustration";
import { ToastProvider } from "@/components/ui/Toast";
import { AppStateProvider, useAppState } from "@/lib/store/provider";
import { CollectibleReveal } from "./CollectibleReveal";
import { Splash } from "./Splash";

/** Mirrors appearance settings onto <html> so CSS tokens can react to them. */
function SettingsEffects() {
  const { settings } = useAppState();
  useEffect(() => {
    const el = document.documentElement;
    el.dataset.theme = settings.theme;
    el.dataset.accent = settings.accent;
    el.dataset.density = settings.density;
    el.dataset.motion = settings.motion;
    el.dataset.text = settings.largeText ? "large" : "normal";
    el.dataset.contrast = settings.highContrast ? "high" : "normal";
    document.querySelector('meta[name="theme-color"]')?.setAttribute("content", settings.theme === "dark" ? "#1d1514" : "#f3e8d2");
  }, [settings.theme, settings.accent, settings.density, settings.motion, settings.largeText, settings.highContrast]);
  return null;
}

function Motion({ children }: { children: ReactNode }) {
  const { settings } = useAppState();
  const reducedMotion = settings.motion === "reduced" ? "always" : settings.motion === "full" ? "never" : "user";
  return <MotionConfig reducedMotion={reducedMotion}>{children}</MotionConfig>;
}

export function Providers({ children }: { children: ReactNode }) {
  return (
    <>
      <SvgDefs />
      <AppStateProvider fallback={<Splash />}>
        <SettingsEffects />
        <Motion>
          <ToastProvider>
            {children}
            <CollectibleReveal />
          </ToastProvider>
        </Motion>
      </AppStateProvider>
    </>
  );
}
