"use client";

import { AtSign } from "lucide-react";
import { useState } from "react";
import { Avatar } from "@/components/avatar/Avatar";
import { Button } from "@/components/ui/Button";
import { Chip, Field, TextInput } from "@/components/ui/controls";
import { useDispatch, useMe } from "@/lib/store/provider";
import { StepShell } from "../StepShell";

const PRONOUNS = ["she/her", "he/him", "they/them"];
const CUSTOM = "custom";

export function suggestHandle(name: string): string {
  return name
    .normalize("NFD")
    .replace(/[̀-ͯ]/g, "")
    .toLowerCase()
    .trim()
    .replace(/\s+/g, ".")
    .replace(/[^a-z0-9._]/g, "")
    .replace(/\.{2,}/g, ".")
    .replace(/^\.|\.$/g, "")
    .slice(0, 24);
}

function validateName(name: string) {
  const n = name.trim();
  if (n.length < 2) return "Your name needs at least 2 characters.";
  if (n.length > 40) return "Keep it under 40 characters.";
  return undefined;
}

function validateHandle(h: string) {
  if (h.length < 3) return "Handles need at least 3 characters.";
  if (h.length > 24) return "Handles can be up to 24 characters.";
  if (!/^[a-z0-9._]+$/.test(h)) return "Use lowercase letters, numbers, dots or underscores.";
  return undefined;
}

export function NameStep({ onNext }: { onNext: () => void }) {
  const dispatch = useDispatch();
  const me = useMe();
  const initialPreset = me.pronouns && PRONOUNS.includes(me.pronouns) ? me.pronouns : me.pronouns ? CUSTOM : "";
  const [name, setName] = useState(me.name);
  const [handle, setHandle] = useState(me.handle);
  const [handleTouched, setHandleTouched] = useState(false);
  const [pronounChoice, setPronounChoice] = useState(initialPreset);
  const [customPronouns, setCustomPronouns] = useState(initialPreset === CUSTOM ? (me.pronouns ?? "") : "");
  const [attempted, setAttempted] = useState(false);

  const nameError = attempted ? validateName(name) : undefined;
  const handleError = attempted ? validateHandle(handle) : undefined;
  const pronouns = pronounChoice === CUSTOM ? customPronouns.trim() : pronounChoice;

  const onName = (v: string) => {
    setName(v);
    if (!handleTouched) setHandle(suggestHandle(v));
  };

  const submit = () => {
    setAttempted(true);
    if (validateName(name) || validateHandle(handle)) return;
    dispatch({ type: "profile/update", patch: { name: name.trim(), handle, pronouns } });
    onNext();
  };

  return (
    <StepShell
      eyebrow="About you"
      title="What should friends call you?"
      description="This is how you'll show up in shared habits, groups and recaps."
      onSubmit={submit}
      footer={
        <Button type="submit" size="lg" block>
          Continue
        </Button>
      }
    >
      <div className="space-y-5">
        <Field label="Display name" htmlFor="ob-name" error={nameError} hint="2–40 characters. First name is perfect.">
          <TextInput id="ob-name" autoComplete="nickname" value={name} onChange={(e) => onName(e.target.value)} invalid={!!nameError} maxLength={40} />
        </Field>

        <Field label="Handle" htmlFor="ob-handle" error={handleError} hint={handleTouched ? "Lowercase letters, numbers, dots and underscores." : "Suggested from your name. Change it if you like."}>
          <div className="relative">
            <AtSign size={17} className="pointer-events-none absolute left-3.5 top-1/2 -translate-y-1/2 text-faint" aria-hidden />
            <TextInput
              id="ob-handle"
              autoCapitalize="none"
              autoCorrect="off"
              spellCheck={false}
              value={handle}
              onChange={(e) => {
                setHandleTouched(true);
                setHandle(e.target.value.toLowerCase().replace(/\s/g, ""));
              }}
              invalid={!!handleError}
              maxLength={30}
              className="pl-10"
            />
          </div>
        </Field>

        <fieldset>
          <legend className="mb-2 flex w-full items-baseline justify-between font-display text-sm font-semibold text-ink">
            <span>Pronouns</span>
            <span className="text-xs font-medium text-faint">Optional</span>
          </legend>
          <div className="flex flex-wrap gap-2">
            {[...PRONOUNS, CUSTOM].map((p) => (
              <Chip key={p} selected={pronounChoice === p} onClick={() => setPronounChoice((cur) => (cur === p ? "" : p))}>
                {p === CUSTOM ? "Custom" : p}
              </Chip>
            ))}
          </div>
          {pronounChoice === CUSTOM && (
            <div className="mt-3">
              <label htmlFor="ob-pronouns" className="sr-only">
                Custom pronouns
              </label>
              <TextInput id="ob-pronouns" placeholder="e.g. xe/xem" value={customPronouns} onChange={(e) => setCustomPronouns(e.target.value)} maxLength={24} />
            </div>
          )}
        </fieldset>

        <div className="relative mt-2 rounded-[var(--radius-card)] border border-dashed border-line-strong bg-cream/70 p-4" aria-live="polite">
          <p className="eyebrow mb-3">Preview</p>
          <div className="flex items-center gap-3">
            <Avatar user={{ name: name || "You", avatar: me.avatar }} size={48} />
            <div className="min-w-0">
              <p className="truncate font-display text-base font-bold text-ink">{name.trim() || "Your name"}</p>
              <p className="truncate text-sm text-muted">
                @{handle || "handle"}
                {pronouns && ` · ${pronouns}`}
              </p>
            </div>
          </div>
        </div>
      </div>
    </StepShell>
  );
}
