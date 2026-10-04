"use client";

import { RotateCcw, Users } from "lucide-react";
import { motion } from "motion/react";
import { useState } from "react";
import { Avatar } from "@/components/avatar/Avatar";
import { haptic } from "@/components/ui/Toast";
import { cn } from "@/lib/cn";
import { relativeTime } from "@/lib/dates";
import { useAppState, useDispatch } from "@/lib/store/provider";
import type { QuizQuestion, User } from "@/lib/types";
import { firstName } from "./social-helpers";

/** Quiz tags that currently feed a weekly superlative (see selectors/recap). */
export const SUPERLATIVE_TAGS: Record<string, string> = {
  "last-minute": "Last-Minute Legend · 11:59",
  reminders: "Professional Reminder Sender",
  wallet: "Wouldn't Give My Wallet To",
};

/**
 * One friend-quiz question. Before voting, a grid of avatar buttons; after voting, a tally with
 * names, labelled as coming from friend votes.
 */
export function QuizCard({ quiz, candidates, index = 0 }: { quiz: QuizQuestion; candidates: User[]; index?: number }) {
  const state = useAppState();
  const dispatch = useDispatch();
  const mine = quiz.votes[state.meId];
  const [changing, setChanging] = useState(false);
  const voting = !mine || changing;
  const author = state.users[quiz.createdBy];
  const visibleVotes = Object.entries(quiz.votes).filter(([voter, pick]) => !state.settings.blockedIds.includes(voter) && !state.settings.blockedIds.includes(pick));
  const total = visibleVotes.length;
  const tally = new Map<string, number>();
  for (const [, pick] of visibleVotes) tally.set(pick, (tally.get(pick) ?? 0) + 1);
  const results = [...tally.entries()].filter(([id]) => state.users[id]).sort((a, b) => b[1] - a[1] || firstName(state, a[0]).localeCompare(firstName(state, b[0])));
  const leaderVotes = results[0]?.[1] ?? 0;
  const superlative = SUPERLATIVE_TAGS[quiz.tag];

  return (
    <article className="card relative p-4" aria-labelledby={`quiz-${quiz.id}`} style={{ transform: `rotate(${index % 3 === 1 ? 0.4 : index % 3 === 2 ? -0.4 : 0}deg)` }}>
      <div className="flex items-start justify-between gap-3">
        <h3 id={`quiz-${quiz.id}`} className="font-display text-[1.0625rem] font-bold leading-snug text-ink">
          {quiz.prompt}
        </h3>
        <span className="shrink-0 font-hand text-lg leading-none text-accent">{total} vote{total === 1 ? "" : "s"}</span>
      </div>
      <p className="mt-1 text-xs text-muted">
        Asked by {author ? firstName(state, author.id) : "a friend"} · {relativeTime(quiz.createdAt)}
        {superlative && <> · feeds “{superlative}”</>}
      </p>

      {voting ? (
        <fieldset className="mt-3">
          <legend className="sr-only">Vote for a friend</legend>
          <div className="grid grid-cols-3 gap-2 sm:grid-cols-4">
            {candidates.map((u) => (
              <button
                key={u.id}
                type="button"
                aria-pressed={mine === u.id}
                onClick={() => {
                  dispatch({ type: "quiz/vote", id: quiz.id, pickId: u.id });
                  haptic(state.settings.haptics);
                  setChanging(false);
                }}
                className={cn(
                  "flex min-h-[5.5rem] flex-col items-center justify-center gap-1.5 rounded-[14px] border p-2 transition-[background-color,transform] active:scale-95",
                  mine === u.id ? "border-accent bg-accent-soft" : "border-line bg-paper/50 hover:bg-accent-soft/50",
                )}
              >
                <Avatar user={u} size={44} />
                <span className="max-w-full truncate text-xs font-semibold text-ink">{u.name.split(" ")[0]}</span>
              </button>
            ))}
          </div>
          {changing && (
            <button type="button" onClick={() => setChanging(false)} className="mt-2 min-h-11 text-sm font-semibold text-muted hover:text-accent">
              Keep my vote
            </button>
          )}
        </fieldset>
      ) : (
        <div className="mt-3">
          <p className="mb-2 flex items-center gap-1.5 text-[0.6875rem] font-bold uppercase tracking-[0.06em] text-muted">
            <Users size={13} aria-hidden /> From friend votes
          </p>
          <ul className="space-y-1.5">
            {results.map(([id, n], i) => {
              const u = state.users[id];
              const pct = total ? n / total : 0;
              return (
                <li key={id} className="flex items-center gap-2.5">
                  <Avatar user={u} size={28} />
                  <span className="relative h-8 min-w-0 flex-1 overflow-hidden rounded-[9px] border border-line bg-paper/60">
                    <motion.span
                      className={cn("absolute inset-y-0 left-0 rounded-[8px]", n === leaderVotes ? "bg-gold-soft" : "bg-accent-soft/70")}
                      initial={{ width: 0 }}
                      animate={{ width: `${pct * 100}%` }}
                      transition={{ duration: 0.6, delay: i * 0.05, ease: [0.22, 1, 0.36, 1] }}
                    />
                    <span className="relative flex h-full items-center justify-between gap-2 px-2.5 text-sm">
                      <span className="truncate font-semibold text-ink">
                        {firstName(state, id)}
                        {mine === id && <span className="ml-1.5 text-xs font-medium text-accent">your pick</span>}
                      </span>
                      <span className="shrink-0 text-xs tabular-nums text-muted">
                        {n} vote{n === 1 ? "" : "s"}
                      </span>
                    </span>
                  </span>
                </li>
              );
            })}
          </ul>
          <button type="button" onClick={() => setChanging(true)} className="mt-2 inline-flex min-h-11 items-center gap-1.5 text-sm font-semibold text-muted hover:text-accent">
            <RotateCcw size={14} aria-hidden /> Change my vote
          </button>
        </div>
      )}
    </article>
  );
}
