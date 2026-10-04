/**
 * Local-first data layer. State lives in memory, is persisted to localStorage,
 * and is read through useSyncExternalStore. Swapping in a backend means replacing
 * `load`/`persist` (and making `dispatch` call an API) without touching UI code.
 */
import { createSeedState, STATE_VERSION } from "../data/seed";
import { todayISO } from "../dates";
import type { AppState } from "../types";
import type { Action } from "./actions";
import { reducer } from "./reducer";

export const STORAGE_KEY = "daybook:v1";

let state: AppState | null = null;
let persistFailed = false;
const listeners = new Set<() => void>();

function load(): AppState {
  try {
    const raw = window.localStorage.getItem(STORAGE_KEY);
    if (raw) {
      const parsed = JSON.parse(raw) as AppState;
      if (parsed && parsed.version === STATE_VERSION && parsed.users && parsed.habits) return parsed;
    }
  } catch {
    // Corrupt or inaccessible storage: fall through to fresh seed data.
  }
  return createSeedState(todayISO());
}

let persistTimer: ReturnType<typeof setTimeout> | undefined;
function persist() {
  clearTimeout(persistTimer);
  persistTimer = setTimeout(() => {
    try {
      window.localStorage.setItem(STORAGE_KEY, JSON.stringify(state));
      persistFailed = false;
    } catch {
      persistFailed = true;
    }
  }, 120);
}

export function getSnapshot(): AppState | null {
  if (state === null && typeof window !== "undefined") {
    state = load();
    persist();
  }
  return state;
}

export function getServerSnapshot(): AppState | null {
  return null;
}

export function subscribe(listener: () => void) {
  listeners.add(listener);
  const onStorage = (e: StorageEvent) => {
    if (e.key !== STORAGE_KEY) return;
    state = load();
    listener();
  };
  window.addEventListener("storage", onStorage);
  return () => {
    listeners.delete(listener);
    window.removeEventListener("storage", onStorage);
  };
}

export function dispatch(action: Action) {
  const current = getSnapshot();
  if (!current) return;
  state = reducer(current, action);
  persist();
  listeners.forEach((l) => l());
}

export function storageHealthy() {
  return !persistFailed;
}

/** Test helper: replace in-memory state. */
export function __setState(next: AppState | null) {
  state = next;
}
