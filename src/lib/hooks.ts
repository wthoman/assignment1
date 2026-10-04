"use client";

import { useSyncExternalStore } from "react";
import { todayISO } from "./dates";

function mediaStore(query: string) {
  return {
    subscribe(cb: () => void) {
      const m = window.matchMedia(query);
      m.addEventListener("change", cb);
      return () => m.removeEventListener("change", cb);
    },
    get: () => window.matchMedia(query).matches,
  };
}

const desktop = mediaStore("(min-width: 768px)");
const wide = mediaStore("(min-width: 1024px)");

export function useIsDesktop() {
  return useSyncExternalStore(desktop.subscribe, desktop.get, () => false);
}

export function useIsWide() {
  return useSyncExternalStore(wide.subscribe, wide.get, () => false);
}

/** Today's date, re-evaluated each render (the app only renders on the client). */
export function useToday() {
  return useSyncExternalStore(
    (cb) => {
      const id = setInterval(cb, 60_000);
      return () => clearInterval(id);
    },
    todayISO,
    todayISO,
  );
}
