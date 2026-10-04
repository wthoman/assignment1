"use client";

import { motion } from "motion/react";
import { CalendarDays, Check, CloudRain, HeartPulse, Loader2, RefreshCw, ShieldCheck, Smartphone, X, type LucideIcon } from "lucide-react";
import { useEffect, useState } from "react";
import { NativeSelect } from "@/components/settings/SettingsControls";
import { Page } from "@/components/shell/Page";
import { BottomSheet } from "@/components/ui/BottomSheet";
import { Button } from "@/components/ui/Button";
import { Badge, HandNote } from "@/components/ui/misc";
import { useToast } from "@/components/ui/Toast";
import { cn } from "@/lib/cn";
import { relativeTime } from "@/lib/dates";
import { myHabits } from "@/lib/selectors/habits";
import { useAppState, useDispatch } from "@/lib/store/provider";
import type { AppState, ConnectedService, HabitCategory, ServiceKey } from "@/lib/types";

interface ServiceMeta {
  name: string;
  icon: LucideIcon;
  tint: string;
  pitch: string;
  reads: string[];
  never: string[];
  mapLabel: string;
  mapCategories: HabitCategory[];
  sample: (habitName?: string) => { headline: string; detail: string }[];
}

const SERVICES: Record<ServiceKey, ServiceMeta> = {
  "apple-health": {
    name: "Apple Health",
    icon: HeartPulse,
    tint: "bg-rose-soft",
    pitch: "Auto-complete movement and sleep habits from steps, workouts and sleep.",
    reads: ["Daily step count", "Workouts (type and duration)", "Sleep start and end times"],
    never: ["Heart rate, medical records or cycle data", "Anything shared with friends automatically"],
    mapLabel: "Steps can auto-complete",
    mapCategories: ["movement", "outdoors", "sleep"],
    sample: (h) => [
      { headline: "8,412 steps today", detail: h ? `Could auto-complete “${h}” once you pass 6,000.` : "Pick a habit below to auto-complete." },
      { headline: "Slept 7h 05m", detail: "In bed at 11:12pm. Close to your lights-out goal." },
    ],
  },
  "screen-time": {
    name: "Screen Time",
    icon: Smartphone,
    tint: "bg-sky-soft",
    pitch: "Check off wind-down habits when your phone actually goes quiet.",
    reads: ["Daily screen time total", "Time of your last phone pickup"],
    never: ["Which apps or sites you use", "Message or notification content"],
    mapLabel: "Last pickup can complete",
    mapCategories: ["sleep", "mind"],
    sample: (h) => [
      { headline: "Screen time 3h 12m today", detail: "41 minutes less than last week's average." },
      { headline: "Last pickup 10:38pm", detail: h ? `Would count toward “${h}”.` : "Pick a habit below to use this." },
    ],
  },
  calendar: {
    name: "Calendars",
    icon: CalendarDays,
    tint: "bg-gold-soft",
    pitch: "Spot clashes with busy days and suggest a better slot.",
    reads: ["Busy / free times for the next 7 days"],
    never: ["Event titles, guests or locations", "Creating or changing events"],
    mapLabel: "Watch for clashes with",
    mapCategories: ["movement", "study", "creative"],
    sample: (h) => [
      { headline: "2 events conflict with " + (h ?? "your habits"), detail: "Thursday 5–6:30pm is busy. Try 7:15am instead?" },
      { headline: "Free evening on Friday", detail: "A good night for a longer session." },
    ],
  },
  weather: {
    name: "Weather",
    icon: CloudRain,
    tint: "bg-sage-soft",
    pitch: "Heads-up when rain or heat might change outdoor plans.",
    reads: ["Approximate location (city level)", "Hourly forecast"],
    never: ["Precise location", "Location history"],
    mapLabel: "Give weather tips for",
    mapCategories: ["movement", "outdoors"],
    sample: (h) => [
      { headline: "Rain at 7am, walk indoors?", detail: h ? `Heads-up for “${h}”. Clears by 10am.` : "Clears by 10am." },
      { headline: "14° and sunny this afternoon", detail: "Nice window for something outside." },
    ],
  },
};

const ORDER: ServiceKey[] = ["apple-health", "screen-time", "calendar", "weather"];

function suggestedHabit(state: AppState, key: ServiceKey) {
  return myHabits(state).find((h) => SERVICES[key].mapCategories.includes(h.category))?.id;
}

export default function ConnectedServicesPage() {
  const state = useAppState();
  const dispatch = useDispatch();
  const toast = useToast();
  const connected = state.settings.connected;
  const [asking, setAsking] = useState<ServiceKey | null>(null);
  const [askOpen, setAskOpen] = useState(false);

  // Finish any "syncing" state after a short, believable delay (also resumes after a reload).
  useEffect(() => {
    const timers = ORDER.filter((k) => connected[k].status === "syncing").map((k) =>
      window.setTimeout(() => {
        dispatch({ type: "settings/connection", service: k, value: { ...connected[k], status: "connected", lastSync: new Date().toISOString() } });
      }, 1200),
    );
    return () => timers.forEach((t) => window.clearTimeout(t));
  }, [connected, dispatch]);

  const set = (k: ServiceKey, value: ConnectedService) => dispatch({ type: "settings/connection", service: k, value });

  const allow = () => {
    if (!asking) return;
    set(asking, { status: "syncing", mappedHabitId: connected[asking].mappedHabitId ?? suggestedHabit(state, asking) });
    toast({ title: `Connecting ${SERVICES[asking].name}…`, body: "Preview: using sample data." });
    setAskOpen(false);
  };

  const meta = asking ? SERVICES[asking] : null;
  const habits = myHabits(state);

  return (
    <Page title="Connected services" back="/settings">
      <div className="mb-5 flex items-start gap-3 rounded-[16px] border border-dashed border-line-strong bg-gold-soft/60 p-3.5">
        <Badge tone="gold" className="mt-0.5 shrink-0">
          Preview
        </Badge>
        <p className="text-sm leading-relaxed text-ink">Integrations aren&apos;t live yet. Connecting shows realistic sample data so you can see how it would work. Nothing leaves this device.</p>
      </div>

      <ul className="space-y-3">
        {ORDER.map((k) => {
          const s = SERVICES[k];
          const c = connected[k];
          const Icon = s.icon;
          const mapped = habits.find((h) => h.id === c.mappedHabitId);
          return (
            <li key={k} className={cn("card overflow-hidden", c.status === "connected" && "border-line-strong")}>
              <div className="flex items-start gap-3 p-4">
                <span className={cn("grid size-11 shrink-0 place-items-center rounded-[13px] border border-line text-accent", s.tint)}>
                  <Icon size={22} aria-hidden />
                </span>
                <div className="min-w-0 flex-1">
                  <div className="flex flex-wrap items-center gap-2">
                    <h2 className="font-display text-base font-bold text-ink">{s.name}</h2>
                    {c.status === "connected" && <Badge tone="sage">Connected</Badge>}
                    {c.status === "syncing" && <Badge tone="gold">Syncing</Badge>}
                    {c.status === "error" && <Badge tone="orange">Needs attention</Badge>}
                  </div>
                  <p className="mt-0.5 text-[0.8125rem] leading-snug text-muted">
                    {c.status === "connected" && c.lastSync ? `Last synced ${relativeTime(c.lastSync)}` : s.pitch}
                  </p>
                </div>
                {c.status === "disconnected" || c.status === "error" ? (
                  <Button
                    size="sm"
                    onClick={() => {
                      setAsking(k);
                      setAskOpen(true);
                    }}
                  >
                    Connect
                  </Button>
                ) : c.status === "syncing" ? (
                  <span className="inline-flex min-h-9 items-center gap-1.5 px-2 text-sm font-semibold text-muted" role="status">
                    <Loader2 size={16} className="animate-spin" aria-hidden /> Syncing
                  </span>
                ) : null}
              </div>

              {c.status === "syncing" && (
                <div className="px-4 pb-4" aria-hidden>
                  <div className="h-1.5 overflow-hidden rounded-full bg-paper-deep">
                    <motion.div className="h-full rounded-full bg-accent" initial={{ width: "8%" }} animate={{ width: "92%" }} transition={{ duration: 1.2, ease: "easeOut" }} />
                  </div>
                </div>
              )}

              {c.status === "connected" && (
                <div className="space-y-3 border-t border-line bg-paper/40 px-4 py-4">
                  <ul className="space-y-2">
                    {s.sample(mapped?.name).map((row) => (
                      <li key={row.headline} className="flex items-start gap-2.5">
                        <Check size={16} className="mt-0.5 shrink-0 text-sage-ink" aria-hidden />
                        <span className="text-sm">
                          <span className="font-semibold text-ink">{row.headline}</span>
                          <span className="block text-[0.8125rem] text-muted">{row.detail}</span>
                        </span>
                      </li>
                    ))}
                  </ul>
                  <div className="space-y-1.5">
                    <label htmlFor={`map-${k}`} className="font-display text-sm font-semibold text-ink">
                      {s.mapLabel}
                    </label>
                    <NativeSelect id={`map-${k}`} value={c.mappedHabitId ?? ""} onChange={(e) => set(k, { ...c, mappedHabitId: e.target.value || undefined })}>
                      <option value="">No habit</option>
                      {habits.map((h) => (
                        <option key={h.id} value={h.id}>
                          {h.name}
                        </option>
                      ))}
                    </NativeSelect>
                  </div>
                  <div className="flex flex-wrap gap-2">
                    <Button size="sm" variant="secondary" icon={<RefreshCw size={15} aria-hidden />} onClick={() => set(k, { ...c, status: "syncing" })}>
                      Sync now
                    </Button>
                    <Button
                      size="sm"
                      variant="ghost"
                      icon={<X size={15} aria-hidden />}
                      onClick={() => {
                        set(k, { status: "disconnected" });
                        toast({ title: `${s.name} disconnected`, body: "Sample data removed." });
                      }}
                    >
                      Disconnect
                    </Button>
                  </div>
                </div>
              )}
            </li>
          );
        })}
      </ul>
      <p className="mt-6 text-center">
        <HandNote className="text-lg">more coming once these are real</HandNote>
      </p>

      <BottomSheet
        open={askOpen}
        onClose={() => setAskOpen(false)}
        title={meta ? `Connect ${meta.name}?` : "Connect"}
        description="Preview — integrations aren't live yet."
        size="sm"
        footer={
          <div className="flex gap-2">
            <Button variant="secondary" block onClick={() => setAskOpen(false)}>
              Not now
            </Button>
            <Button block onClick={allow} data-autofocus>
              Allow (preview)
            </Button>
          </div>
        }
      >
        {meta && (
          <div className="space-y-4">
            <div className="flex items-center gap-3">
              <span className={cn("grid size-12 place-items-center rounded-[14px] border border-line text-accent", meta.tint)}>
                <meta.icon size={24} aria-hidden />
              </span>
              <p className="text-sm leading-relaxed text-muted">{meta.pitch}</p>
            </div>
            <div>
              <h3 className="font-display text-sm font-bold text-ink">Daybook would read</h3>
              <ul className="mt-1.5 space-y-1.5">
                {meta.reads.map((r) => (
                  <li key={r} className="flex items-start gap-2 text-sm text-ink">
                    <Check size={16} className="mt-0.5 shrink-0 text-sage-ink" aria-hidden /> {r}
                  </li>
                ))}
              </ul>
            </div>
            <div>
              <h3 className="font-display text-sm font-bold text-ink">Daybook would never</h3>
              <ul className="mt-1.5 space-y-1.5">
                {meta.never.map((r) => (
                  <li key={r} className="flex items-start gap-2 text-sm text-muted">
                    <X size={16} className="mt-0.5 shrink-0 text-faint" aria-hidden /> {r}
                  </li>
                ))}
              </ul>
            </div>
            <p className="flex items-start gap-2 rounded-[12px] bg-paper/70 p-3 text-[0.8125rem] text-muted">
              <ShieldCheck size={16} className="mt-0.5 shrink-0 text-accent" aria-hidden />
              Synced data stays on your device and is never shown to friends. You can disconnect any time.
            </p>
          </div>
        )}
      </BottomSheet>
    </Page>
  );
}
