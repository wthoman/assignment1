"use client";

import { Activity, Plus, Users, Vote } from "lucide-react";
import { useId, useState, type FormEvent } from "react";
import { Page } from "@/components/shell/Page";
import { QuizCard } from "@/components/social/QuizCard";
import { visibleFriends } from "@/components/social/social-helpers";
import { Button } from "@/components/ui/Button";
import { CharCount, Field, Segmented, TextInput } from "@/components/ui/controls";
import { EmptyState, HandNote, SectionHeading } from "@/components/ui/misc";
import { useToast } from "@/components/ui/Toast";
import { useAppState, useDispatch } from "@/lib/store/provider";

const MAX = 100;

const SUGGESTIONS = [
  "Who would survive a no-phone weekend?",
  "Who is most likely to start a 5am club?",
  "Who gives the best pep talks?",
  "Who would win a plank contest?",
  "Who is secretly the most organised?",
  "Who would finish a book club book first?",
];

type View = "open" | "answered";

export default function QuizzesPage() {
  const state = useAppState();
  const dispatch = useDispatch();
  const toast = useToast();
  const inputId = useId();
  const [view, setView] = useState<View>("open");
  const [prompt, setPrompt] = useState("");
  const [tried, setTried] = useState(false);

  const friends = visibleFriends(state);
  // Questions that were open when the page loaded stay in "Waiting on you" so the results reveal in place.
  const [sessionOpen] = useState(() => new Set(state.quizzes.filter((q) => !q.votes[state.meId]).map((q) => q.id)));
  const open = state.quizzes.filter((q) => !q.votes[state.meId]);
  const answered = state.quizzes.filter((q) => q.votes[state.meId]);
  const list = view === "open" ? state.quizzes.filter((q) => !q.votes[state.meId] || sessionOpen.has(q.id)) : answered;

  const trimmed = prompt.trim();
  const duplicate = state.quizzes.some((q) => q.prompt.toLowerCase() === trimmed.toLowerCase());
  const error = !tried
    ? undefined
    : !trimmed
      ? "Write a question first."
      : trimmed.length < 8
        ? "A little longer, so friends know what you mean."
        : trimmed.length > MAX
          ? `Keep it under ${MAX} characters.`
          : duplicate
            ? "Your circle already has that one."
            : !/^who\b/i.test(trimmed)
              ? "Start with “Who…” so friends can vote for someone."
              : undefined;

  const submit = (e: FormEvent) => {
    e.preventDefault();
    setTried(true);
    const ok = trimmed.length >= 8 && trimmed.length <= MAX && !duplicate && /^who\b/i.test(trimmed);
    if (!ok) return;
    const q = /[?!.]$/.test(trimmed) ? trimmed : `${trimmed}?`;
    dispatch({ type: "quiz/create", prompt: q });
    toast({ title: "Question sent to your circle", body: q, motif: "star" });
    setPrompt("");
    setTried(false);
    setView("open");
  };

  const aside = (
    <section className="card p-4" aria-labelledby="sources-heading">
      <h2 id="sources-heading" className="font-display text-[1.0625rem] font-bold text-ink">
        Where superlatives come from
      </h2>
      <p className="mt-1 text-sm leading-relaxed text-muted">Weekly superlatives in your recap always say what they&apos;re based on.</p>
      <ul className="mt-3 space-y-2.5 text-sm">
        <li className="flex gap-2.5">
          <span className="grid size-8 shrink-0 place-items-center rounded-[9px] bg-sage-soft text-sage-ink">
            <Activity size={16} aria-hidden />
          </span>
          <span>
            <span className="font-semibold text-ink">Behavior</span>
            <span className="block text-muted">From actual check-ins, like times and streaks.</span>
          </span>
        </li>
        <li className="flex gap-2.5">
          <span className="grid size-8 shrink-0 place-items-center rounded-[9px] bg-sky-soft text-ink">
            <Vote size={16} aria-hidden />
          </span>
          <span>
            <span className="font-semibold text-ink">Votes</span>
            <span className="block text-muted">From these quizzes. Pure vibes, clearly labelled.</span>
          </span>
        </li>
        <li className="flex gap-2.5">
          <span className="grid size-8 shrink-0 place-items-center rounded-[9px] bg-gold-soft text-ink">
            <Users size={16} aria-hidden />
          </span>
          <span>
            <span className="font-semibold text-ink">Both</span>
            <span className="block text-muted">When the data and your friends agree.</span>
          </span>
        </li>
      </ul>
      <p className="mt-3 text-xs text-faint">Only friends see votes, and quizzes never affect consistency scores.</p>
    </section>
  );

  return (
    <Page title="Friend quizzes" back="/friends" subtitle="Silly questions, friendly votes. Results can show up as weekly superlatives." aside={aside}>
      <div className="space-y-6">
        <form onSubmit={submit} className="card relative space-y-3 p-4" noValidate aria-labelledby="ask-heading">
          <div className="flex items-baseline justify-between gap-2">
            <h2 id="ask-heading" className="font-display text-[1.0625rem] font-bold text-ink">
              Ask your circle
            </h2>
            <HandNote className="text-base">keep it kind</HandNote>
          </div>
          <Field label="Your question" htmlFor={inputId} error={error} hint="Start with “Who…”. Friends vote for one person.">
            <TextInput id={inputId} value={prompt} onChange={(e) => setPrompt(e.target.value)} placeholder="Who would…" invalid={Boolean(error)} maxLength={MAX + 20} autoComplete="off" />
          </Field>
          <div className="flex items-center justify-between gap-2">
            <CharCount value={prompt} max={MAX} />
            <Button type="submit" size="sm" className="min-h-11" icon={<Plus size={16} aria-hidden />}>
              Ask
            </Button>
          </div>
          <div>
            <p className="mb-1.5 text-xs font-semibold text-muted">Need an idea?</p>
            <ul className="flex flex-wrap gap-1.5">
              {SUGGESTIONS.filter((s) => !state.quizzes.some((q) => q.prompt === s)).map((s) => (
                <li key={s}>
                  <button
                    type="button"
                    onClick={() => {
                      setPrompt(s);
                      setTried(false);
                    }}
                    className="min-h-10 rounded-[11px] border border-line-strong bg-paper/50 px-3 text-left text-sm text-ink transition-colors hover:bg-accent-soft"
                  >
                    {s}
                  </button>
                </li>
              ))}
            </ul>
          </div>
        </form>

        <section aria-labelledby="questions-heading" className="space-y-3">
          <SectionHeading id="questions-heading" title="Questions" />
          <Segmented
            label="Show questions"
            value={view}
            onChange={setView}
            size="sm"
            options={[
              { value: "open", label: `Waiting on you (${open.length})` },
              { value: "answered", label: `Answered (${answered.length})` },
            ]}
          />
          {friends.length === 0 ? (
            <EmptyState title="Add friends to play" body="Quizzes need at least one friend to vote for." mood="wave" />
          ) : list.length ? (
            <div className="space-y-3">
              {list.map((q, i) => (
                <QuizCard key={q.id} quiz={q} candidates={friends} index={i} />
              ))}
            </div>
          ) : (
            <EmptyState
              compact
              mood={view === "open" ? "happy" : "thinking"}
              title={view === "open" ? "All caught up" : "No votes yet"}
              body={view === "open" ? "You've voted on every question. Ask a new one above." : "Vote on a question and the results show up here."}
            />
          )}
        </section>
      </div>
    </Page>
  );
}
