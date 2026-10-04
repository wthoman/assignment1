"use client";

import { useState, type FormEvent } from "react";
import { BottomSheet } from "@/components/ui/BottomSheet";
import { Button } from "@/components/ui/Button";
import { CharCount, Field, TextArea, TextInput } from "@/components/ui/controls";
import { useToast } from "@/components/ui/Toast";
import { useAppState, useDispatch, useMe } from "@/lib/store/provider";

interface Draft {
  name: string;
  handle: string;
  bio: string;
  pronouns: string;
}

type Errors = Partial<Record<keyof Draft, string>>;

export const PROFILE_LIMITS = { nameMin: 2, nameMax: 40, handleMin: 3, handleMax: 24, bio: 160, pronouns: 24 } as const;

export function validateProfile(d: Draft, takenHandles: string[] = []): Errors {
  const e: Errors = {};
  const name = d.name.trim();
  if (!name) e.name = "Please add a display name.";
  else if (name.length < PROFILE_LIMITS.nameMin) e.name = `Names need at least ${PROFILE_LIMITS.nameMin} characters.`;
  else if (name.length > PROFILE_LIMITS.nameMax) e.name = `Keep it to ${PROFILE_LIMITS.nameMax} characters or fewer.`;

  if (d.handle.length < PROFILE_LIMITS.handleMin) e.handle = `Handles need at least ${PROFILE_LIMITS.handleMin} characters.`;
  else if (d.handle.length > PROFILE_LIMITS.handleMax) e.handle = `Keep handles to ${PROFILE_LIMITS.handleMax} characters or fewer.`;
  else if (!/^[a-z0-9._]+$/.test(d.handle)) e.handle = "Use only lowercase letters, numbers, dots and underscores.";
  else if (takenHandles.includes(d.handle)) e.handle = "That handle is already taken.";

  if (d.bio.length > PROFILE_LIMITS.bio) e.bio = `Bios can be up to ${PROFILE_LIMITS.bio} characters. Trim ${d.bio.length - PROFILE_LIMITS.bio}.`;
  if (d.pronouns.trim().length > PROFILE_LIMITS.pronouns) e.pronouns = `Keep pronouns to ${PROFILE_LIMITS.pronouns} characters.`;
  return e;
}

const FORM_ID = "edit-profile-form";

/** Edit-profile sheet. Remount (via `key`) each time it opens to start from saved values. */
export function EditProfileSheet({ open, onClose }: { open: boolean; onClose: () => void }) {
  const me = useMe();
  const state = useAppState();
  const dispatch = useDispatch();
  const toast = useToast();
  const [draft, setDraft] = useState<Draft>({ name: me.name, handle: me.handle, bio: me.bio, pronouns: me.pronouns ?? "" });
  const [touched, setTouched] = useState<Partial<Record<keyof Draft, boolean>>>({});
  const [submitted, setSubmitted] = useState(false);

  const taken = Object.values(state.users)
    .filter((u) => u.id !== me.id)
    .map((u) => u.handle);
  const errors = validateProfile(draft, taken);
  const show = (k: keyof Draft) => (submitted || touched[k] ? errors[k] : undefined);
  const set = (k: keyof Draft, v: string) => setDraft((d) => ({ ...d, [k]: v }));
  const blur = (k: keyof Draft) => setTouched((t) => ({ ...t, [k]: true }));

  const submit = (e: FormEvent) => {
    e.preventDefault();
    setSubmitted(true);
    const first = (Object.keys(errors) as (keyof Draft)[])[0];
    if (first) {
      document.getElementById(`profile-${first}`)?.focus();
      return;
    }
    dispatch({ type: "profile/update", patch: { name: draft.name.trim(), handle: draft.handle, bio: draft.bio.trim(), pronouns: draft.pronouns.trim() } });
    toast({ title: "Profile updated", body: "Looking sharp.", motif: "pencil" });
    onClose();
  };

  return (
    <BottomSheet
      open={open}
      onClose={onClose}
      title="Edit profile"
      description="This is what friends see on your page."
      footer={
        <div className="flex gap-2">
          <Button variant="secondary" block onClick={onClose}>
            Cancel
          </Button>
          <Button type="submit" form={FORM_ID} block>
            Save changes
          </Button>
        </div>
      }
    >
      <form id={FORM_ID} noValidate onSubmit={submit} className="space-y-4">
        <Field label="Display name" htmlFor="profile-name" error={show("name")} hint="2–40 characters.">
          <TextInput id="profile-name" data-autofocus value={draft.name} onChange={(e) => set("name", e.target.value)} onBlur={() => blur("name")} invalid={Boolean(show("name"))} autoComplete="name" maxLength={60} required />
        </Field>
        <Field label="Handle" htmlFor="profile-handle" error={show("handle")} hint="3–24 characters: a–z, 0–9, dots and underscores.">
          <div className="relative">
            <span className="pointer-events-none absolute left-3.5 top-1/2 -translate-y-1/2 text-[0.9375rem] text-faint" aria-hidden>
              @
            </span>
            <TextInput
              id="profile-handle"
              value={draft.handle}
              onChange={(e) => set("handle", e.target.value.toLowerCase().replace(/\s/g, ""))}
              onBlur={() => blur("handle")}
              invalid={Boolean(show("handle"))}
              autoCapitalize="none"
              autoCorrect="off"
              spellCheck={false}
              maxLength={40}
              className="pl-8"
              required
            />
          </div>
        </Field>
        <Field label="Pronouns" htmlFor="profile-pronouns" optional error={show("pronouns")} hint="For example: she/her, he/him, they/them.">
          <TextInput id="profile-pronouns" value={draft.pronouns} onChange={(e) => set("pronouns", e.target.value)} onBlur={() => blur("pronouns")} invalid={Boolean(show("pronouns"))} maxLength={40} />
        </Field>
        <div className="space-y-1.5">
          <Field label="Bio" htmlFor="profile-bio" optional error={show("bio")}>
            <TextArea id="profile-bio" value={draft.bio} onChange={(e) => set("bio", e.target.value)} onBlur={() => blur("bio")} invalid={Boolean(show("bio"))} aria-describedby="profile-bio-count" maxLength={220} rows={3} />
          </Field>
          <p id="profile-bio-count" className="flex justify-end">
            <CharCount value={draft.bio} max={PROFILE_LIMITS.bio} />
          </p>
        </div>
      </form>
    </BottomSheet>
  );
}
