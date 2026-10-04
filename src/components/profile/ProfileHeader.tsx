"use client";

import { Palette, Pencil } from "lucide-react";
import { useState } from "react";
import { AvatarArt } from "@/components/avatar/Avatar";
import { Button, ButtonLink } from "@/components/ui/Button";
import { Badge, HandNote, Tape } from "@/components/ui/misc";
import { formatDate } from "@/lib/dates";
import { useAppState, useMe } from "@/lib/store/provider";
import type { Settings } from "@/lib/types";
import { EditProfileSheet } from "./EditProfileSheet";

export const VISIBILITY_LABEL: Record<Settings["profileVisibility"], string> = {
  private: "Only you",
  friends: "Friends",
  groups: "Groups",
  public: "Everyone",
};

export function ProfileHeader() {
  const me = useMe();
  const { settings } = useAppState();
  const [editing, setEditing] = useState(false);
  const [editKey, setEditKey] = useState(0);

  return (
    <section aria-labelledby="profile-name" className="card relative px-5 pb-5 pt-6">
      <Tape className="-top-2 right-8" rotate={6} />
      <div className="flex flex-col items-center text-center sm:flex-row sm:items-center sm:gap-6 sm:text-left">
        <div className="relative shrink-0 pb-2 pr-3">
          <AvatarArt config={me.avatar} size={124} title={`${me.name}'s avatar`} />
          <HandNote className="absolute -bottom-1 -left-4 text-base" rotate={-8}>
            that&apos;s me
          </HandNote>
        </div>
        <div className="mt-3 min-w-0 flex-1 sm:mt-0">
          <h2 id="profile-name" className="break-words font-display text-[1.75rem] font-extrabold leading-tight tracking-[-0.035em] text-ink">
            {me.name}
          </h2>
          <p className="mt-0.5 text-sm text-muted">
            @{me.handle}
            {me.pronouns ? <> · {me.pronouns}</> : null}
          </p>
          {me.bio ? <p className="mx-auto mt-2 max-w-md break-words text-[0.9375rem] leading-relaxed text-ink sm:mx-0">{me.bio}</p> : <p className="mt-2 text-sm text-faint">No bio yet. Add a line about what you&apos;re working on.</p>}
          <div className="mt-3 flex flex-wrap items-center justify-center gap-x-3 gap-y-1.5 text-xs text-muted sm:justify-start">
            <Badge tone="muted">Visible to {VISIBILITY_LABEL[settings.profileVisibility].toLowerCase()}</Badge>
            <span>Keeping a daybook since {formatDate(me.joinedAt, { month: "long", year: "numeric" })}</span>
          </div>
        </div>
      </div>
      <div className="mt-5 grid grid-cols-2 gap-2">
        <Button
          variant="secondary"
          icon={<Pencil size={16} aria-hidden />}
          onClick={() => {
            setEditKey((k) => k + 1);
            setEditing(true);
          }}
        >
          Edit profile
        </Button>
        <ButtonLink href="/profile/avatar" variant="soft" icon={<Palette size={16} aria-hidden />}>
          Customize avatar
        </ButtonLink>
      </div>
      <EditProfileSheet key={editKey} open={editing} onClose={() => setEditing(false)} />
    </section>
  );
}
