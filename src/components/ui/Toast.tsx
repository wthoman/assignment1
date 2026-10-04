"use client";

import { AnimatePresence, motion } from "motion/react";
import { createContext, useCallback, useContext, useMemo, useRef, useState, type ReactNode } from "react";
import { Illustration } from "@/components/illustrations/Illustration";
import type { IllustrationKey } from "@/lib/types";

export interface ToastInput {
  title: string;
  body?: string;
  motif?: IllustrationKey;
  action?: { label: string; onClick: () => void };
  duration?: number;
}

interface ToastItem extends ToastInput {
  id: number;
}

const ToastContext = createContext<(t: ToastInput) => void>(() => {});

export function useToast() {
  return useContext(ToastContext);
}

export function ToastProvider({ children }: { children: ReactNode }) {
  const [items, setItems] = useState<ToastItem[]>([]);
  const nextId = useRef(1);
  const dismiss = useCallback((id: number) => setItems((xs) => xs.filter((x) => x.id !== id)), []);
  const push = useCallback(
    (t: ToastInput) => {
      const id = nextId.current++;
      setItems((xs) => [...xs.slice(-2), { ...t, id }]);
      setTimeout(() => dismiss(id), t.duration ?? (t.action ? 5000 : 3200));
    },
    [dismiss],
  );
  const value = useMemo(() => push, [push]);

  return (
    <ToastContext.Provider value={value}>
      {children}
      <div
        aria-live="polite"
        aria-atomic="false"
        className="pointer-events-none fixed inset-x-0 bottom-[calc(5.5rem+env(safe-area-inset-bottom))] z-[90] flex flex-col items-center gap-2 px-4 md:bottom-6 md:left-auto md:right-6 md:items-end"
      >
        <AnimatePresence initial={false}>
          {items.map((t) => (
            <motion.div
              key={t.id}
              layout
              initial={{ opacity: 0, y: 16, scale: 0.96 }}
              animate={{ opacity: 1, y: 0, scale: 1 }}
              exit={{ opacity: 0, y: 8, scale: 0.97 }}
              transition={{ type: "spring", stiffness: 500, damping: 36 }}
              className="pointer-events-auto flex w-full max-w-sm items-center gap-3 rounded-[16px] border border-line bg-ink py-2.5 pl-3 pr-2 text-paper shadow-[var(--shadow-lift)] dark:bg-cream dark:text-ink"
              role="status"
            >
              {t.motif && (
                <span className="grid size-9 shrink-0 place-items-center rounded-[10px] bg-paper/10">
                  <Illustration kind={t.motif} size={28} />
                </span>
              )}
              <div className="min-w-0 flex-1 py-0.5">
                <p className="font-display text-[0.9375rem] font-semibold leading-tight">{t.title}</p>
                {t.body && <p className="mt-0.5 text-[0.8125rem] leading-snug opacity-75">{t.body}</p>}
              </div>
              {t.action && (
                <button
                  type="button"
                  onClick={() => {
                    t.action!.onClick();
                    dismiss(t.id);
                  }}
                  className="min-h-10 shrink-0 rounded-[10px] px-3 font-display text-sm font-bold text-gold hover:bg-paper/10 dark:text-accent"
                >
                  {t.action.label}
                </button>
              )}
            </motion.div>
          ))}
        </AnimatePresence>
      </div>
    </ToastContext.Provider>
  );
}

/** Gentle haptic tick where supported. Visual feedback is handled by the caller. */
export function haptic(enabled: boolean, pattern: number | number[] = 12) {
  if (!enabled || typeof navigator === "undefined" || !("vibrate" in navigator)) return;
  try {
    navigator.vibrate(pattern);
  } catch {
    /* unsupported */
  }
}
