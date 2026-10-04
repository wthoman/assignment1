"use client";

import { Check } from "lucide-react";
import { useRouter } from "next/navigation";
import { useId, useState, type FormEvent } from "react";
import { Avatar } from "@/components/avatar/Avatar";
import { IllustrationTile, TINT_HEX } from "@/components/illustrations/Illustration";
import { Page } from "@/components/shell/Page";
import { visibleFriends } from "@/components/social/social-helpers";
import { Button } from "@/components/ui/Button";
import { CharCount, Field, TextArea, TextInput } from "@/components/ui/controls";
import { HandNote } from "@/components/ui/misc";
import { useToast } from "@/components/ui/Toast";
import { HABIT_ICONS, ILLUSTRATION_LABELS } from "@/lib/data/catalog";
import { cn } from "@/lib/cn";
import { uid } from "@/lib/random";
import { useAppState, useDispatch } from "@/lib/store/provider";
import type { ID, IllustrationKey, Tint } from "@/lib/types";

const TINTS: { value: Tint; label: string }[] = [
  { value: "burgundy", label: "Burgundy" },
  { value: "rose", label: "Rose" },
  { value: "orange", label: "Apricot" },
  { value: "gold", label: "Marigold" },
  { value: "sage", label: "Sage" },
  { value: "sky", label: "Sky" },
];

const NAME_MAX = 40;
const DESC_MAX = 140;

export default function NewGroupPage() {
  const state = useAppState();
  const dispatch = useDispatch();
  const router = useRouter();
  const toast = useToast();
  const nameId = useId();
  const descId = useId();
  const [name, setName] = useState("");
  const [description, setDescription] = useState("");
  const [icon, setIcon] = useState<IllustrationKey>("star");
  const [tint, setTint] = useState<Tint>("rose");
  const [invited, setInvited] = useState<ID[]>([]);
  const [tried, setTried] = useState(false);
  const friends = visibleFriends(state);

  const trimmed = name.trim();
  const taken = state.groups.some((g) => g.memberIds.includes(state.meId) && g.name.toLowerCase() === trimmed.toLowerCase());
  const nameError = !tried ? undefined : !trimmed ? "Give your group a name." : trimmed.length < 3 ? "At least 3 characters." : trimmed.length > NAME_MAX ? `Keep it under ${NAME_MAX} characters.` : taken ? "You already have a group with that name." : undefined;
  const descError = description.length > DESC_MAX ? `Keep it under ${DESC_MAX} characters.` : undefined;

  const submit = (e: FormEvent) => {
    e.preventDefault();
    setTried(true);
    const ok = trimmed.length >= 3 && trimmed.length <= NAME_MAX && !taken && !descError;
    if (!ok) {
      document.getElementById(nameId)?.focus();
      return;
    }
    const id = uid("g");
    dispatch({ type: "group/create", id, group: { name: trimmed, description: description.trim(), icon, tint, memberIds: invited, notify: "all" } });
    toast({ title: `${trimmed} is ready`, body: invited.length ? `${invited.length} friend${invited.length > 1 ? "s" : ""} added` : "Invite friends any time", motif: icon });
    router.push(`/groups/${id}`);
  };

  return (
    <Page title="New group" back="/groups">
      <form onSubmit={submit} noValidate className="space-y-6">
        <div className="card flex items-center gap-4 p-4" aria-hidden>
          <IllustrationTile kind={icon} tint={tint} size={64} rotate={-5} />
          <div className="min-w-0">
            <p className="truncate font-display text-xl font-extrabold text-ink">{trimmed || "Your group"}</p>
            <p className="truncate text-sm text-muted">{description.trim() || "A short line about what you're doing together"}</p>
          </div>
          <HandNote className="ml-auto hidden text-base sm:inline-block">preview</HandNote>
        </div>

        <Field label="Group name" htmlFor={nameId} error={nameError}>
          <TextInput id={nameId} value={name} onChange={(e) => setName(e.target.value)} placeholder="e.g. Library Goblins" invalid={Boolean(nameError)} maxLength={NAME_MAX + 10} autoComplete="off" />
        </Field>

        <Field label="Description" htmlFor={descId} optional error={descError}>
          <TextArea id={descId} value={description} onChange={(e) => setDescription(e.target.value)} placeholder="What are you working on together?" invalid={Boolean(descError)} maxLength={DESC_MAX + 20} className="min-h-20" />
          <div className="flex justify-end">
            <CharCount value={description} max={DESC_MAX} />
          </div>
        </Field>

        <fieldset>
          <legend className="mb-2 font-display text-sm font-semibold text-ink">Icon</legend>
          <div className="grid grid-cols-6 gap-2 sm:grid-cols-8" role="radiogroup" aria-label="Icon">
            {HABIT_ICONS.map((k) => (
              <button
                key={k}
                type="button"
                role="radio"
                aria-checked={icon === k}
                aria-label={ILLUSTRATION_LABELS[k]}
                title={ILLUSTRATION_LABELS[k]}
                onClick={() => setIcon(k)}
                className={cn("grid aspect-square min-h-11 place-items-center rounded-[14px] border-2 transition-colors", icon === k ? "border-accent" : "border-transparent hover:border-line-strong")}
              >
                <IllustrationTile kind={k} tint={icon === k ? tint : "cream"} size={40} />
              </button>
            ))}
          </div>
        </fieldset>

        <fieldset>
          <legend className="mb-2 font-display text-sm font-semibold text-ink">Colour</legend>
          <div className="flex flex-wrap gap-2" role="radiogroup" aria-label="Colour">
            {TINTS.map((t) => (
              <button
                key={t.value}
                type="button"
                role="radio"
                aria-checked={tint === t.value}
                aria-label={t.label}
                title={t.label}
                onClick={() => setTint(t.value)}
                className={cn("grid size-11 place-items-center rounded-[12px] border-2 transition-transform active:scale-95", tint === t.value ? "border-ink" : "border-line")}
                style={{ backgroundColor: t.value === "burgundy" ? "var(--accent)" : TINT_HEX[t.value] }}
              >
                {tint === t.value && <Check size={18} strokeWidth={3} className="text-[#fbf6ec] drop-shadow" aria-hidden />}
              </button>
            ))}
          </div>
        </fieldset>

        <fieldset>
          <legend className="mb-2 flex w-full items-baseline justify-between font-display text-sm font-semibold text-ink">
            Invite friends <span className="font-sans text-xs font-medium text-faint">{invited.length ? `${invited.length} selected` : "Optional"}</span>
          </legend>
          {friends.length ? (
            <ul className="grid gap-2 sm:grid-cols-2">
              {friends.map((u) => {
                const on = invited.includes(u.id);
                return (
                  <li key={u.id}>
                    <button
                      type="button"
                      aria-pressed={on}
                      onClick={() => setInvited((xs) => (on ? xs.filter((x) => x !== u.id) : [...xs, u.id]))}
                      className={cn("flex min-h-12 w-full items-center gap-3 rounded-[14px] border px-3 py-2 text-left transition-colors", on ? "border-accent bg-accent-soft" : "border-line bg-cream hover:bg-accent-soft/50")}
                    >
                      <Avatar user={u} size={34} />
                      <span className="min-w-0 flex-1 truncate text-sm font-semibold text-ink">{u.name}</span>
                      <span className={cn("grid size-6 place-items-center rounded-[7px] border", on ? "border-accent bg-accent text-on-accent" : "border-line-strong")} aria-hidden>
                        {on && <Check size={14} strokeWidth={3} />}
                      </span>
                    </button>
                  </li>
                );
              })}
            </ul>
          ) : (
            <p className="text-sm text-muted">Add friends first, or invite them once the group exists.</p>
          )}
        </fieldset>

        <div className="flex flex-col-reverse gap-2 border-t border-line pt-5 sm:flex-row sm:justify-end">
          <Button variant="secondary" onClick={() => router.push("/groups")}>
            Cancel
          </Button>
          <Button type="submit">Create group</Button>
        </div>
      </form>
    </Page>
  );
}
