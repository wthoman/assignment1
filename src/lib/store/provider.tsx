"use client";

import { createContext, useContext, useSyncExternalStore, type ReactNode } from "react";
import type { AppState, User } from "../types";
import type { Action } from "./actions";
import { dispatch, getServerSnapshot, getSnapshot, subscribe } from "./store";

const StateContext = createContext<AppState | null>(null);

export function AppStateProvider({ children, fallback }: { children: ReactNode; fallback: ReactNode }) {
  const state = useSyncExternalStore(subscribe, getSnapshot, getServerSnapshot);
  if (!state) return <>{fallback}</>;
  return <StateContext.Provider value={state}>{children}</StateContext.Provider>;
}

export function useAppState(): AppState {
  const s = useContext(StateContext);
  if (!s) throw new Error("useAppState must be used inside <AppStateProvider>");
  return s;
}

export function useDispatch(): (action: Action) => void {
  return dispatch;
}

export function useMe(): User {
  const s = useAppState();
  return s.users[s.meId];
}

export function useUser(id: string | undefined): User | undefined {
  const s = useAppState();
  return id ? s.users[id] : undefined;
}
