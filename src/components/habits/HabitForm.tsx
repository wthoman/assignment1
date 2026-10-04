"use client";

import { AnimatePresence, motion } from "motion/react";
import { Bell, Camera, Check, ChevronDown, Clock, Lock, Minus, Plus, Sun, Sunrise, Sunset, Trash2, Users, X } from "lucide-react";
import { useRouter } from "next/navigation";
import { useEffect, useId, useMemo, useRef, useState, type ReactNode } from "react";
import { Avatar } from "@/components/avatar/Avatar";
import { FriendAvatarStack } from "@/components/avatar/FriendAvatarStack";
import { IllustrationTile, TINT_SOLID } from "@/components/illustrations/Illustration";
import { Button } from "@/components/ui/Button";
import { ConfirmationDialog } from "@/components/ui/ConfirmationDialog";
import { CharCount, Field, Segmented, TextArea, TextInput, Toggle } from "@/components/ui/controls";
import { Badge, HandNote, Tape } from "@/components/ui/misc";
import { useToast } from "@/components/ui/Toast";
import { CATEGORY_META, HABIT_ICONS, ILLUSTRATION_LABELS, PERSONALITIES } from "@/lib/data/catalog";
import { cn } from "@/lib/cn";
import { orderedWeekdays, WEEKDAY_LETTER, WEEKDAY_LONG, WEEKDAY_SHORT } from "@/lib/dates";
import { useToday } from "@/lib/hooks";
import { uid } from "@/lib/random";
import { scheduleLabel, TIME_LABEL } from "@/lib/selectors/habits";
import type { HabitDraft } from "@/lib/store/actions";
import { useAppState, useDispatch } from "@/lib/store/provider";
import type { FrequencyPreset, Habit, HabitCategory, HabitPrivacy, IllustrationKey, ProofMode, Tint, TimeOfDay } from "@/lib/types";

/* ---------- Presets ---------- */

const ALL_DAYS = [0, 1, 2, 3, 4, 5, 6];
const PRESET_DAYS: Record<Exclude<FrequencyPreset, "custom" | "three-per-week">, number[]> = {
  daily: ALL_DAYS,
  weekdays: [1, 2, 3, 4, 5],
  weekends: [0, 6],
};
/** Evenly spread suggestions for "N× a week". */
export const SUGGESTED_DAYS: Record<number, number[]> = {
  1: [3],
  2: [2, 5],
  3: [1, 3, 5],
  4: [1, 2, 4, 6],
  5: [1, 2, 3, 4, 5],
  6: [1, 2, 3, 4, 5, 6],
};

export function daysForFrequency(f: FrequencyPreset, timesPerWeek = 3, current: number[] = ALL_DAYS): number[] {
  if (f === "custom") return current;
  if (f === "three-per-week") return SUGGESTED_DAYS[timesPerWeek] ?? SUGGESTED_DAYS[3];
  return PRESET_DAYS[f];
}

type PresetDraft = Partial<Pick<HabitDraft, "name" | "icon" | "category" | "frequency" | "timeOfDay" | "timesPerWeek" | "description">>;

/** Suggestion presets usable via `/habits/new?preset=<key>`. Keys match onboarding goal keys. */
export const HABIT_PRESETS: Record<string, PresetDraft> = {
  move: { name: "10-minute walk", icon: "shoe", category: "movement", frequency: "daily", timeOfDay: "anytime" },
  walk: { name: "Morning walk", icon: "shoe", category: "movement", frequency: "daily", timeOfDay: "morning" },
  sleep: { name: "Lights out by 11", icon: "moon", category: "sleep", frequency: "daily", timeOfDay: "evening" },
  read: { name: "Read 10 pages", icon: "book", category: "study", frequency: "weekdays", timeOfDay: "evening" },
  hydrate: { name: "Drink a glass of water", icon: "water", category: "hydration", frequency: "daily", timeOfDay: "morning" },
  water: { name: "Six glasses of water", icon: "water", category: "hydration", frequency: "daily", timeOfDay: "anytime" },
  focus: { name: "One focused study block", icon: "pencil", category: "study", frequency: "weekdays", timeOfDay: "afternoon" },
  calm: { name: "Five minutes of quiet", icon: "flower", category: "mind", frequency: "daily", timeOfDay: "evening" },
  eat: { name: "A piece of fruit", icon: "fruit", category: "nourish", frequency: "daily", timeOfDay: "anytime" },
  outside: { name: "Something outdoors", icon: "leaf", category: "outdoors", frequency: "three-per-week", timesPerWeek: 3, timeOfDay: "afternoon" },
  strength: { name: "Strength session", icon: "dumbbell", category: "movement", frequency: "three-per-week", timesPerWeek: 3, timeOfDay: "afternoon" },
  create: { name: "Make something", icon: "music", category: "creative", frequency: "three-per-week", timesPerWeek: 3, timeOfDay: "evening" },
  mornings: { name: "Up by 7:30", icon: "alarm", category: "sleep", frequency: "weekdays", timeOfDay: "morning" },
  friends: { name: "Call someone you love", icon: "phone", category: "mind", frequency: "weekends", timeOfDay: "anytime" },
  journal: { name: "Journal three lines", icon: "pencil", category: "creative", frequency: "daily", timeOfDay: "evening" },
  stretch: { name: "Stretch for 10 minutes", icon: "flower", category: "movement", frequency: "daily", timeOfDay: "morning" },
};

const ICON_CATEGORY: Partial<Record<IllustrationKey, HabitCategory>> = {
  shoe: "movement", bike: "movement", dumbbell: "movement", water: "hydration", flower: "mind", heart: "mind", phone: "mind",
  moon: "sleep", alarm: "sleep", book: "study", pencil: "creative", music: "creative", fruit: "nourish", leaf: "outdoors", sun: "outdoors", coffee: "home",
};

function parseSchedule(s: string): PresetDraft {
  const lower = s.toLowerCase();
  const out: PresetDraft = {};
  if (lower.includes("weekday")) out.frequency = "weekdays";
  else if (lower.includes("weekend")) out.frequency = "weekends";
  else if (/\d×/.test(lower)) {
    out.frequency = "three-per-week";
    out.timesPerWeek = Number(lower.match(/(\d)×/)?.[1] ?? 3);
  } else out.frequency = "daily";
  for (const t of ["morning", "afternoon", "evening"] as const) if (lower.includes(t)) out.timeOfDay = t;
  return out;
}

/**
 * Reads `?preset=` (a HABIT_PRESETS key or a suggested habit name) plus optional
 * `name`, `icon`, `category` and `frequency` overrides.
 */
export function presetFromParams(params: URLSearchParams | null): PresetDraft | undefined {
  if (!params) return undefined;
  const key = params.get("preset")?.trim();
  let base: PresetDraft | undefined = key ? HABIT_PRESETS[key.toLowerCase()] : undefined;
  if (key && !base) {
    const match = Object.values(PERSONALITIES)
      .flatMap((p) => p.habits)
      .find((h) => h.name.toLowerCase() === key.toLowerCase());
    base = match
      ? { name: match.name, icon: match.icon, category: ICON_CATEGORY[match.icon], ...parseSchedule(match.schedule) }
      : { name: key.slice(0, 60) };
  }
  const out: PresetDraft = { ...base };
  const name = params.get("name");
  const icon = params.get("icon") as IllustrationKey | null;
  const category = params.get("category") as HabitCategory | null;
  const frequency = params.get("frequency") as FrequencyPreset | null;
  if (name) out.name = name.slice(0, 60);
  if (icon && icon in ILLUSTRATION_LABELS) out.icon = icon;
  if (category && category in CATEGORY_META) out.category = category;
  if (frequency && ["daily", "weekdays", "weekends", "three-per-week", "custom"].includes(frequency)) out.frequency = frequency;
  if (out.icon && !out.category) out.category = ICON_CATEGORY[out.icon];
  return Object.keys(out).length ? out : undefined;
}

/* ---------- Draft helpers ---------- */

export function emptyDraft(today: string): HabitDraft {
  return {
    name: "",
    description: "",
    icon: "shoe",
    category: "movement",
    tint: "orange",
    frequency: "daily",
    days: ALL_DAYS,
    timesPerWeek: 3,
    timeOfDay: "anytime",
    remindersOn: true,
    reminderTimes: ["09:00"],
    shared: false,
    participantIds: [],
    proof: "off",
    notesEnabled: true,
    showStreak: true,
    privacy: "friends",
    startDate: today,
    targetDate: undefined,
    optional: false,
  };
}

function draftFromHabit(h: Habit, meId: string): HabitDraft {
  const rest: Partial<Habit> = { ...h };
  delete rest.id;
  delete rest.ownerId;
  delete rest.createdAt;
  delete rest.status;
  return { ...(rest as HabitDraft), participantIds: h.participantIds.filter((p) => p !== meId), reminderTimes: [...h.reminderTimes] };
}

function applyPreset(d: HabitDraft, p: PresetDraft): HabitDraft {
  const next = { ...d, ...p };
  if (p.category) {
    next.tint = CATEGORY_META[p.category].tint;
    if (!p.icon) next.icon = CATEGORY_META[p.category].icon;
  }
  if (p.timeOfDay) next.reminderTimes = [DEFAULT_REMINDER[p.timeOfDay]];
  next.days = daysForFrequency(next.frequency, next.timesPerWeek, next.days);
  return next;
}

const DEFAULT_REMINDER: Record<TimeOfDay, string> = { morning: "08:00", afternoon: "13:00", evening: "20:00", anytime: "09:00" };

const TINTS: { value: Tint; label: string }[] = [
  { value: "burgundy", label: "Burgundy" },
  { value: "rose", label: "Rose" },
  { value: "orange", label: "Apricot" },
  { value: "gold", label: "Marigold" },
  { value: "sage", label: "Sage" },
  { value: "sky", label: "Sky" },
  { value: "cream", label: "Cream" },
];

const FREQUENCIES: { value: FrequencyPreset; label: string }[] = [
  { value: "daily", label: "Every day" },
  { value: "weekdays", label: "Weekdays" },
  { value: "weekends", label: "Weekends" },
  { value: "three-per-week", label: "× a week" },
  { value: "custom", label: "Custom" },
];

const TIMES: { value: TimeOfDay; label: string; icon: ReactNode }[] = [
  { value: "morning", label: "Morning", icon: <Sunrise size={17} aria-hidden /> },
  { value: "afternoon", label: "Afternoon", icon: <Sun size={17} aria-hidden /> },
  { value: "evening", label: "Evening", icon: <Sunset size={17} aria-hidden /> },
  { value: "anytime", label: "Anytime", icon: <Clock size={17} aria-hidden /> },
];

const PROOF: { value: ProofMode; label: string; detail: string }[] = [
  { value: "off", label: "Off", detail: "Just tap to check in." },
  { value: "optional", label: "Optional", detail: "Add a photo when you feel like it." },
  { value: "required", label: "Required", detail: "Every check-in asks for a photo." },
];

const PRIVACY: { value: HabitPrivacy; label: string; detail: string }[] = [
  { value: "private", label: "Only me", detail: "Never shown in feeds or recaps." },
  { value: "friends", label: "Friends", detail: "Friends can see check-ins and react." },
  { value: "group", label: "Groups", detail: "Visible to people in your groups." },
];

/* ---------- Small building blocks ---------- */

function Section({ title, hint, children, id }: { title: string; hint?: string; children: ReactNode; id: string }) {
  return (
    <section aria-labelledby={id} className="card p-4 sm:p-5">
      <div className="mb-4 flex items-baseline justify-between gap-3">
        <h2 id={id} className="font-display text-[1.0625rem] font-bold tracking-[-0.015em] text-ink">
          {title}
        </h2>
        {hint && <span className="font-hand text-lg leading-none text-accent">{hint}</span>}
      </div>
      <div className="space-y-5">{children}</div>
    </section>
  );
}

function GroupLabel({ id, children, aside }: { id: string; children: ReactNode; aside?: ReactNode }) {
  return (
    <div className="mb-1.5 flex items-baseline justify-between gap-2">
      <p id={id} className="font-display text-sm font-semibold text-ink">
        {children}
      </p>
      {aside}
    </div>
  );
}

function ErrorText({ id, children }: { id: string; children: ReactNode }) {
  return (
    <p id={id} role="alert" className="mt-1.5 text-[0.8125rem] font-medium text-[#a3301f] dark:text-[#f0a090]">
      {children}
    </p>
  );
}

/** Radio group of small stacked cards (icon/label/detail). */
function OptionCards<T extends string>({
  value,
  onChange,
  options,
  labelledBy,
  cols = 3,
}: {
  value: T;
  onChange: (v: T) => void;
  options: { value: T; label: string; detail?: string; icon?: ReactNode }[];
  labelledBy: string;
  cols?: 3 | 4;
}) {
  return (
    <div role="radiogroup" aria-labelledby={labelledBy} className={cn("grid gap-1.5", cols === 4 ? "grid-cols-2 min-[400px]:grid-cols-4" : "grid-cols-3")}>
      {options.map((o) => {
        const active = o.value === value;
        return (
          <button
            key={o.value}
            type="button"
            role="radio"
            aria-checked={active}
            onClick={() => onChange(o.value)}
            className={cn(
              "flex min-h-12 flex-col items-start justify-center gap-0.5 rounded-[12px] border px-2.5 py-2 text-left transition-colors",
              active ? "border-accent bg-accent-soft text-accent" : "border-line-strong bg-cream text-ink hover:bg-accent-soft/50",
            )}
          >
            <span className="flex items-center gap-1.5 font-display text-sm font-semibold">
              {o.icon}
              {o.label}
            </span>
            {o.detail && <span className={cn("text-[0.75rem] leading-snug", active ? "text-accent/80" : "text-muted")}>{o.detail}</span>}
          </button>
        );
      })}
    </div>
  );
}

function SwitchRow({ label, detail, checked, onChange, icon }: { label: string; detail?: string; checked: boolean; onChange: (v: boolean) => void; icon?: ReactNode }) {
  return (
    <div className="flex min-h-12 items-center gap-3">
      {icon && <span className="grid size-9 shrink-0 place-items-center rounded-[11px] bg-paper-deep/70 text-muted">{icon}</span>}
      <div className="min-w-0 flex-1">
        <p className="text-[0.9375rem] font-semibold text-ink">{label}</p>
        {detail && <p className="text-[0.8125rem] leading-snug text-muted">{detail}</p>}
      </div>
      <Toggle checked={checked} onChange={onChange} label={label} />
    </div>
  );
}

function WeekdayToggles({
  days,
  weekStart,
  onToggle,
  labelledBy,
  describedBy,
}: {
  days: number[];
  weekStart: 0 | 1;
  onToggle: (d: number) => void;
  labelledBy: string;
  describedBy?: string;
}) {
  return (
    <div role="group" aria-labelledby={labelledBy} aria-describedby={describedBy} className="grid grid-cols-7 gap-1">
      {orderedWeekdays(weekStart).map((d) => {
        const on = days.includes(d);
        return (
          <button
            key={d}
            type="button"
            aria-pressed={on}
            aria-label={WEEKDAY_LONG[d]}
            onClick={() => onToggle(d)}
            className={cn(
              "grid h-11 place-items-center rounded-[11px] border font-display text-sm font-bold transition-colors",
              on ? "border-accent bg-accent text-on-accent" : "border-line-strong bg-cream text-muted hover:bg-accent-soft",
            )}
          >
            <span className="sm:hidden">{WEEKDAY_LETTER[d]}</span>
            <span className="hidden sm:inline">{WEEKDAY_SHORT[d]}</span>
          </button>
        );
      })}
    </div>
  );
}

/* ---------- Preview ---------- */

function Preview({ draft, weekStart, className }: { draft: HabitDraft; weekStart: 0 | 1; className?: string }) {
  const state = useAppState();
  const people = draft.shared ? draft.participantIds.map((id) => state.users[id]).filter(Boolean) : [];
  const label = scheduleLabel({ ...draft } as Habit);
  return (
    <div className={cn("relative", className)} aria-live="polite">
      <p className="sr-only">Preview: {draft.name.trim() || "Untitled habit"}, {label}, {TIME_LABEL[draft.timeOfDay]}</p>
      <div className="card relative px-3.5 py-3" aria-hidden>
        <Tape className="-top-2 left-1/2 -translate-x-1/2" rotate={-3} />
        <div className="flex items-center gap-3">
          <IllustrationTile kind={draft.icon} tint={draft.tint} size={52} rotate={-3} />
          <div className="min-w-0 flex-1">
            <p className={cn("truncate font-display text-[1.0625rem] font-bold leading-tight", draft.name.trim() ? "text-ink" : "text-faint")}>{draft.name.trim() || "Your new habit"}</p>
            <p className="mt-0.5 truncate text-[0.8125rem] text-muted">
              {label} · {TIME_LABEL[draft.timeOfDay]}
              {draft.remindersOn && draft.reminderTimes.length > 0 && " · reminder on"}
            </p>
          </div>
          <span className="grid size-10 shrink-0 place-items-center rounded-[12px] border-2 border-dashed border-line-strong text-faint">
            <Check size={18} />
          </span>
        </div>
        <div className="mt-3 flex items-center justify-between gap-2">
          <div className="flex gap-1">
            {orderedWeekdays(weekStart).map((d) => (
              <span
                key={d}
                className={cn(
                  "grid size-5 place-items-center rounded-[6px] text-[0.625rem] font-bold",
                  draft.days.includes(d) ? cn(TINT_SOLID[draft.tint], draft.tint === "burgundy" ? "text-on-accent" : "text-[#271c1b]") : "bg-paper-deep/60 text-faint",
                )}
              >
                {WEEKDAY_LETTER[d]}
              </span>
            ))}
          </div>
          <div className="flex min-w-0 items-center gap-1.5">
            {draft.optional && <Badge tone="muted">Optional</Badge>}
            {draft.proof !== "off" && <Camera size={14} className="text-muted" />}
            {draft.privacy === "private" && <Lock size={13} className="text-muted" />}
            {people.length > 0 && <FriendAvatarStack users={people} size={22} max={3} />}
          </div>
        </div>
      </div>
    </div>
  );
}

/* ---------- Validation ---------- */

type Errors = Partial<Record<"name" | "description" | "days" | "friends" | "targetDate" | "reminders", string>>;

function validate(d: HabitDraft): Errors {
  const e: Errors = {};
  const name = d.name.trim();
  if (name.length < 2) e.name = name.length === 0 ? "Give your habit a name." : "A name needs at least 2 characters.";
  else if (name.length > 60) e.name = "Keep the name under 60 characters.";
  if (d.description.length > 140) e.description = "Keep the description under 140 characters.";
  if (d.days.length === 0) e.days = "Pick at least one day.";
  if (d.shared && d.participantIds.length === 0) e.friends = "Pick at least one friend, or switch to solo.";
  if (d.targetDate && d.targetDate <= d.startDate) e.targetDate = "The target date needs to be after the start date.";
  if (d.remindersOn && d.reminderTimes.some((t) => !t)) e.reminders = "Fill in each reminder time, or remove the empty one.";
  return e;
}

const FIELD_ORDER: (keyof Errors)[] = ["name", "description", "days", "reminders", "friends", "targetDate"];
/** Errors shown as soon as they happen; the rest wait for blur or submit. */
const LIVE: (keyof Errors)[] = ["description", "days", "targetDate"];

/* ---------- Form ---------- */

export interface HabitFormProps {
  /** Existing habit to edit; omit to create a new one. */
  habit?: Habit;
  /** Prefill for new habits (see `presetFromParams`). */
  preset?: PresetDraft;
}

export function HabitForm({ habit, preset }: HabitFormProps) {
  const state = useAppState();
  const dispatch = useDispatch();
  const toast = useToast();
  const router = useRouter();
  const today = useToday();
  const base = useId();
  const ids = (k: string) => `${base}-${k}`;
  const weekStart = state.settings.weekStart;
  const me = state.users[state.meId];
  const friends = useMemo(() => me.friendIds.map((id) => state.users[id]).filter(Boolean), [me.friendIds, state.users]);
  const editing = Boolean(habit);

  const [initial] = useState<HabitDraft>(() => (habit ? draftFromHabit(habit, state.meId) : preset ? applyPreset(emptyDraft(today), preset) : emptyDraft(today)));
  const [draft, setDraft] = useState<HabitDraft>(initial);
  const [touched, setTouched] = useState({ icon: editing || Boolean(preset?.icon), tint: editing, name: false });
  const [submitted, setSubmitted] = useState(false);
  const [moreOpen, setMoreOpen] = useState(() => editing && (initial.proof !== "off" || initial.optional || Boolean(initial.targetDate)));
  const [confirmLeave, setConfirmLeave] = useState(false);
  const savedRef = useRef(false);

  const errors = validate(draft);
  const show = (k: keyof Errors) => Boolean(errors[k]) && (submitted || LIVE.includes(k) || (k === "name" && touched.name));
  const dirty = JSON.stringify(draft) !== JSON.stringify(initial);

  useEffect(() => {
    if (!dirty) return;
    const onBeforeUnload = (e: BeforeUnloadEvent) => {
      if (savedRef.current) return;
      e.preventDefault();
    };
    window.addEventListener("beforeunload", onBeforeUnload);
    return () => window.removeEventListener("beforeunload", onBeforeUnload);
  }, [dirty]);

  const set = <K extends keyof HabitDraft>(k: K, v: HabitDraft[K]) => setDraft((d) => ({ ...d, [k]: v }));

  const pickCategory = (c: HabitCategory) =>
    setDraft((d) => ({
      ...d,
      category: c,
      icon: touched.icon ? d.icon : CATEGORY_META[c].icon,
      tint: touched.tint ? d.tint : CATEGORY_META[c].tint,
    }));

  const pickFrequency = (f: FrequencyPreset) => setDraft((d) => ({ ...d, frequency: f, days: f === "custom" ? (d.days.length === 7 ? [1, 3, 5] : d.days) : daysForFrequency(f, d.timesPerWeek, d.days) }));

  const setTimesPerWeek = (n: number) => setDraft((d) => ({ ...d, timesPerWeek: n, days: SUGGESTED_DAYS[n] }));

  const toggleDay = (day: number) => setDraft((d) => ({ ...d, days: d.days.includes(day) ? d.days.filter((x) => x !== day) : [...d.days, day].sort() }));

  const toggleFriend = (id: string) => setDraft((d) => ({ ...d, participantIds: d.participantIds.includes(id) ? d.participantIds.filter((x) => x !== id) : [...d.participantIds, id] }));

  const setTime = (i: number, v: string) => setDraft((d) => ({ ...d, reminderTimes: d.reminderTimes.map((t, j) => (j === i ? v : t)) }));
  const addTime = () => setDraft((d) => ({ ...d, reminderTimes: [...d.reminderTimes, DEFAULT_REMINDER[d.timeOfDay === "morning" ? "evening" : "morning"]].slice(0, 3) }));
  const removeTime = (i: number) => setDraft((d) => ({ ...d, reminderTimes: d.reminderTimes.filter((_, j) => j !== i) }));

  const exitHref = habit ? `/habits/${habit.id}` : "/today";
  const leave = () => router.push(exitHref);
  const cancel = () => (dirty ? setConfirmLeave(true) : leave());

  const submit = (e: React.FormEvent) => {
    e.preventDefault();
    setSubmitted(true);
    const first = FIELD_ORDER.find((k) => errors[k]);
    if (first) {
      if (first === "targetDate") setMoreOpen(true);
      requestAnimationFrame(() => {
        const el = document.getElementById(ids(first));
        el?.focus({ preventScroll: true });
        el?.scrollIntoView({ block: "center", behavior: "smooth" });
      });
      return;
    }
    const clean: HabitDraft = {
      ...draft,
      name: draft.name.trim(),
      description: draft.description.trim(),
      days: [...draft.days].sort(),
      reminderTimes: Array.from(new Set(draft.reminderTimes.filter(Boolean))).sort(),
      participantIds: draft.shared ? draft.participantIds : [],
      targetDate: draft.targetDate || undefined,
    };
    savedRef.current = true;
    if (habit) {
      dispatch({ type: "habit/update", id: habit.id, patch: clean });
      toast({ title: "Changes saved", body: clean.name, motif: clean.icon });
      router.push(`/habits/${habit.id}`);
    } else {
      dispatch({ type: "habit/create", draft: clean, id: uid("h") });
      toast({ title: "Habit added", body: `“${clean.name}” is on your Today list.`, motif: clean.icon });
      router.push("/today");
    }
  };

  const nameErr = show("name") ? errors.name : undefined;

  return (
    <>
      <form onSubmit={submit} noValidate className="lg:grid lg:grid-cols-[minmax(0,1fr)_280px] lg:gap-6">
        <div className="lg:sticky lg:top-6 lg:order-2 lg:self-start">
          <p className="eyebrow mb-2 hidden lg:block">Preview</p>
          <Preview draft={draft} weekStart={weekStart} />
          <HandNote className="mt-3 hidden pl-2 lg:inline-block" rotate={-2}>
            {draft.optional ? "a nice-to-have, no pressure" : draft.shared ? "better together" : "small and doable wins"}
          </HandNote>
        </div>

        <div className="mt-5 space-y-4 lg:order-1 lg:mt-0">
          <Section title="The basics" id={ids("s-basics")}>
            <Field label="Name" htmlFor={ids("name")} error={nameErr} hint="Small and specific works best — “10-minute walk” beats “get fit”.">
              <div className="relative">
                <TextInput
                  id={ids("name")}
                  value={draft.name}
                  onChange={(e) => set("name", e.target.value)}
                  onBlur={() => setTouched((t) => ({ ...t, name: true }))}
                  invalid={Boolean(nameErr)}
                  maxLength={80}
                  placeholder="e.g. Read 10 pages"
                  autoComplete="off"
                  required
                  className="pr-14"
                />
                <span className="pointer-events-none absolute right-3 top-1/2 -translate-y-1/2">
                  <CharCount value={draft.name} max={60} />
                </span>
              </div>
            </Field>
            <Field label="Description" htmlFor={ids("description")} optional error={show("description") ? errors.description : undefined}>
              <TextArea
                id={ids("description")}
                value={draft.description}
                onChange={(e) => set("description", e.target.value)}
                invalid={Boolean(show("description"))}
                aria-describedby={ids("description-count")}
                maxLength={160}
                rows={2}
                className="min-h-16"
                placeholder="A note to future you"
              />
              <div className="-mt-1 flex justify-end" id={ids("description-count")}>
                <CharCount value={draft.description} max={140} />
              </div>
            </Field>

            <div>
              <GroupLabel id={ids("l-cat")}>Category</GroupLabel>
              <div role="radiogroup" aria-labelledby={ids("l-cat")} className="flex flex-wrap gap-1.5">
                {(Object.keys(CATEGORY_META) as HabitCategory[]).map((c) => {
                  const active = draft.category === c;
                  return (
                    <button
                      key={c}
                      type="button"
                      role="radio"
                      aria-checked={active}
                      onClick={() => pickCategory(c)}
                      className={cn(
                        "inline-flex min-h-10 items-center gap-1.5 rounded-[11px] border px-2.5 text-sm font-semibold transition-colors",
                        active ? "border-accent bg-accent text-on-accent" : "border-line-strong bg-cream text-ink hover:bg-accent-soft",
                      )}
                    >
                      <span className={cn("size-2.5 rounded-[3px]", TINT_SOLID[CATEGORY_META[c].tint])} aria-hidden />
                      {CATEGORY_META[c].label}
                    </button>
                  );
                })}
              </div>
            </div>

            <div>
              <GroupLabel id={ids("l-icon")} aside={<span className="text-xs text-faint">{ILLUSTRATION_LABELS[draft.icon]}</span>}>
                Illustration
              </GroupLabel>
              <div role="group" aria-labelledby={ids("l-icon")} className="grid grid-cols-[repeat(auto-fill,minmax(46px,1fr))] gap-1.5">
                {HABIT_ICONS.map((k) => {
                  const active = draft.icon === k;
                  return (
                    <button
                      key={k}
                      type="button"
                      aria-pressed={active}
                      aria-label={ILLUSTRATION_LABELS[k]}
                      title={ILLUSTRATION_LABELS[k]}
                      onClick={() => {
                        set("icon", k);
                        setTouched((t) => ({ ...t, icon: true }));
                      }}
                      className={cn(
                        "grid aspect-square min-h-11 place-items-center rounded-[13px] border-2 transition-[border-color,transform] active:scale-95",
                        active ? "border-accent" : "border-transparent hover:border-line-strong",
                      )}
                    >
                      <IllustrationTile kind={k} tint={active ? draft.tint : "cream"} size={40} rotate={active ? -4 : 0} />
                    </button>
                  );
                })}
              </div>
            </div>

            <div>
              <GroupLabel id={ids("l-tint")}>Colour</GroupLabel>
              <div role="radiogroup" aria-labelledby={ids("l-tint")} className="flex flex-wrap gap-1.5">
                {TINTS.map((t) => {
                  const active = draft.tint === t.value;
                  return (
                    <button
                      key={t.value}
                      type="button"
                      role="radio"
                      aria-checked={active}
                      aria-label={t.label}
                      title={t.label}
                      onClick={() => {
                        set("tint", t.value);
                        setTouched((x) => ({ ...x, tint: true }));
                      }}
                      className={cn("grid size-11 place-items-center rounded-[12px] border-2 transition-colors", active ? "border-accent" : "border-transparent hover:border-line-strong")}
                    >
                      <span className={cn("grid size-8 place-items-center rounded-[9px] border border-line", TINT_SOLID[t.value])}>
                        {active && <Check size={16} strokeWidth={3} className={t.value === "burgundy" ? "text-on-accent" : "text-[#271c1b]"} aria-hidden />}
                      </span>
                    </button>
                  );
                })}
              </div>
            </div>
          </Section>

          <Section title="Rhythm" id={ids("s-rhythm")} hint={draft.frequency === "daily" ? undefined : "rest days count too"}>
            <div>
              <GroupLabel id={ids("l-freq")}>How often</GroupLabel>
              <div role="radiogroup" aria-labelledby={ids("l-freq")} className="grid grid-cols-3 gap-1.5 min-[480px]:grid-cols-5">
                {FREQUENCIES.map((f) => {
                  const active = draft.frequency === f.value;
                  return (
                    <button
                      key={f.value}
                      type="button"
                      role="radio"
                      aria-checked={active}
                      onClick={() => pickFrequency(f.value)}
                      className={cn(
                        "min-h-11 rounded-[11px] border px-2 font-display text-sm font-semibold transition-colors",
                        active ? "border-accent bg-accent text-on-accent" : "border-line-strong bg-cream text-ink hover:bg-accent-soft",
                      )}
                    >
                      {f.value === "three-per-week" ? `${draft.timesPerWeek}${f.label}` : f.label}
                    </button>
                  );
                })}
              </div>
            </div>

            {draft.frequency === "three-per-week" && (
              <div className="flex items-center justify-between gap-3 rounded-[14px] border border-line bg-paper/60 p-2.5 pl-3.5">
                <div>
                  <p id={ids("l-times")} className="font-display text-sm font-semibold text-ink">
                    Times per week
                  </p>
                  <p className="text-[0.8125rem] text-muted">We&apos;ve spread the days out — tap below to swap.</p>
                </div>
                <div className="flex shrink-0 items-center gap-1" role="group" aria-labelledby={ids("l-times")}>
                  <button type="button" aria-label="Fewer times per week" disabled={draft.timesPerWeek <= 1} onClick={() => setTimesPerWeek(draft.timesPerWeek - 1)} className="grid size-11 place-items-center rounded-[11px] border border-line-strong bg-cream text-accent disabled:opacity-40">
                    <Minus size={16} aria-hidden />
                  </button>
                  <output aria-live="polite" className="w-7 text-center font-display text-xl font-bold tabular-nums text-ink">
                    {draft.timesPerWeek}
                  </output>
                  <button type="button" aria-label="More times per week" disabled={draft.timesPerWeek >= 6} onClick={() => setTimesPerWeek(draft.timesPerWeek + 1)} className="grid size-11 place-items-center rounded-[11px] border border-line-strong bg-cream text-accent disabled:opacity-40">
                    <Plus size={16} aria-hidden />
                  </button>
                </div>
              </div>
            )}

            {(draft.frequency === "custom" || draft.frequency === "three-per-week") && (
              <div>
                <GroupLabel id={ids("l-days")} aside={<span className="text-xs text-faint">{draft.days.length} picked</span>}>
                  {draft.frequency === "custom" ? "Which days" : "Suggested days"}
                </GroupLabel>
                <div id={ids("days")} tabIndex={-1} className="outline-none">
                  <WeekdayToggles days={draft.days} weekStart={weekStart} onToggle={toggleDay} labelledBy={ids("l-days")} describedBy={show("days") ? ids("days-error") : undefined} />
                </div>
                {show("days") && <ErrorText id={ids("days-error")}>{errors.days}</ErrorText>}
              </div>
            )}

            <div>
              <GroupLabel id={ids("l-tod")}>Time of day</GroupLabel>
              <OptionCards value={draft.timeOfDay} onChange={(v) => set("timeOfDay", v)} options={TIMES} labelledBy={ids("l-tod")} cols={4} />
            </div>

            <div className="rounded-[14px] border border-line bg-paper/50 px-3.5 py-1.5">
              <SwitchRow label="Reminders" detail="A gentle nudge, never a nag." checked={draft.remindersOn} onChange={(v) => set("remindersOn", v)} icon={<Bell size={17} aria-hidden />} />
              <AnimatePresence initial={false}>
                {draft.remindersOn && (
                  <motion.div initial={{ height: 0, opacity: 0 }} animate={{ height: "auto", opacity: 1 }} exit={{ height: 0, opacity: 0 }} transition={{ duration: 0.2 }} className="overflow-hidden">
                    <ul className="space-y-1.5 pb-2 pt-1" id={ids("reminders")} tabIndex={-1}>
                      {draft.reminderTimes.map((t, i) => (
                        <li key={i} className="flex items-center gap-2">
                          <label htmlFor={ids(`time-${i}`)} className="sr-only">
                            Reminder {i + 1} time
                          </label>
                          <input
                            id={ids(`time-${i}`)}
                            type="time"
                            value={t}
                            onChange={(e) => setTime(i, e.target.value)}
                            className="min-h-11 flex-1 rounded-[12px] border border-line-strong bg-cream px-3 font-display text-[0.9375rem] font-semibold tabular-nums text-ink focus:border-accent focus:outline-none focus:ring-3 focus:ring-accent/15"
                          />
                          <button type="button" onClick={() => removeTime(i)} aria-label={`Remove reminder ${i + 1}`} className="grid size-11 shrink-0 place-items-center rounded-[12px] text-muted hover:bg-accent-soft hover:text-accent">
                            <X size={18} aria-hidden />
                          </button>
                        </li>
                      ))}
                    </ul>
                    {show("reminders") && <ErrorText id={ids("reminders-error")}>{errors.reminders}</ErrorText>}
                    {draft.reminderTimes.length < 3 ? (
                      <Button variant="ghost" size="sm" onClick={addTime} icon={<Plus size={16} aria-hidden />} className="mb-2 min-h-11">
                        Add a time
                      </Button>
                    ) : (
                      <p className="pb-2 text-[0.8125rem] text-muted">Three reminders is the max — plenty of nudges.</p>
                    )}
                  </motion.div>
                )}
              </AnimatePresence>
            </div>
          </Section>

          <Section title="Who's in" id={ids("s-who")}>
            <Segmented
              label="Solo or shared"
              value={draft.shared ? "shared" : "solo"}
              onChange={(v) => set("shared", v === "shared")}
              options={[
                { value: "solo", label: "Just me" },
                { value: "shared", label: "With friends", icon: <Users size={15} aria-hidden /> },
              ]}
            />
            <AnimatePresence initial={false}>
              {draft.shared && (
                <motion.div initial={{ height: 0, opacity: 0 }} animate={{ height: "auto", opacity: 1 }} exit={{ height: 0, opacity: 0 }} transition={{ duration: 0.2 }} className="-mx-1 overflow-hidden px-1">
                  <GroupLabel id={ids("l-friends")} aside={<span className="text-xs text-faint">{draft.participantIds.length} invited</span>}>
                    Who&apos;s joining
                  </GroupLabel>
                  {friends.length === 0 ? (
                    <p className="text-sm text-muted">Add friends first, then you can share habits with them.</p>
                  ) : (
                    <div id={ids("friends")} tabIndex={-1} role="group" aria-labelledby={ids("l-friends")} aria-describedby={show("friends") ? ids("friends-error") : undefined} className="grid gap-1.5 outline-none sm:grid-cols-2">
                      {friends.map((f) => {
                        const on = draft.participantIds.includes(f.id);
                        return (
                          <button
                            key={f.id}
                            type="button"
                            role="checkbox"
                            aria-checked={on}
                            onClick={() => toggleFriend(f.id)}
                            className={cn("flex min-h-12 items-center gap-2.5 rounded-[12px] border px-2.5 py-1.5 text-left transition-colors", on ? "border-accent bg-accent-soft" : "border-line-strong bg-cream hover:bg-accent-soft/50")}
                          >
                            <Avatar user={f} size={34} />
                            <span className="min-w-0 flex-1">
                              <span className="block truncate text-sm font-semibold text-ink">{f.name}</span>
                              <span className="block truncate text-xs text-muted">@{f.handle}</span>
                            </span>
                            <span className={cn("grid size-6 shrink-0 place-items-center rounded-[7px] border-2", on ? "border-accent bg-accent text-on-accent" : "border-line-strong")} aria-hidden>
                              {on && <Check size={14} strokeWidth={3} />}
                            </span>
                          </button>
                        );
                      })}
                    </div>
                  )}
                  {show("friends") && <ErrorText id={ids("friends-error")}>{errors.friends}</ErrorText>}
                  <p className="mt-2 text-[0.8125rem] text-muted">Friends get an invite and can say yes or no — no pressure.</p>
                </motion.div>
              )}
            </AnimatePresence>
            <div>
              <GroupLabel id={ids("l-privacy")}>Who can see it</GroupLabel>
              <OptionCards value={draft.privacy} onChange={(v) => set("privacy", v)} options={PRIVACY} labelledBy={ids("l-privacy")} />
            </div>
          </Section>

          <section className="card overflow-hidden">
            <button
              type="button"
              onClick={() => setMoreOpen((o) => !o)}
              aria-expanded={moreOpen}
              aria-controls={ids("more")}
              className="flex min-h-14 w-full items-center justify-between gap-3 px-4 py-3 text-left hover:bg-accent-soft/40 sm:px-5"
            >
              <span>
                <span className="block font-display text-[1.0625rem] font-bold tracking-[-0.015em] text-ink">More options</span>
                <span className="block text-[0.8125rem] text-muted">Photo proof, notes, streaks, dates</span>
              </span>
              <ChevronDown size={20} className={cn("shrink-0 text-muted transition-transform duration-200", moreOpen && "rotate-180")} aria-hidden />
            </button>
            <AnimatePresence initial={false}>
              {moreOpen && (
                <motion.div id={ids("more")} initial={{ height: 0, opacity: 0 }} animate={{ height: "auto", opacity: 1 }} exit={{ height: 0, opacity: 0 }} transition={{ duration: 0.22, ease: [0.22, 1, 0.36, 1] }} className="overflow-hidden">
                  <div className="space-y-5 border-t border-line px-4 pb-5 pt-4 sm:px-5">
                    <div>
                      <GroupLabel id={ids("l-proof")}>Photo proof</GroupLabel>
                      <OptionCards value={draft.proof} onChange={(v) => set("proof", v)} options={PROOF} labelledBy={ids("l-proof")} />
                    </div>
                    <div className="divide-y divide-line">
                      <SwitchRow label="Optional habit" detail="Optional — doesn't affect your consistency." checked={draft.optional} onChange={(v) => set("optional", v)} />
                      <SwitchRow label="Notes on check-ins" detail="Jot a line about how it went." checked={draft.notesEnabled} onChange={(v) => set("notesEnabled", v)} />
                      <SwitchRow
                        label="Show streak"
                        detail={state.settings.showStreaks ? "Streaks are a bonus. Consistency is what we track." : "Streaks are hidden everywhere in Settings right now."}
                        checked={draft.showStreak}
                        onChange={(v) => set("showStreak", v)}
                      />
                    </div>
                    <div className="grid gap-4 sm:grid-cols-2">
                      <Field label="Start date" htmlFor={ids("startDate")}>
                        <TextInput id={ids("startDate")} type="date" value={draft.startDate} onChange={(e) => e.target.value && set("startDate", e.target.value)} />
                      </Field>
                      <Field label="Target date" htmlFor={ids("targetDate")} optional error={show("targetDate") ? errors.targetDate : undefined} hint="Handy for challenges with a finish line.">
                        <div className="flex gap-1.5">
                          <TextInput
                            id={ids("targetDate")}
                            type="date"
                            value={draft.targetDate ?? ""}
                            min={draft.startDate}
                            onChange={(e) => set("targetDate", e.target.value || undefined)}
                            invalid={Boolean(show("targetDate"))}
                          />
                          {draft.targetDate && (
                            <button type="button" onClick={() => set("targetDate", undefined)} aria-label="Clear target date" className="grid size-12 shrink-0 place-items-center rounded-[13px] text-muted hover:bg-accent-soft hover:text-accent">
                              <Trash2 size={17} aria-hidden />
                            </button>
                          )}
                        </div>
                      </Field>
                    </div>
                  </div>
                </motion.div>
              )}
            </AnimatePresence>
          </section>

          <div className="sticky bottom-[calc(4.25rem+env(safe-area-inset-bottom)+0.5rem)] z-30 md:bottom-4">
            <div className="flex items-center gap-2 rounded-[18px] border border-line bg-cream/95 p-2 shadow-[var(--shadow-lift)] backdrop-blur-[2px]">
              <p className="hidden min-w-0 flex-1 truncate pl-2 text-sm text-muted sm:block" aria-live="polite">
                {submitted && Object.keys(errors).length > 0 ? "A couple of things need a look." : dirty ? "Unsaved changes" : editing ? "No changes yet" : "Looking good"}
              </p>
              <Button variant="secondary" onClick={cancel} className="flex-1 sm:flex-none">
                Cancel
              </Button>
              <Button type="submit" className="flex-[2] sm:flex-none" icon={<Check size={18} aria-hidden />}>
                {editing ? "Save changes" : "Add habit"}
              </Button>
            </div>
          </div>
        </div>
      </form>
      <ConfirmationDialog
        open={confirmLeave}
        onClose={() => setConfirmLeave(false)}
        onConfirm={leave}
        title="Leave without saving?"
        body={editing ? "Your edits to this habit won't be kept." : "This habit hasn't been added yet. You can always start it again later."}
        confirmLabel="Discard changes"
        cancelLabel="Keep editing"
        tone="danger"
      />
    </>
  );
}
