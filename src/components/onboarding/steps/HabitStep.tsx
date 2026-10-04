"use client";

import { Bell } from "lucide-react";
import { useState } from "react";
import { IllustrationTile } from "@/components/illustrations/Illustration";
import { Button } from "@/components/ui/Button";
import { CharCount, Field, TextInput, Toggle } from "@/components/ui/controls";
import { Stamp } from "@/components/ui/Stamp";
import { cn } from "@/lib/cn";
import { CATEGORY_META, ILLUSTRATION_LABELS, PERSONALITIES } from "@/lib/data/catalog";
import { useToday } from "@/lib/hooks";
import { uid } from "@/lib/random";
import { useAppState, useDispatch } from "@/lib/store/provider";
import type { ClockTime, IllustrationKey, PersonalityKey, TimeOfDay } from "@/lib/types";
import { buildHabitDraft, categoryForIcon, defaultReminder, FREQUENCY_OPTIONS, parseSchedule, QUICK_ICONS, TIME_OPTIONS, type QuickFrequency } from "../habitDraft";
import { ChoiceGroup, StepShell } from "../StepShell";

const MAX = 60;

function validateName(n: string) {
  const t = n.trim();
  if (t.length < 2) return "Give your habit a name (at least 2 characters).";
  if (t.length > MAX) return `Keep it under ${MAX} characters.`;
  return undefined;
}

export function HabitStep({ personality, habitId, onCreated }: { personality: PersonalityKey; habitId: string | null; onCreated: (id: string) => void }) {
  const dispatch = useDispatch();
  const state = useAppState();
  const today = useToday();
  const suggestions = PERSONALITIES[personality].habits;
  const existing = habitId ? state.habits.find((h) => h.id === habitId) : undefined;

  const initial = existing
    ? { name: existing.name, icon: existing.icon, frequency: (existing.frequency === "custom" ? "daily" : existing.frequency) as QuickFrequency, timeOfDay: existing.timeOfDay }
    : { name: suggestions[0].name, icon: suggestions[0].icon, ...parseSchedule(suggestions[0].schedule) };

  const [name, setName] = useState(initial.name);
  const [icon, setIcon] = useState<IllustrationKey>(initial.icon);
  const [frequency, setFrequency] = useState<QuickFrequency>(initial.frequency);
  const [timeOfDay, setTimeOfDay] = useState<TimeOfDay>(initial.timeOfDay);
  const [remindersOn, setRemindersOn] = useState(existing ? existing.remindersOn : true);
  const [reminderTime, setReminderTime] = useState<ClockTime>(existing?.reminderTimes[0] ?? defaultReminder(initial.timeOfDay));
  const [attempted, setAttempted] = useState(false);

  const nameError = attempted ? validateName(name) : undefined;
  const timeError = attempted && remindersOn && !/^\d{2}:\d{2}$/.test(reminderTime) ? "Pick a reminder time." : undefined;
  const suggestionIndex = suggestions.findIndex((s) => s.name === name.trim());

  const applySuggestion = (i: number) => {
    const s = suggestions[i];
    const parsed = parseSchedule(s.schedule);
    setName(s.name);
    setIcon(s.icon);
    setFrequency(parsed.frequency);
    setTimeOfDay(parsed.timeOfDay);
    setReminderTime(defaultReminder(parsed.timeOfDay));
  };

  const onTime = (t: TimeOfDay) => {
    setTimeOfDay(t);
    setReminderTime(defaultReminder(t));
  };

  const submit = () => {
    setAttempted(true);
    if (validateName(name) || (remindersOn && !/^\d{2}:\d{2}$/.test(reminderTime))) return;
    const draft = buildHabitDraft({ name, icon, frequency, timeOfDay, remindersOn, reminderTime }, existing?.startDate ?? today);
    if (existing) {
      dispatch({ type: "habit/update", id: existing.id, patch: draft });
      onCreated(existing.id);
    } else {
      const id = uid("h");
      dispatch({ type: "habit/create", draft, id });
      onCreated(id);
    }
  };

  const tint = CATEGORY_META[categoryForIcon(icon)].tint;

  return (
    <StepShell
      eyebrow="First habit"
      title="Start with one small thing"
      description="Pick a suggestion for your type, or write your own. Tiny is good."
      onSubmit={submit}
      footer={
        <Button type="submit" size="lg" block>
          {existing ? "Save habit" : "Add habit"}
        </Button>
      }
    >
      <div className="space-y-6">
        <fieldset>
          <legend className="mb-2 font-display text-sm font-semibold text-ink">Suggested for a {PERSONALITIES[personality].name}</legend>
          <div role="radiogroup" aria-label="Suggested habits" className="space-y-2">
            {suggestions.map((s, i) => {
              const on = suggestionIndex === i;
              return (
                <button
                  key={s.name}
                  type="button"
                  role="radio"
                  aria-checked={on}
                  onClick={() => applySuggestion(i)}
                  className={cn(
                    "relative flex min-h-14 w-full items-center gap-3 rounded-[14px] border px-3 py-2.5 text-left transition-[background-color,border-color,transform] duration-150 active:scale-[0.985]",
                    on ? "border-accent bg-accent-soft" : "border-line bg-cream hover:bg-accent-soft/40",
                  )}
                >
                  <IllustrationTile kind={s.icon} tint={CATEGORY_META[categoryForIcon(s.icon)].tint} size={40} rotate={i % 2 ? 3 : -3} />
                  <span className="min-w-0 flex-1">
                    <span className={cn("block font-display text-[0.9375rem] font-semibold leading-tight", on ? "text-accent" : "text-ink")}>{s.name}</span>
                    <span className="mt-0.5 block text-[0.8125rem] text-muted">{s.schedule}</span>
                  </span>
                  {on && <Stamp size={28} animate />}
                </button>
              );
            })}
          </div>
        </fieldset>

        <div className="hand-divider" aria-hidden />

        <div>
          <Field label={suggestionIndex === -1 ? "Your habit" : "Or write your own"} htmlFor="ob-habit-name" error={nameError}>
            <div className="flex items-center gap-2.5">
              <IllustrationTile kind={icon} tint={tint} size={48} rotate={-4} />
              <TextInput id="ob-habit-name" value={name} onChange={(e) => setName(e.target.value)} invalid={!!nameError} maxLength={MAX + 10} placeholder="e.g. Stretch before bed" />
            </div>
          </Field>
          <div className="mt-1 flex justify-end">
            <CharCount value={name.trim()} max={MAX} />
          </div>
        </div>

        <fieldset>
          <legend className="mb-2 font-display text-sm font-semibold text-ink">Icon</legend>
          <div role="radiogroup" aria-label="Icon" className="grid grid-cols-6 gap-1.5">
            {QUICK_ICONS.map((k) => {
              const on = icon === k;
              return (
                <button
                  key={k}
                  type="button"
                  role="radio"
                  aria-checked={on}
                  aria-label={ILLUSTRATION_LABELS[k]}
                  title={ILLUSTRATION_LABELS[k]}
                  onClick={() => setIcon(k)}
                  className={cn(
                    "grid aspect-square min-h-11 place-items-center rounded-[12px] border transition-[background-color,border-color,transform] duration-150 active:scale-[0.94]",
                    on ? "border-accent bg-accent-soft" : "border-transparent hover:bg-accent-soft/50",
                  )}
                >
                  <IllustrationTile kind={k} tint={on ? CATEGORY_META[categoryForIcon(k)].tint : "cream"} size={36} />
                </button>
              );
            })}
          </div>
        </fieldset>

        <ChoiceGroup label="How often" value={frequency} onChange={setFrequency} className="grid-cols-2" options={FREQUENCY_OPTIONS.map((f) => ({ value: f.value, label: f.label, detail: f.detail }))} />

        <ChoiceGroup label="Time of day" value={timeOfDay} onChange={onTime} className="grid-cols-2 min-[400px]:grid-cols-4" options={TIME_OPTIONS.map((t) => ({ value: t.value, label: t.label }))} />

        <div className="card-flat space-y-3 px-4 py-3">
          <div className="flex min-h-11 items-center gap-3">
            <span className="grid size-9 shrink-0 place-items-center rounded-[11px] bg-accent-soft text-accent" aria-hidden>
              <Bell size={18} />
            </span>
            <span className="min-w-0 flex-1">
              <span className="block text-[0.9375rem] font-semibold text-ink">Reminder</span>
              <span className="block text-[0.8125rem] text-muted">{remindersOn ? "A gentle ping at this time." : "No reminder. You can add one later."}</span>
            </span>
            <Toggle checked={remindersOn} onChange={setRemindersOn} label="Reminder" />
          </div>
          {remindersOn && (
            <Field label="Remind me at" htmlFor="ob-habit-time" error={timeError}>
              <TextInput id="ob-habit-time" type="time" value={reminderTime} onChange={(e) => setReminderTime(e.target.value)} invalid={!!timeError} className="max-w-[10rem]" />
            </Field>
          )}
        </div>
      </div>
    </StepShell>
  );
}
