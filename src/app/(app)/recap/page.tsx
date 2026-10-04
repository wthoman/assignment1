"use client";

import { ChevronRight, Play, Vote } from "lucide-react";
import Link from "next/link";
import { useMemo, useState } from "react";
import { FriendAvatarStack } from "@/components/avatar/FriendAvatarStack";
import { AwardRibbon, Spotlights } from "@/components/recap/RecapSlide";
import { buildSlides, weekLabel } from "@/components/recap/slides";
import { SuperlativeCard } from "@/components/recap/SuperlativeCard";
import { Page } from "@/components/shell/Page";
import { BottomSheet } from "@/components/ui/BottomSheet";
import { ButtonLink } from "@/components/ui/Button";
import { Segmented } from "@/components/ui/controls";
import { EmptyState, HandNote, SectionHeading, Tape } from "@/components/ui/misc";
import { Stamp } from "@/components/ui/Stamp";
import { BRAND } from "@/lib/brand";
import { cn } from "@/lib/cn";
import { addDays, fromISODate } from "@/lib/dates";
import { useToday } from "@/lib/hooks";
import { buildRecap } from "@/lib/selectors/recap";
import { useAppState, useDispatch } from "@/lib/store/provider";
import type { PastRecap, Visibility } from "@/lib/types";

const TICKET_MASK =
  "radial-gradient(circle at 0 50%, transparent 11px, #000 11.5px) left / 51% 100% no-repeat, radial-gradient(circle at 100% 50%, transparent 11px, #000 11.5px) right / 51% 100% no-repeat";

/** A ticket stub: main body on the left, tear-off stub on the right. */
function TicketStub({
  week,
  headline,
  stat,
  statLabel,
  current,
  href,
  onClick,
  label,
}: {
  week: string;
  headline: string;
  stat: string;
  statLabel: string;
  current?: boolean;
  href?: string;
  onClick?: () => void;
  label: string;
}) {
  const body = (
    <span
      className={cn(
        "relative flex min-h-[5.5rem] w-full items-stretch overflow-hidden text-left drop-shadow-[0_3px_6px_rgb(70_30_20/0.14)] transition-transform duration-150 group-hover:-translate-y-0.5 group-active:scale-[0.99]",
        current ? "bg-accent text-on-accent" : "bg-cream text-ink",
      )}
      style={{ mask: TICKET_MASK, WebkitMask: TICKET_MASK, borderRadius: 14 }}
    >
      <span className="flex min-w-0 flex-1 flex-col justify-center py-3 pl-6 pr-3">
        <span className={cn("font-display text-[0.6875rem] font-bold uppercase tracking-[0.14em]", current ? "opacity-80" : "text-accent")}>{current ? "Now showing" : "Week of"}</span>
        <span className="mt-0.5 font-display text-[1.0625rem] font-extrabold leading-tight tracking-[-0.02em]">{week}</span>
        <span className={cn("mt-0.5 truncate font-hand text-lg leading-tight", current ? "opacity-90" : "text-muted")}>{headline}</span>
      </span>
      <span aria-hidden className={cn("my-2 w-0 border-l-2 border-dashed", current ? "border-on-accent/40" : "border-line-strong")} />
      <span className="flex w-[5.5rem] shrink-0 flex-col items-center justify-center pr-3 text-center">
        {current ? <Play size={22} aria-hidden className="mb-0.5" /> : <span className="font-display text-xl font-extrabold tabular-nums tracking-[-0.03em] text-accent">{stat}</span>}
        <span className={cn("text-[0.6875rem] font-semibold", current ? "opacity-85" : "text-muted")}>{current ? "Play" : statLabel}</span>
      </span>
    </span>
  );
  return href ? (
    <Link href={href} className="group block rounded-[14px]" aria-label={label}>
      {body}
    </Link>
  ) : (
    <button type="button" onClick={onClick} className="group block w-full rounded-[14px]" aria-label={label}>
      {body}
    </button>
  );
}

function NumberTile({ value, label, note, rotate }: { value: string; label: string; note?: string; rotate: number }) {
  return (
    <div className="card min-w-0 px-3 py-3" style={{ rotate: `${rotate}deg` }}>
      <p className="truncate font-display text-[1.75rem] font-extrabold leading-none tracking-[-0.04em] text-accent tabular-nums">{value}</p>
      <p className="mt-1 text-[0.8125rem] font-semibold leading-tight text-muted">{label}</p>
      {note && <p className="mt-0.5 font-hand text-base leading-tight text-accent">{note}</p>}
    </div>
  );
}

export default function RecapPage() {
  const state = useAppState();
  const dispatch = useDispatch();
  const today = useToday();
  const recap = useMemo(() => buildRecap(state, today), [state, today]);
  const slideCount = useMemo(() => buildSlides(state, recap).length, [state, recap]);
  const [openId, setOpenId] = useState<string | null>(null);
  const [shownId, setShownId] = useState<string | null>(null);

  const rate = Math.round(recap.rate * 100);
  const delta = rate - Math.round(recap.prevRate * 100);
  const cast = recap.rankings.filter((r) => r.userId !== state.meId).map((r) => state.users[r.userId]);
  const castNames = cast.slice(0, 2).map((u) => u.name.split(" ")[0]);
  const past = state.pastRecaps.filter((p) => p.weekStart !== recap.start);
  const shown: PastRecap | undefined = past.find((p) => p.id === shownId);
  const openQuizzes = state.quizzes.filter((q) => !q.votes[state.meId]).length;
  const start = fromISODate(recap.start);

  const aside = (
    <>
      <section className="card relative overflow-hidden p-4" aria-labelledby="quiz-heading">
        <Tape className="-top-1.5 right-6" rotate={6} />
        <div className="flex items-start gap-3">
          <span className="grid size-10 shrink-0 place-items-center rounded-[12px] bg-accent-soft text-accent">
            <Vote size={20} aria-hidden />
          </span>
          <div className="min-w-0">
            <h2 id="quiz-heading" className="font-display text-[1.0625rem] font-bold tracking-[-0.015em] text-ink">
              Friend quizzes
            </h2>
            <p className="mt-0.5 text-sm leading-snug text-muted">
              Your votes feed next week&apos;s superlatives. Awards marked <span className="font-semibold text-ink">From friend votes</span> come straight from here.
            </p>
          </div>
        </div>
        <ButtonLink href="/friends/quizzes" variant="secondary" block className="mt-3" icon={<ChevronRight size={18} aria-hidden className="order-last" />}>
          {openQuizzes ? `${openQuizzes} question${openQuizzes > 1 ? "s" : ""} waiting` : "See the quizzes"}
        </ButtonLink>
      </section>

      <section className="card p-4" aria-labelledby="vis-heading">
        <h2 id="vis-heading" className="font-display text-[1.0625rem] font-bold tracking-[-0.015em] text-ink">
          Who sees your recap
        </h2>
        <p className="mt-0.5 text-sm text-muted">Friends see your highlights and awards, never your private habits.</p>
        <Segmented<Visibility>
          label="Recap visibility"
          size="sm"
          className="mt-3"
          value={state.settings.recapVisibility}
          onChange={(v) => dispatch({ type: "settings/update", patch: { recapVisibility: v } })}
          options={[
            { value: "private", label: "Only me" },
            { value: "friends", label: "Friends" },
            { value: "groups", label: "Groups" },
          ]}
        />
      </section>
    </>
  );

  return (
    <Page title="Recap" eyebrow="Every Sunday" aside={aside}>
      {/* Poster */}
      <section aria-labelledby="poster-heading" className="@container relative isolate overflow-hidden rounded-[24px] border border-line-strong bg-cream px-5 pb-6 pt-9 shadow-[var(--shadow-lift)] sm:px-7">
        <Spotlights />
        <span
          aria-hidden
          className="pointer-events-none absolute inset-x-0 top-0 h-6"
          style={{ background: "radial-gradient(circle at 50% 0, var(--accent) 12px, transparent 12.5px) 0 0 / 24px 20px repeat-x" }}
        />
        <span className="pointer-events-none absolute right-4 top-8 sm:right-6" aria-hidden>
          <Stamp variant="date" text={`${start.getMonth() + 1}/${start.getDate()}`} size={70} rotate={12} />
        </span>
        <div className="relative">
          <p className="font-display text-[0.6875rem] font-bold uppercase tracking-[0.18em] text-muted">{BRAND.name} presents</p>
          <h2 id="poster-heading" className="mt-2 max-w-[11ch] font-display text-[clamp(2.3rem,12cqw,4.25rem)] font-extrabold leading-[0.86] tracking-[-0.055em] text-accent">
            This week&apos;s recap is ready.
          </h2>
          <AwardRibbon className="mt-4">Week of {weekLabel(recap.start, recap.end)}</AwardRibbon>
          <div className="mt-4 flex flex-wrap items-center gap-x-3 gap-y-2">
            {cast.length > 0 && <FriendAvatarStack users={cast} size={30} max={4} label={`Featuring ${cast.map((u) => u.name.split(" ")[0]).join(", ")}`} />}
            <HandNote rotate={-2} className="text-lg">
              starring you{castNames.length ? `, ${castNames.join(", ")}` : ""}
              {cast.length > 2 ? ` & ${cast.length - 2} more` : ""}
            </HandNote>
          </div>
          <div className="mt-6 flex flex-wrap items-center gap-3">
            <ButtonLink href="/recap/play" size="lg" icon={<Play size={20} aria-hidden fill="currentColor" />} className="px-6">
              Play recap
            </ButtonLink>
            <p className="text-sm text-muted">
              {slideCount} cards · about {Math.max(1, Math.round((slideCount * 6) / 60))} min
            </p>
          </div>
        </div>
      </section>

      {/* Quick numbers */}
      <section aria-label="This week in numbers" className="mt-6 grid grid-cols-3 gap-2 sm:gap-3">
        <NumberTile value={String(recap.completed)} label="check-ins" rotate={-1} />
        <NumberTile value={`${rate}%`} label="consistency" note={delta > 0 ? `+${delta} on last week` : delta < 0 ? "still showed up" : "steady"} rotate={0.8} />
        <NumberTile value={recap.strongestDay.slice(0, 3)} label="strongest day" note={`${recap.strongestDayCount} done`} rotate={-0.6} />
      </section>

      {/* Superlatives */}
      <section aria-labelledby="sup-heading" className="mt-8">
        <SectionHeading id="sup-heading" title="This week's superlatives" count={recap.superlatives.length} hand="the awards" />
        <p className="mt-1 text-sm text-muted">Earned from what your circle actually did, plus a few votes from friend quizzes.</p>
        {recap.superlatives.length ? (
          <ul className="mt-3 grid gap-2.5 sm:grid-cols-2 lg:grid-cols-1 xl:grid-cols-2">
            {recap.superlatives.map((s) => (
              <li key={s.id}>
                <SuperlativeCard superlative={s} variant="compact" className="h-full" />
              </li>
            ))}
          </ul>
        ) : (
          <EmptyState compact className="mt-3" title="No awards this week" body="Superlatives appear once your circle has a week of check-ins and quiz votes." mood="sleepy" />
        )}
      </section>

      {/* Past recaps */}
      <section aria-labelledby="past-heading" className="mt-8">
        <SectionHeading id="past-heading" title="Ticket stubs" hand="past weeks" />
        <ul className="mt-3 space-y-2.5">
          <li>
            <TicketStub current href="/recap/play" week={weekLabel(recap.start, recap.end)} headline={`${recap.completed} check-ins, ${rate}%`} stat="" statLabel="" label={`Play this week's recap, ${weekLabel(recap.start, recap.end)}`} />
          </li>
          {past.map((p) => (
            <li key={p.id}>
              <TicketStub
                week={weekLabel(p.weekStart, addDays(p.weekStart, 6))}
                headline={p.headline}
                stat={`${p.consistency}%`}
                statLabel="consistency"
                label={`Week of ${weekLabel(p.weekStart, addDays(p.weekStart, 6))}: ${p.headline}. Open summary`}
                onClick={() => {
                  setOpenId(p.id);
                  setShownId(p.id);
                }}
              />
            </li>
          ))}
        </ul>
      </section>

      <BottomSheet
        open={Boolean(openId)}
        onClose={() => setOpenId(null)}
        title={shown ? `Week of ${weekLabel(shown.weekStart, addDays(shown.weekStart, 6))}` : "Past recap"}
        description="A summary from your ticket stubs."
        size="sm"
      >
        {shown && (
          <div className="relative">
            <p className="font-hand text-2xl leading-tight text-accent">“{shown.headline}”</p>
            <dl className="mt-4 grid grid-cols-2 gap-2">
              <div className="flex flex-col-reverse rounded-[14px] border border-line bg-paper/60 p-3">
                <dt className="text-sm font-semibold text-muted">check-ins</dt>
                <dd className="font-display text-3xl font-extrabold tracking-[-0.04em] text-accent tabular-nums">{shown.completions}</dd>
              </div>
              <div className="flex flex-col-reverse rounded-[14px] border border-line bg-paper/60 p-3">
                <dt className="text-sm font-semibold text-muted">consistency</dt>
                <dd className="font-display text-3xl font-extrabold tracking-[-0.04em] text-accent tabular-nums">{shown.consistency}%</dd>
              </div>
            </dl>
            <div className="mt-4 flex flex-wrap items-center gap-2">
              <span className="text-sm font-semibold text-muted">Your award:</span>
              <AwardRibbon>{shown.superlative}</AwardRibbon>
            </div>
            <p className="mt-4 text-[0.8125rem] text-muted">Full replays are kept for the latest week. Past weeks live on as stubs.</p>
          </div>
        )}
      </BottomSheet>
    </Page>
  );
}
