"use client";

import { Check, Lock } from "lucide-react";
import Link from "next/link";
import { Avatar } from "@/components/avatar/Avatar";
import { Stamp } from "@/components/ui/Stamp";
import { haptic } from "@/components/ui/Toast";
import { cn } from "@/lib/cn";
import { formatDate } from "@/lib/dates";
import { useToday } from "@/lib/hooks";
import { useAppState, useDispatch } from "@/lib/store/provider";
import type { Prediction } from "@/lib/types";
import { firstName } from "./social-helpers";

/**
 * A friendly guess about who'll do what first. Options render as avatar buttons;
 * once I've voted, everyone's guesses show as a small tally. Closed predictions show who
 * actually did it, framed as a celebration of them, not a scorecard of guessers.
 */
export function PredictionCard({ prediction: p, showGroup, className }: { prediction: Prediction; showGroup?: boolean; className?: string }) {
  const state = useAppState();
  const dispatch = useDispatch();
  const today = useToday();
  const mine = p.votes[state.meId];
  const closed = Boolean(p.winnerId) || p.closesAt < today;
  const total = Object.keys(p.votes).length;
  const group = p.groupId ? state.groups.find((g) => g.id === p.groupId) : undefined;
  const options = p.optionIds.filter((id) => state.users[id] && !state.settings.blockedIds.includes(id));
  const showTally = Boolean(mine) || closed;

  return (
    <article className={cn("card relative overflow-hidden p-4", className)} aria-label={`Prediction: ${p.question}`}>
      <div className="flex items-start justify-between gap-3">
        <div className="min-w-0">
          <p className="eyebrow flex items-center gap-1.5">
            Prediction
            {showGroup && group && (
              <Link href={`/groups/${group.id}`} className="normal-case tracking-normal text-muted underline-offset-2 hover:underline">
                · {group.name}
              </Link>
            )}
          </p>
          <h3 className="mt-1 font-display text-[1.0625rem] font-bold leading-snug text-ink">{p.question}</h3>
        </div>
        {p.winnerId ? (
          <Stamp variant="label" text="Called it" rotate={6} className="mt-1 shrink-0" />
        ) : (
          <span className="mt-1 shrink-0 text-xs font-medium text-faint">{closed ? "Closed" : `Closes ${formatDate(p.closesAt, { weekday: "short" })}`}</span>
        )}
      </div>

      <ul className="mt-3 grid grid-cols-2 gap-2 sm:grid-cols-3">
        {options.map((id) => {
          const u = state.users[id];
          const votes = Object.values(p.votes).filter((v) => v === id).length;
          const picked = mine === id;
          const winner = p.winnerId === id;
          const share = total ? votes / total : 0;
          return (
            <li key={id}>
              <button
                type="button"
                disabled={closed}
                aria-pressed={picked}
                aria-label={`${closed ? "" : "Guess "}${firstName(state, id)}${showTally ? `, ${votes} vote${votes === 1 ? "" : "s"}` : ""}${winner ? ", did it" : ""}`}
                onClick={() => {
                  dispatch({ type: "prediction/vote", id: p.id, pickId: id });
                  haptic(state.settings.haptics);
                }}
                className={cn(
                  "relative flex min-h-14 w-full items-center gap-2 overflow-hidden rounded-[13px] border px-2.5 py-2 text-left transition-colors disabled:cursor-default",
                  picked ? "border-accent bg-accent-soft" : winner ? "border-gold bg-gold-soft" : "border-line bg-paper/50 enabled:hover:bg-accent-soft/50",
                )}
              >
                {showTally && <span aria-hidden className="absolute inset-y-0 left-0 bg-accent/10 transition-[width] duration-500" style={{ width: `${share * 100}%` }} />}
                <Avatar user={u} size={32} className="relative" />
                <span className="relative min-w-0 flex-1">
                  <span className="block truncate font-display text-sm font-semibold text-ink">{firstName(state, id)}</span>
                  {showTally && <span className="block text-xs tabular-nums text-muted">{votes} guess{votes === 1 ? "" : "es"}</span>}
                </span>
                {picked && <Check size={16} className="relative shrink-0 text-accent" aria-hidden />}
              </button>
            </li>
          );
        })}
      </ul>

      <p className="mt-3 flex items-center gap-1.5 text-xs text-muted">
        {p.winnerId ? (
          <>
            <span className="font-semibold text-ink">{firstName(state, p.winnerId)}</span> got there first.{" "}
            {mine ? (mine === p.winnerId ? "Nice call!" : "Fun guess anyway.") : ""}
          </>
        ) : closed ? (
          <>
            <Lock size={12} aria-hidden /> Voting closed. Results land with the weekly recap.
          </>
        ) : mine ? (
          <>You guessed {firstName(state, mine)}. Tap another face to change it.</>
        ) : (
          <>Just for fun. Guesses are shown once you&apos;ve made one.</>
        )}
      </p>
    </article>
  );
}
