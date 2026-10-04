"use client";

import { BellRing, HeartHandshake, PartyPopper, Send } from "lucide-react";
import { useId, useState } from "react";
import { Avatar } from "@/components/avatar/Avatar";
import { IllustrationTile } from "@/components/illustrations/Illustration";
import { BottomSheet } from "@/components/ui/BottomSheet";
import { Button } from "@/components/ui/Button";
import { CharCount, Field, Segmented, TextArea } from "@/components/ui/controls";
import { HandNote } from "@/components/ui/misc";
import { haptic, useToast } from "@/components/ui/Toast";
import { cn } from "@/lib/cn";
import { useAppState, useDispatch } from "@/lib/store/provider";
import type { EncouragementStyle, ID, NudgeKind } from "@/lib/types";

const MAX = 120;

const KIND_META: Record<NudgeKind, { label: string; verb: string }> = {
  nudge: { label: "Nudge", verb: "Send nudge" },
  cheer: { label: "Cheer", verb: "Send cheer" },
  comeback: { label: "Welcome back", verb: "Celebrate" },
};

/** Preset messages, tuned to the user's encouragement style. All kind, none guilt-trippy. */
export function presetMessages(kind: NudgeKind, tone: EncouragementStyle, name: string, habit?: string): string[] {
  const h = habit ? habit.toLowerCase() : "today's habit";
  const sets: Record<NudgeKind, Record<EncouragementStyle, string[]>> = {
    nudge: {
      gentle: [
        `Thinking of you! Tiny version of ${h} still counts.`,
        `No pressure, ${name}. Just a little wave from me.`,
        `Whenever you're ready. I'm rooting for you.`,
        `Five easy minutes? You've got this.`,
      ],
      cheeky: [
        `${name}. ${habit ?? "The habit"} misses you. It told me.`,
        `Psst. Future you says thanks in advance.`,
        `This is your friendly neighbourhood reminder.`,
        `Bet you can't do it before me. (Please prove me wrong.)`,
      ],
      coach: [
        `Small reps win. Go get one in, ${name}.`,
        `Show up for ten minutes. That's the whole plan.`,
        `Momentum starts now. You know the drill.`,
        `One check-in. Then rest. Let's go.`,
      ],
    },
    cheer: {
      gentle: [
        `So proud of you for showing up, ${name}.`,
        `Loved seeing this today.`,
        `Quietly consistent and it shows.`,
        `You make this look easy (I know it isn't).`,
      ],
      cheeky: [
        `Okay, show-off. Love it.`,
        `Who gave you permission to be this consistent?`,
        `Main character behaviour, ${name}.`,
        `Saving this as proof that I should get up too.`,
      ],
      coach: [
        `That's how it's done. Keep stacking.`,
        `Strong work. Same time tomorrow.`,
        `Consistency is a skill and you're training it.`,
        `Great rep, ${name}. On to the next.`,
      ],
    },
    comeback: {
      gentle: [
        `Welcome back, ${name}! So glad you're here.`,
        `Coming back is the hardest part, and you did it.`,
        `Missed days happen. Showing up again is the skill.`,
        `Look who's back. Made my day.`,
      ],
      cheeky: [
        `THE RETURN. Cinema.`,
        `Plot twist: ${name} is back and better.`,
        `${habit ?? "The habit"} called. It's thrilled.`,
        `Comeback season has officially started.`,
      ],
      coach: [
        `Back in it. That's what matters. Keep rolling.`,
        `Restart logged. Now build on it.`,
        `Good reset, ${name}. One day at a time.`,
        `Day one again is still a day one. Let's go.`,
      ],
    },
  };
  return sets[kind][tone];
}

/**
 * Bottom sheet to send a friend an encouraging nudge, cheer, or comeback celebration,
 * optionally about one of their habits.
 */
export function ReminderComposer({ open, onClose, toId, habitId, kind: initialKind = "nudge" }: { open: boolean; onClose: () => void; toId: ID; habitId?: ID; kind?: NudgeKind }) {
  // Remount the inner form each time the sheet opens so drafts reset cleanly.
  return (
    <BottomSheet open={open} onClose={onClose} title="Send some encouragement" description="Short, kind, and easy to ignore if they're busy." size="md">
      {open && <ComposerBody onClose={onClose} toId={toId} habitId={habitId} initialKind={initialKind} />}
    </BottomSheet>
  );
}

function ComposerBody({ onClose, toId, habitId, initialKind }: { onClose: () => void; toId: ID; habitId?: ID; initialKind: NudgeKind }) {
  const state = useAppState();
  const dispatch = useDispatch();
  const toast = useToast();
  const fieldId = useId();
  const [kind, setKind] = useState<NudgeKind>(initialKind);
  const [preset, setPreset] = useState<number | null>(0);
  const [custom, setCustom] = useState("");
  const [touched, setTouched] = useState(false);

  const friend = state.users[toId];
  const habit = habitId ? state.habits.find((h) => h.id === habitId) : undefined;
  if (!friend) return <p className="text-sm text-muted">This person isn&apos;t available right now.</p>;
  const name = friend.name.split(" ")[0];
  const presets = presetMessages(kind, state.settings.encouragement, name, habit?.name);

  const message = preset !== null ? presets[preset] : custom.trim();
  const error = preset === null && touched ? (!custom.trim() ? "Write a short message, or pick one above." : custom.length > MAX ? `Keep it under ${MAX} characters.` : undefined) : undefined;
  const valid = Boolean(message) && message.length <= MAX;

  const send = () => {
    setTouched(true);
    if (!valid) return;
    dispatch({ type: "social/nudge", toId, habitId, kind, message });
    haptic(state.settings.haptics);
    toast({ title: kind === "comeback" ? `Celebrated ${name}'s comeback` : kind === "cheer" ? `Cheer sent to ${name}` : `Nudge sent to ${name}`, body: `“${message}”`, motif: kind === "comeback" ? "sun" : kind === "cheer" ? "heart" : "alarm" });
    onClose();
  };

  return (
    <div className="space-y-5">
      <div className="flex items-center gap-3 rounded-[16px] border border-line bg-paper/60 p-3">
        <Avatar user={friend} size={48} />
        <div className="min-w-0 flex-1">
          <p className="font-display font-bold text-ink">To {friend.name}</p>
          {habit ? (
            <p className="flex items-center gap-1.5 truncate text-sm text-muted">
              <IllustrationTile kind={habit.icon} tint={habit.tint} size={22} />
              <span className="truncate">About “{habit.name}”</span>
            </p>
          ) : (
            <p className="text-sm text-muted">Just because</p>
          )}
        </div>
        <HandNote className="hidden text-base sm:inline-block">be kind!</HandNote>
      </div>

      <Segmented
        label="Message type"
        value={kind}
        onChange={(v) => {
          setKind(v);
          if (preset !== null) setPreset(0);
        }}
        options={[
          { value: "nudge", label: KIND_META.nudge.label, icon: <BellRing size={15} aria-hidden /> },
          { value: "cheer", label: KIND_META.cheer.label, icon: <PartyPopper size={15} aria-hidden /> },
          { value: "comeback", label: "Comeback", icon: <HeartHandshake size={15} aria-hidden /> },
        ]}
      />

      <fieldset>
        <legend className="mb-2 font-display text-sm font-semibold text-ink">
          Pick a message <span className="font-sans text-xs font-medium capitalize text-faint">· {state.settings.encouragement} tone</span>
        </legend>
        <div className="flex flex-col gap-2">
          {presets.map((p, i) => {
            const active = preset === i;
            return (
              <button
                key={p}
                type="button"
                aria-pressed={active}
                onClick={() => setPreset(i)}
                className={cn(
                  "min-h-11 rounded-[13px] border px-3.5 py-2.5 text-left text-[0.9375rem] leading-snug transition-colors",
                  active ? "border-accent bg-accent-soft text-ink" : "border-line bg-cream text-ink hover:bg-accent-soft/50",
                )}
              >
                {p}
              </button>
            );
          })}
          <button
            type="button"
            aria-pressed={preset === null}
            onClick={() => setPreset(null)}
            className={cn(
              "min-h-11 rounded-[13px] border border-dashed px-3.5 py-2.5 text-left font-display text-sm font-semibold transition-colors",
              preset === null ? "border-accent bg-accent-soft text-accent" : "border-line-strong text-muted hover:text-accent",
            )}
          >
            Write my own…
          </button>
        </div>
      </fieldset>

      {preset === null && (
        <Field label="Your message" htmlFor={fieldId} error={error} hint="Encouraging and short works best.">
          <TextArea
            id={fieldId}
            value={custom}
            onChange={(e) => setCustom(e.target.value)}
            onBlur={() => setTouched(true)}
            maxLength={MAX + 20}
            placeholder={`Something nice for ${name}…`}
            invalid={Boolean(error)}
            data-autofocus
          />
          <div className="flex justify-end">
            <CharCount value={custom} max={MAX} />
          </div>
        </Field>
      )}

      <div className="flex flex-col-reverse gap-2 sm:flex-row sm:justify-end">
        <Button variant="secondary" onClick={onClose}>
          Not now
        </Button>
        <Button onClick={send} disabled={preset !== null ? false : touched && !valid} icon={<Send size={17} aria-hidden />}>
          {KIND_META[kind].verb}
        </Button>
      </div>
      <p className="text-center text-xs text-faint">Friends can mute reminders anytime in their own settings.</p>
    </div>
  );
}
