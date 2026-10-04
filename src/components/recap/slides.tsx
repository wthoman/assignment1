"use client";

import { motion } from "motion/react";
import type { ReactNode } from "react";
import { Avatar } from "@/components/avatar/Avatar";
import { Sticker } from "@/components/collection/Sticker";
import { IllustrationTile } from "@/components/illustrations/Illustration";
import { Mascot } from "@/components/illustrations/Mascot";
import { Stamp } from "@/components/ui/Stamp";
import { BRAND } from "@/lib/brand";
import { cn } from "@/lib/cn";
import { COLLECTIBLE_BY_ID, RARITY_META } from "@/lib/data/catalog";
import { addDays, formatDate, fromISODate, weekday, WEEKDAY_LETTER } from "@/lib/dates";
import type { RecapData } from "@/lib/selectors/recap";
import type { AppState, ID } from "@/lib/types";
import { AwardRibbon, StampedPortrait, T, type SlideTone } from "./RecapSlide";
import { SuperlativeCard } from "./SuperlativeCard";

export interface SlideContext {
  paused: boolean;
}

export interface SlideDef {
  key: string;
  /** Announced to screen readers and used as the slide's accessible name. */
  title: string;
  tone: SlideTone;
  /** Auto-advance time in ms (defaults to the player's standard duration). */
  duration?: number;
  render: (ctx: SlideContext) => ReactNode;
}

const pctOf = (n: number) => Math.round(n * 100);

function firstName(state: AppState, id: ID) {
  return id === state.meId ? "You" : state.users[id]?.name.split(" ")[0] ?? "Someone";
}

export function weekLabel(start: string, end: string) {
  const sameMonth = fromISODate(start).getMonth() === fromISODate(end).getMonth();
  return `${formatDate(start)} – ${sameMonth ? fromISODate(end).getDate() : formatDate(end)}`;
}

/* ---------- Shared bits ---------- */

function Center({ children, className }: { children: ReactNode; className?: string }) {
  return <div className={cn("flex min-h-0 flex-1 flex-col justify-center", className)}>{children}</div>;
}

/** A scalloped theatre valance across the top of a sheet. */
function Valance() {
  return (
    <span
      aria-hidden
      className="pointer-events-none absolute inset-x-0 top-0 h-7"
      style={{ background: "radial-gradient(circle at 50% 0, var(--accent) 13px, transparent 13.5px) 0 0 / 26px 22px repeat-x" }}
    />
  );
}

function StatTile({ value, label, rotate = 0 }: { value: ReactNode; label: string; rotate?: number }) {
  return (
    <div className="rounded-[14px] border border-line bg-cream px-3 py-3 shadow-[var(--shadow)]" style={{ rotate: `${rotate}deg` }}>
      <p className="font-display text-[clamp(2rem,13cqw,3.25rem)] font-extrabold leading-none tracking-[-0.05em] text-accent tabular-nums">{value}</p>
      <p className="mt-1 text-[clamp(0.75rem,3.6cqw,0.9rem)] font-semibold leading-tight text-muted">{label}</p>
    </div>
  );
}

/* ---------- Individual slides ---------- */

function TitleSlide({ recap, friends }: { recap: RecapData; friends: number }) {
  const start = fromISODate(recap.start);
  return (
    <>
      <Valance />
      <Center className="items-start">
        <p className={cn(T.hand, "text-accent")}>{BRAND.name} presents…</p>
        <h1 className="mt-2 font-display text-[clamp(2.4rem,15cqw,4.6rem)] font-extrabold leading-[0.88] tracking-[-0.055em] text-accent">
          The week
          <br />
          of {formatDate(recap.start, { month: "short" })}
          <br />
          {start.getDate()}
        </h1>
        <AwardRibbon className="mt-5">Your weekly recap</AwardRibbon>
        <p className={cn(T.body, "mt-5 max-w-[30ch] text-muted")}>
          Starring you{friends ? ` and ${friends} friend${friends > 1 ? "s" : ""}` : ""}. {recap.completed} check-ins, {recap.superlatives.length} award{recap.superlatives.length === 1 ? "" : "s"}, and one very good {recap.strongestDay}.
        </p>
      </Center>
      <span className="absolute bottom-24 right-[7cqw]" aria-hidden>
        <Stamp variant="date" text={`${start.getMonth() + 1}/${start.getDate()}`} size={84} rotate={12} animate />
      </span>
    </>
  );
}

function CompletedSlide({ recap }: { recap: RecapData }) {
  const line =
    recap.completed === 0
      ? "A quiet week. The page is still yours."
      : recap.scheduled
        ? `out of ${recap.scheduled} scheduled. Every one of them was a choice you made.`
        : "Every one of them was a choice you made.";
  return (
    <Center>
      <p className={cn(T.kicker, "opacity-80")}>This week you checked off</p>
      <p className={cn(T.huge, "-ml-[0.04em] mt-3")}>{recap.completed}</p>
      <p className={cn(T.headline, "mt-1")}>habit{recap.completed === 1 ? "" : "s"}</p>
      <p className={cn(T.body, "mt-4 max-w-[30ch] opacity-85")}>{line}</p>
      <span className="mt-6 self-start" aria-hidden>
        <Stamp variant="label" text="Logged" rotate={-8} color="var(--on-accent)" animate className="text-[clamp(0.8rem,4cqw,1rem)]!" />
      </span>
    </Center>
  );
}

function ConsistencySlide({ recap }: { recap: RecapData }) {
  const now = pctOf(recap.rate);
  const prev = pctOf(recap.prevRate);
  const delta = now - prev;
  const line =
    delta > 0
      ? `Up ${delta} point${delta === 1 ? "" : "s"} on last week. Momentum looks good on you.`
      : delta < 0
        ? `${Math.abs(delta)} down from last week, and you still kept showing up. Weeks wobble; the habit is still here.`
        : "Right on par with last week. Steady is a superpower.";
  return (
    <Center>
      <p className={cn(T.kicker, "text-accent")}>Overall consistency</p>
      <p className="mt-3 font-display text-[clamp(4rem,31cqw,8.25rem)] font-extrabold leading-[0.82] tracking-[-0.06em] text-accent tabular-nums">
        {now}
        <span className="text-[0.5em] tracking-[-0.02em]">%</span>
      </p>
      <p className={cn(T.body, "mt-4 max-w-[32ch] text-ink")}>{line}</p>
      <div className="mt-6 space-y-2.5" aria-hidden>
        {[
          { label: "Last week", value: prev, strong: false },
          { label: "This week", value: now, strong: true },
        ].map((b) => (
          <div key={b.label} className="flex items-center gap-3">
            <span className="w-[22cqw] shrink-0 text-[clamp(0.75rem,3.6cqw,0.9rem)] font-semibold text-muted">{b.label}</span>
            <span className="relative h-4 flex-1 overflow-hidden rounded-[5px] border border-line bg-paper-deep/60">
              <motion.span
                className={cn("absolute inset-y-0 left-0 w-full origin-left", b.strong ? "bg-accent" : "bg-line-strong")}
                initial={{ scaleX: 0 }}
                animate={{ scaleX: b.value / 100 }}
                transition={{ duration: 0.9, delay: b.strong ? 0.45 : 0.2, ease: [0.22, 1, 0.36, 1] }}
              />
            </span>
            <span className="w-10 shrink-0 text-right font-display text-sm font-bold tabular-nums">{b.value}%</span>
          </div>
        ))}
      </div>
    </Center>
  );
}

function StrongestDaySlide({ recap }: { recap: RecapData }) {
  const max = Math.max(1, ...recap.perDay);
  const best = recap.perDay.indexOf(Math.max(...recap.perDay));
  return (
    <Center>
      <p className={cn(T.kicker, "text-accent")}>Strongest day</p>
      <h2 className={cn(T.headline, "mt-2 text-accent")}>
        {recap.strongestDay}
        <br />
        <span className="text-ink">was your day.</span>
      </h2>
      <p className={cn(T.body, "mt-3 text-muted")}>
        {recap.strongestDayCount} check-in{recap.strongestDayCount === 1 ? "" : "s"} in one day.
      </p>
      <div className="mt-6 flex h-[min(38cqw,11rem)] items-end gap-[2.2cqw]" role="img" aria-label={`Check-ins per day: ${recap.perDay.join(", ")}`}>
        {recap.perDay.map((n, i) => {
          const isBest = i === best && n > 0;
          return (
            <div key={i} className="flex h-full min-w-0 flex-1 flex-col items-center justify-end gap-1">
              <span className={cn("font-display text-[clamp(0.7rem,3.4cqw,0.9rem)] font-bold tabular-nums", isBest ? "text-accent" : "text-muted")}>{n}</span>
              <motion.span
                className={cn("w-full origin-bottom rounded-t-[6px] border", isBest ? "border-accent bg-accent" : "border-line-strong bg-paper-deep")}
                style={{ height: `${Math.max(4, (n / max) * 100)}%` }}
                initial={{ scaleY: 0 }}
                animate={{ scaleY: 1 }}
                transition={{ duration: 0.6, delay: 0.15 + i * 0.06, ease: [0.22, 1, 0.36, 1] }}
              />
              <span className={cn("font-display text-[clamp(0.7rem,3.4cqw,0.9rem)] font-bold", isBest ? "text-accent" : "text-faint")}>{WEEKDAY_LETTER[weekday(addDays(recap.start, i))]}</span>
            </div>
          );
        })}
      </div>
    </Center>
  );
}

function TopHabitSlide({ recap }: { recap: RecapData }) {
  const top = recap.topHabit;
  if (!top)
    return (
      <Center className="items-center text-center">
        <Mascot mood="thinking" size={130} />
        <h2 className={cn(T.headline, "mt-4 text-accent")}>Still warming up</h2>
        <p className={cn(T.body, "mt-3 max-w-[28ch] text-muted")}>No habit had a full week yet. Next week&apos;s recap has your name on it.</p>
      </Center>
    );
  return (
    <Center>
      <p className={cn(T.kicker, "text-accent")}>Most consistent habit</p>
      <div className="relative mt-5 self-start">
        <IllustrationTile kind={top.habit.icon} tint={top.habit.tint} size={110} rotate={-5} />
        <span className="absolute -bottom-3 -right-5">
          <Stamp variant="check" size={52} animate />
        </span>
      </div>
      <h2 className="mt-6 line-clamp-3 text-balance font-display text-[clamp(1.6rem,9cqw,2.7rem)] font-extrabold leading-[0.98] tracking-[-0.04em] text-ink">{top.habit.name}</h2>
      <p className="mt-3 font-display text-[clamp(2.4rem,15cqw,4.5rem)] font-extrabold leading-none tracking-[-0.05em] text-accent tabular-nums">{pctOf(top.rate)}%</p>
      <p className={cn(T.body, "mt-1 text-muted")}>
        of scheduled days, done {top.done} time{top.done === 1 ? "" : "s"}. This one&apos;s sticking.
      </p>
    </Center>
  );
}

function ImprovedSlide({ recap }: { recap: RecapData }) {
  const imp = recap.improvedHabit;
  if (!imp)
    return (
      <Center>
        <p className={cn(T.kicker, "opacity-80")}>Most improved</p>
        <h2 className={cn(T.headline, "mt-3")}>Everything held its ground.</h2>
        <p className={cn(T.body, "mt-4 max-w-[30ch] opacity-85")}>No big jumps this week, and no big drops either. Holding steady is underrated.</p>
      </Center>
    );
  return (
    <Center>
      <p className={cn(T.kicker, "opacity-80")}>The glow-up award goes to</p>
      <h2 className="mt-3 line-clamp-3 text-balance font-display text-[clamp(1.6rem,9cqw,2.7rem)] font-extrabold leading-[0.98] tracking-[-0.04em]">{imp.habit.name}</h2>
      <p className={cn(T.huge, "mt-5")}>
        +{pctOf(imp.delta)}
      </p>
      <p className={cn(T.title, "mt-2")}>points on last week</p>
      <p className={cn(T.body, "mt-3 opacity-85")}>Now at {pctOf(imp.rate)}% of scheduled days.</p>
      <span className="absolute right-[7cqw] top-[22%]" aria-hidden>
        <IllustrationTile kind={imp.habit.icon} tint={imp.habit.tint} size={72} rotate={9} />
      </span>
    </Center>
  );
}

function InteractionsSlide({ recap }: { recap: RecapData }) {
  const i = recap.interactions;
  const total = i.reactionsSent + i.reactionsReceived + i.comments + i.nudges;
  return (
    <Center>
      <p className={cn(T.kicker, "text-accent")}>The supporting cast</p>
      <h2 className={cn(T.headline, "mt-2 text-ink")}>{total ? "Friends were in the room." : "A quiet week socially."}</h2>
      <div className="mt-6 grid grid-cols-2 gap-[3cqw]">
        <StatTile value={i.reactionsSent} label="reactions you sent" rotate={-2} />
        <StatTile value={i.reactionsReceived} label="reactions you got" rotate={1.5} />
        <StatTile value={i.comments} label="comments on your check-ins" rotate={1} />
        <StatTile value={i.nudges} label="kind nudges sent" rotate={-1.5} />
      </div>
      <p className={cn(T.hand, "mt-5 text-accent")}>{i.reactionsSent >= i.reactionsReceived && i.reactionsSent > 0 ? "You gave more than you got. Legend." : "Cheering goes both ways."}</p>
    </Center>
  );
}

function SharedSlide({ recap }: { recap: RecapData }) {
  const goals = recap.shared.slice(0, 3);
  return (
    <Center>
      <p className={cn(T.kicker, "text-accent")}>Shared goals</p>
      <h2 className={cn(T.headline, "mt-2 text-ink")}>Better together.</h2>
      {goals.length ? (
        <ul className="mt-6 space-y-4">
          {goals.map((g) => {
            const p = Math.min(1, g.goal ? g.progress / g.goal : 0);
            return (
              <li key={g.title}>
                <div className="flex items-baseline justify-between gap-3">
                  <span className={cn(T.title, "min-w-0 truncate text-[clamp(1rem,4.8cqw,1.3rem)]")}>{g.title}</span>
                  <span className="shrink-0 font-display font-extrabold tabular-nums text-accent">{pctOf(p)}%</span>
                </div>
                <span className="relative mt-1.5 block h-3.5 overflow-hidden rounded-[5px] border border-line bg-paper-deep/70" aria-hidden>
                  <motion.span className="absolute inset-0 origin-left bg-accent" initial={{ scaleX: 0 }} animate={{ scaleX: p }} transition={{ duration: 0.9, delay: 0.3, ease: [0.22, 1, 0.36, 1] }} />
                </span>
                <p className="mt-1 text-[clamp(0.8rem,3.8cqw,0.95rem)] text-muted">
                  {g.progress} of {g.goal} together · you added {g.mine}
                </p>
              </li>
            );
          })}
        </ul>
      ) : (
        <p className={cn(T.body, "mt-4 max-w-[30ch] text-muted")}>No shared goals this week. Start a challenge in Groups and this slide fills itself in.</p>
      )}
    </Center>
  );
}

function FunniestSlide({ recap }: { recap: RecapData }) {
  return (
    <Center>
      <p className={cn(T.kicker, "text-accent")}>Funniest pattern</p>
      <span aria-hidden className="mt-2 font-display text-[clamp(5rem,30cqw,8rem)] font-extrabold leading-[0.6] text-accent/30">“</span>
      <p className="text-balance font-display text-[clamp(1.45rem,8cqw,2.4rem)] font-bold leading-[1.05] tracking-[-0.03em] text-ink">{recap.funniest}</p>
      <div className="mt-6 flex items-end justify-between">
        <p className={cn(T.hand, "text-accent")}>no judgement. mostly.</p>
        <Mascot mood="happy" size={92} />
      </div>
    </Center>
  );
}

function CollectibleSlide({ recap, state }: { recap: RecapData; state: AppState }) {
  const c = recap.collectibleId ? COLLECTIBLE_BY_ID[recap.collectibleId] : undefined;
  if (!c) return null;
  const owned = state.collection.find((o) => o.collectibleId === c.id);
  return (
    <Center className="items-center text-center">
      <p className={cn(T.kicker, "text-accent")}>Fresh in the sticker book</p>
      <motion.div
        className="relative mt-5"
        initial={{ scale: 0.5, rotate: -30, opacity: 0 }}
        animate={{ scale: 1, rotate: 0, opacity: 1 }}
        transition={{ type: "spring", stiffness: 220, damping: 14, delay: 0.2 }}
      >
        <span aria-hidden className="absolute inset-[-22%] rounded-full bg-[radial-gradient(circle,var(--gold-soft),transparent_68%)]" />
        <Sticker collectible={c} size={150} rotate={-6} peel />
      </motion.div>
      <h2 className={cn(T.headline, "mt-5 text-accent")}>{c.name}</h2>
      <AwardRibbon tone="gold" className="mt-3">
        {RARITY_META[c.rarity].label}
      </AwardRibbon>
      {owned && <p className={cn(T.body, "mt-4 max-w-[30ch] text-muted")}>{owned.earnedFor}</p>}
    </Center>
  );
}

function PredictionsSlide({ recap, state }: { recap: RecapData; state: AppState }) {
  const rows = recap.predictions.filter((p) => p.pickedId || p.winnerId).slice(0, 3);
  const resolved = rows.filter((r) => r.correct !== undefined);
  const right = resolved.filter((r) => r.correct).length;
  return (
    <Center>
      <p className={cn(T.kicker, "text-accent")}>Predictions</p>
      <h2 className={cn(T.headline, "mt-2 text-ink")}>{resolved.length ? `${right} of ${resolved.length} called.` : "Results pending."}</h2>
      {rows.length ? (
        <ul className="mt-5 space-y-2.5">
          {rows.map((r) => {
            const status = r.correct === undefined ? "Still open" : r.correct ? "Called it" : "Not this time";
            return (
              <li key={r.question} className="rounded-[14px] border border-line bg-cream px-3 py-2.5 shadow-[var(--shadow)]">
                <p className="line-clamp-2 text-[clamp(0.85rem,4cqw,1rem)] font-semibold leading-snug text-ink">{r.question}</p>
                <div className="mt-1.5 flex flex-wrap items-center justify-between gap-2 text-[clamp(0.75rem,3.6cqw,0.9rem)]">
                  <span className="text-muted">{r.pickedId ? `You picked ${firstName(state, r.pickedId)}` : "You sat this one out"}</span>
                  <span
                    className={cn(
                      "rounded-[7px] px-2 py-0.5 font-display font-bold",
                      r.correct === undefined ? "bg-gold-soft text-[#6b5016] dark:text-gold" : r.correct ? "bg-sage-soft text-sage-ink" : "bg-paper-deep text-muted",
                    )}
                  >
                    {status}
                  </span>
                </div>
              </li>
            );
          })}
        </ul>
      ) : (
        <p className={cn(T.body, "mt-4 text-muted")}>No predictions this week. Your crystal ball is well rested.</p>
      )}
    </Center>
  );
}

function RankingsSlide({ recap, state }: { recap: RecapData; state: AppState }) {
  const podium = recap.rankings.slice(0, 3);
  const rest = recap.rankings.slice(3);
  const order = [podium[1], podium[0], podium[2]];
  const heights = ["h-[13cqw]", "h-[19cqw]", "h-[9cqw]"];
  const places = [2, 1, 3];
  return (
    <Center>
      <p className={cn(T.kicker, "text-accent")}>Your circle</p>
      <h2 className={cn(T.headline, "mt-2 text-ink")}>Everybody showed up.</h2>
      <div className="mt-5 flex items-end justify-center gap-[2.5cqw]">
        {order.map((r, i) =>
          r ? (
            <div key={r.userId} className="flex min-w-0 flex-1 flex-col items-center">
              <StampedPortrait user={state.users[r.userId]} size={places[i] === 1 ? 64 : 50} rotate={i === 0 ? -6 : i === 2 ? 5 : -2} />
              <p className="mt-2 max-w-full truncate font-display text-[clamp(0.8rem,4cqw,1rem)] font-bold">{firstName(state, r.userId)}</p>
              <p className="text-[clamp(0.7rem,3.4cqw,0.85rem)] font-semibold tabular-nums text-muted">{pctOf(r.rate)}%</p>
              <div className={cn("mt-1.5 grid w-full place-items-center rounded-t-[8px] border border-b-0 font-display font-extrabold", heights[i], places[i] === 1 ? "border-accent bg-accent text-on-accent" : "border-line-strong bg-paper-deep text-accent")}>
                {places[i]}
              </div>
            </div>
          ) : (
            <div key={`empty-${i}`} className="flex-1" />
          ),
        )}
      </div>
      <span className="block h-1 rounded-full bg-line-strong" aria-hidden />
      {rest.length > 0 && (
        <div className="mt-4">
          <p className={cn(T.hand, "text-accent")}>Everyone else showed up too:</p>
          <ul className="mt-1.5 flex flex-wrap gap-x-3 gap-y-1.5">
            {rest.map((r) => (
              <li key={r.userId} className="flex items-center gap-1.5 text-[clamp(0.8rem,3.8cqw,0.95rem)]">
                <Avatar user={state.users[r.userId]} size={24} />
                <span className="font-semibold">{firstName(state, r.userId)}</span>
                <span className="text-muted tabular-nums">· {r.completed}</span>
              </li>
            ))}
          </ul>
        </div>
      )}
    </Center>
  );
}

interface Credit {
  id: ID;
  reactions: number;
  comments: number;
  nudges: number;
}

function creditsFor(state: AppState, recap: RecapData): Credit[] {
  const map = new Map<ID, Credit>();
  const get = (id: ID) => {
    if (!map.has(id)) map.set(id, { id, reactions: 0, comments: 0, nudges: 0 });
    return map.get(id)!;
  };
  for (const c of state.checkIns) {
    if (c.userId !== state.meId || c.date < recap.start || c.date > recap.end) continue;
    for (const r of c.reactions) if (r.userId !== state.meId && state.users[r.userId]) get(r.userId).reactions++;
    for (const m of c.comments) if (m.userId !== state.meId && state.users[m.userId]) get(m.userId).comments++;
  }
  const endTs = addDays(recap.end, 1);
  for (const n of state.nudges) {
    const d = n.at.slice(0, 10);
    if (n.toId === state.meId && d >= recap.start && d <= endTs && state.users[n.fromId]) get(n.fromId).nudges++;
  }
  return [...map.values()].filter((c) => !state.settings.blockedIds.includes(c.id)).sort((a, b) => b.reactions + b.comments + b.nudges - (a.reactions + a.comments + a.nudges));
}

function Block({ label, children }: { label: string; children: ReactNode }) {
  return (
    <div className="py-[3.5cqw] text-center">
      <p className="text-[clamp(0.68rem,3.2cqw,0.8rem)] font-bold uppercase tracking-[0.2em] opacity-70">{label}</p>
      <div className="mt-1 font-display text-[clamp(1.1rem,5.6cqw,1.5rem)] font-bold leading-snug">{children}</div>
    </div>
  );
}

function CreditsSlide({ recap, state, paused }: { recap: RecapData; state: AppState; paused: boolean }) {
  const credits = creditsFor(state, recap);
  const role = (c: Credit) =>
    [c.reactions && `${c.reactions} reaction${c.reactions > 1 ? "s" : ""}`, c.comments && `${c.comments} comment${c.comments > 1 ? "s" : ""}`, c.nudges && `${c.nudges} nudge${c.nudges > 1 ? "s" : ""}`]
      .filter(Boolean)
      .join(" · ");
  return (
    <div className="relative -mx-[7cqw] min-h-0 flex-1 overflow-hidden" style={{ maskImage: "linear-gradient(transparent, #000 14%, #000 86%, transparent)" }}>
      <div className="animate-[credits-roll_11s_linear] px-[7cqw]" style={{ animationPlayState: paused ? "paused" : "running" }}>
        <Block label={`A ${BRAND.name} production`}>
          <span className="font-hand text-[1.4em] font-bold">The Week of {formatDate(recap.start)}</span>
        </Block>
        <Block label="Starring">You</Block>
        {credits.length > 0 && (
          <Block label="With heartfelt support from">
            <ul className="space-y-2">
              {credits.map((c) => (
                <li key={c.id}>
                  {state.users[c.id].name}
                  <span className="block text-[0.62em] font-semibold opacity-75">{role(c)}</span>
                </li>
              ))}
            </ul>
          </Block>
        )}
        <Block label="Produced by">
          {recap.completed} check-in{recap.completed === 1 ? "" : "s"}
        </Block>
        <Block label="Filmed on location">Mostly on a {recap.strongestDay}</Block>
        <Block label="Special thanks">Everyone who showed up, including future you</Block>
        <p className="py-[4cqw] text-center font-hand text-[clamp(1.1rem,5.4cqw,1.5rem)] opacity-85">No habits were harmed in the making of this week.</p>
      </div>
    </div>
  );
}

function FinalSlide({ recap, state }: { recap: RecapData; state: AppState }) {
  const award = recap.superlatives.find((s) => s.userId === state.meId);
  const sticker = recap.collectibleId ? COLLECTIBLE_BY_ID[recap.collectibleId] : undefined;
  return (
    <Center>
      <p className={cn(T.hand, "text-accent")}>that&apos;s a wrap!</p>
      <div className="relative mt-2 rounded-[18px] border-2 border-accent bg-cream p-[5cqw] shadow-[var(--shadow-lift)]">
        <span aria-hidden className="tape -top-2.5 left-1/2 -translate-x-1/2" style={{ rotate: "-3deg" }} />
        <div className="flex items-start justify-between gap-3">
          <div className="min-w-0">
            <p className={cn(T.kicker, "text-accent")}>{BRAND.name} weekly recap</p>
            <p className="mt-0.5 font-display text-[clamp(1.1rem,5.6cqw,1.5rem)] font-extrabold tracking-[-0.02em] text-ink">{weekLabel(recap.start, recap.end)}</p>
          </div>
          {sticker && <Sticker collectible={sticker} size={56} rotate={8} />}
        </div>
        <div className="hand-divider my-3" aria-hidden />
        <dl className="grid grid-cols-3 gap-2 text-center">
          {[
            { k: "Check-ins", v: String(recap.completed) },
            { k: "Consistency", v: `${pctOf(recap.rate)}%` },
            { k: "Best day", v: recap.strongestDay.slice(0, 3) },
          ].map((s) => (
            <div key={s.k} className="flex min-w-0 flex-col-reverse">
              <dt className="mt-1 text-[clamp(0.65rem,3.1cqw,0.8rem)] font-semibold text-muted">{s.k}</dt>
              <dd className="font-display text-[clamp(1.5rem,9cqw,2.4rem)] font-extrabold leading-none tracking-[-0.04em] text-accent tabular-nums">{s.v}</dd>
            </div>
          ))}
        </dl>
        <div className="hand-divider my-3" aria-hidden />
        {recap.topHabit && (
          <p className="text-[clamp(0.8rem,3.8cqw,0.95rem)] text-ink">
            <span className="font-semibold text-muted">Most consistent: </span>
            {recap.topHabit.habit.name}
          </p>
        )}
        {award && (
          <p className="mt-1 text-[clamp(0.8rem,3.8cqw,0.95rem)] text-ink">
            <span className="font-semibold text-muted">Award: </span>
            {award.title}
          </p>
        )}
        <span className="absolute -bottom-5 -right-3" aria-hidden>
          <Stamp variant="label" text="Kept" rotate={-12} animate />
        </span>
      </div>
      <p className={cn(T.body, "mt-7 text-center text-muted")}>See you next week. Same time, same habits.</p>
    </Center>
  );
}

/* ---------- Assembly ---------- */

/** Turns recap data into the ordered list of slides for the player. */
export function buildSlides(state: AppState, recap: RecapData): SlideDef[] {
  const friends = recap.rankings.length - 1;
  const slides: SlideDef[] = [
    { key: "title", title: `${BRAND.name} presents the week of ${formatDate(recap.start)}`, tone: "cream", render: () => <TitleSlide recap={recap} friends={friends} /> },
    { key: "completed", title: `${recap.completed} habits completed`, tone: "accent", render: () => <CompletedSlide recap={recap} /> },
    { key: "consistency", title: `Overall consistency ${pctOf(recap.rate)}%`, tone: "cream", render: () => <ConsistencySlide recap={recap} /> },
    { key: "strongest", title: `Strongest day: ${recap.strongestDay}`, tone: "paper", render: () => <StrongestDaySlide recap={recap} /> },
    { key: "top-habit", title: recap.topHabit ? `Most consistent habit: ${recap.topHabit.habit.name}` : "Most consistent habit", tone: "cream", render: () => <TopHabitSlide recap={recap} /> },
    { key: "improved", title: recap.improvedHabit ? `Most improved: ${recap.improvedHabit.habit.name}` : "Most improved", tone: "accent", render: () => <ImprovedSlide recap={recap} /> },
    { key: "interactions", title: "Friend interactions", tone: "paper", render: () => <InteractionsSlide recap={recap} /> },
    { key: "shared", title: "Shared goals", tone: "cream", render: () => <SharedSlide recap={recap} /> },
    { key: "funniest", title: "Funniest pattern", tone: "paper", render: () => <FunniestSlide recap={recap} /> },
  ];
  if (recap.collectibleId && COLLECTIBLE_BY_ID[recap.collectibleId])
    slides.push({ key: "collectible", title: `Sticker unlocked: ${COLLECTIBLE_BY_ID[recap.collectibleId].name}`, tone: "cream", render: () => <CollectibleSlide recap={recap} state={state} /> });
  slides.push(
    { key: "predictions", title: "Prediction results", tone: "paper", render: () => <PredictionsSlide recap={recap} state={state} /> },
    { key: "rankings", title: "Your circle this week", tone: "cream", render: () => <RankingsSlide recap={recap} state={state} /> },
  );
  recap.superlatives.forEach((s, i) =>
    slides.push({
      key: `sup-${s.id}`,
      title: `Award: ${s.title}, ${firstName(state, s.userId)}`,
      tone: i % 2 ? "paper" : "cream",
      render: () => <SuperlativeCard superlative={s} variant="slide" />,
    }),
  );
  slides.push(
    { key: "credits", title: "Credits", tone: "accent", duration: 11000, render: ({ paused }) => <CreditsSlide recap={recap} state={state} paused={paused} /> },
    { key: "summary", title: "Your week, in one card", tone: "cream", render: () => <FinalSlide recap={recap} state={state} /> },
  );
  return slides;
}
