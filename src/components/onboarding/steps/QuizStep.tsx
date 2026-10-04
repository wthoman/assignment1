"use client";

import { AnimatePresence, motion } from "motion/react";
import { useCallback, useEffect, useRef, useState } from "react";
import { Button } from "@/components/ui/Button";
import { HandNote } from "@/components/ui/misc";
import { cn } from "@/lib/cn";
import { QUIZ_QUESTIONS, type QuizAnswers } from "../personality";
import { StepShell } from "../StepShell";

const LETTERS = ["A", "B", "C", "D", "E"];

export function QuizStep({
  index,
  direction,
  answers,
  onAnswer,
  onNext,
  reduce,
}: {
  index: number;
  direction: number;
  answers: QuizAnswers;
  onAnswer: (questionId: string, optionId: string) => void;
  onNext: () => void;
  reduce: boolean;
}) {
  const q = QUIZ_QUESTIONS[index];
  const chosen = answers[q.id];
  const [missing, setMissing] = useState<string | null>(null);
  const last = index === QUIZ_QUESTIONS.length - 1;

  // Move focus to each new question once the person has moved between questions.
  const firstIndex = useRef(index);
  const navigated = useRef(false);
  useEffect(() => {
    if (index !== firstIndex.current) navigated.current = true;
  }, [index]);
  const focusHeading = useCallback((el: HTMLHeadingElement | null) => {
    if (el && navigated.current) el.focus({ preventScroll: true });
  }, []);

  const submit = () => {
    if (!chosen) {
      setMissing(q.id);
      return;
    }
    onNext();
  };

  return (
    <StepShell
      onSubmit={submit}
      heading={
        <header className="mb-5">
          <div className="mb-3 flex items-center justify-between gap-3">
            <p className="eyebrow">
              Habit quiz · {index + 1} of {QUIZ_QUESTIONS.length}
            </p>
            <div className="flex gap-1" aria-hidden>
              {QUIZ_QUESTIONS.map((qq, i) => (
                <span key={qq.id} className={cn("h-1.5 w-4 rounded-full transition-colors duration-300", i < index || answers[qq.id] ? "bg-accent" : i === index ? "bg-accent/35" : "bg-paper-deep")} />
              ))}
            </div>
          </div>
          <AnimatePresence mode="wait" initial={false} custom={direction}>
            <motion.div
              key={q.id}
              custom={direction}
              initial={reduce ? { opacity: 0 } : { opacity: 0, x: direction * 28 }}
              animate={{ opacity: 1, x: 0 }}
              exit={reduce ? { opacity: 0 } : { opacity: 0, x: direction * -28 }}
              transition={{ duration: reduce ? 0.12 : 0.24, ease: [0.22, 1, 0.36, 1] }}
            >
              <h1 ref={focusHeading} tabIndex={-1} className="font-display text-[1.625rem] font-extrabold leading-[1.12] tracking-[-0.03em] text-ink focus:outline-none sm:text-[1.875rem]">
                {q.prompt}
              </h1>
              <HandNote className="mt-1.5" rotate={-2}>
                {q.aside}
              </HandNote>
            </motion.div>
          </AnimatePresence>
        </header>
      }
      footer={
        <div className="space-y-2">
          {missing === q.id && !chosen && (
            <p role="alert" className="text-center text-sm font-semibold text-[#a3301f] dark:text-[#f0a090]">
              Pick the one that fits best. There&rsquo;s no wrong answer.
            </p>
          )}
          <Button type="submit" size="lg" block>
            {last ? "See my result" : "Next question"}
          </Button>
        </div>
      }
    >
      <AnimatePresence mode="wait" initial={false} custom={direction}>
        <motion.div
          key={q.id}
          role="radiogroup"
          aria-label={q.prompt}
          className="space-y-2.5"
          initial={reduce ? { opacity: 0 } : { opacity: 0, x: direction * 36 }}
          animate={{ opacity: 1, x: 0 }}
          exit={reduce ? { opacity: 0 } : { opacity: 0, x: direction * -36 }}
          transition={{ duration: reduce ? 0.12 : 0.26, ease: [0.22, 1, 0.36, 1], delay: reduce ? 0 : 0.03 }}
        >
          {q.options.map((o, i) => {
            const on = chosen === o.id;
            return (
              <button
                key={o.id}
                type="button"
                role="radio"
                aria-checked={on}
                onClick={() => onAnswer(q.id, o.id)}
                className={cn(
                  "flex min-h-14 w-full items-center gap-3 rounded-[14px] border px-3.5 py-3 text-left transition-[background-color,border-color,transform,box-shadow] duration-150 active:scale-[0.985]",
                  on ? "border-accent bg-accent-soft shadow-[var(--shadow)]" : "border-line-strong bg-cream hover:bg-accent-soft/40",
                )}
              >
                <span
                  aria-hidden
                  className={cn(
                    "grid size-8 shrink-0 place-items-center rounded-[9px] border font-display text-sm font-bold transition-colors",
                    on ? "border-accent bg-accent text-on-accent" : "border-line-strong text-muted",
                  )}
                  style={{ transform: `rotate(${on ? -6 : 0}deg)` }}
                >
                  {LETTERS[i]}
                </span>
                <span className="text-[0.9375rem] font-medium leading-snug text-ink">{o.label}</span>
              </button>
            );
          })}
        </motion.div>
      </AnimatePresence>
    </StepShell>
  );
}
