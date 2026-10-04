"use client";

import { ArrowLeft } from "lucide-react";
import { AnimatePresence, motion, useReducedMotion, type Variants } from "motion/react";
import { useRouter } from "next/navigation";
import { useState } from "react";
import { Button, IconButton } from "@/components/ui/Button";
import { useToast } from "@/components/ui/Toast";
import { cn } from "@/lib/cn";
import { useAppState, useDispatch } from "@/lib/store/provider";
import type { PersonalityKey } from "@/lib/types";
import { QUIZ_QUESTIONS, scorePersonality, type QuizAnswers } from "./personality";
import { SideIllustration } from "./SideIllustration";
import { StepFocusContext } from "./StepShell";
import { AccountStep, type AuthMode } from "./steps/AccountStep";
import { AvatarStep } from "./steps/AvatarStep";
import { DoneStep } from "./steps/DoneStep";
import { FriendsStep } from "./steps/FriendsStep";
import { GoalsStep } from "./steps/GoalsStep";
import { HabitStep } from "./steps/HabitStep";
import { NameStep } from "./steps/NameStep";
import { NotificationsStep } from "./steps/NotificationsStep";
import { QuizStep } from "./steps/QuizStep";
import { ResultStep } from "./steps/ResultStep";
import { WelcomeStep } from "./steps/WelcomeStep";

const STEPS = ["welcome", "account", "name", "avatar", "goals", "quiz", "result", "habit", "friends", "notifications", "done"] as const;
type StepKey = (typeof STEPS)[number];

const LABELS: Record<StepKey, string> = {
  welcome: "Welcome",
  account: "Account",
  name: "Your name",
  avatar: "Avatar",
  goals: "Goals",
  quiz: "Habit quiz",
  result: "Your result",
  habit: "First habit",
  friends: "Friends",
  notifications: "Notifications",
  done: "All set",
};

/** Optional steps show a Skip button in the header. */
const SKIPPABLE = new Set<StepKey>(["avatar", "habit", "friends", "notifications"]);
const TOTAL = STEPS.length - 1;

function ProgressStamps({ current, label }: { current: number; label: string }) {
  return (
    <div className="flex flex-col items-center gap-1.5">
      <p className="font-display text-xs font-semibold tabular-nums text-muted">
        Step {current} of {TOTAL}
        <span className="sr-only">: {label}</span>
      </p>
      <div className="relative flex items-center gap-1" aria-hidden>
        <span className="dotted-rule absolute inset-x-0 top-1/2 -translate-y-1/2" />
        {Array.from({ length: TOTAL }, (_, i) => {
          const n = i + 1;
          return (
            <span
              key={n}
              className={cn(
                "relative rounded-full border transition-all duration-300",
                n < current && "size-2 border-accent bg-accent",
                n === current && "size-2.5 border-2 border-accent bg-cream ring-2 ring-accent/20",
                n > current && "size-2 border-line-strong bg-paper",
              )}
            />
          );
        })}
      </div>
    </div>
  );
}

export function OnboardingFlow() {
  const router = useRouter();
  const dispatch = useDispatch();
  const state = useAppState();
  const toast = useToast();
  const prefersReduced = useReducedMotion();
  const reduce = state.settings.motion === "reduced" || (state.settings.motion !== "full" && !!prefersReduced);

  const [step, setStep] = useState(0);
  const [dir, setDir] = useState(1);
  const [navigated, setNavigated] = useState(false);
  const [authMode, setAuthMode] = useState<AuthMode>("signup");
  const [answers, setAnswers] = useState<QuizAnswers>({});
  const [quizIndex, setQuizIndex] = useState(0);
  const [quizDir, setQuizDir] = useState(1);
  const [personality, setPersonality] = useState<PersonalityKey | null>(null);
  const [habitId, setHabitId] = useState<string | null>(null);

  const key = STEPS[step];
  const resolvedPersonality: PersonalityKey = personality ?? state.session.personality ?? scorePersonality(answers, state.session.goals);

  const go = (to: number) => {
    const target = Math.max(0, Math.min(STEPS.length - 1, to));
    setDir(target >= step ? 1 : -1);
    setStep(target);
    setNavigated(true);
    window.scrollTo(0, 0);
  };
  const next = () => go(step + 1);

  const back = () => {
    if (key === "quiz" && quizIndex > 0) {
      setQuizDir(-1);
      setQuizIndex(quizIndex - 1);
      window.scrollTo(0, 0);
      return;
    }
    go(step - 1);
  };

  const enterApp = () => {
    dispatch({ type: "session/finishOnboarding" });
    router.replace("/today");
  };

  const explore = () => {
    const me = state.users[state.meId];
    dispatch({ type: "session/account", account: { email: `${me.handle || "demo"}@example.com`, method: "email", createdAt: new Date().toISOString() } });
    enterApp();
  };

  const onAccount = (mode: AuthMode) => {
    if (mode === "login") {
      toast({ title: `Welcome back, ${state.users[state.meId].name.split(" ")[0]}`, body: "Your habits are right where you left them.", motif: "sun" });
      enterApp();
      return;
    }
    next();
  };

  const quizNext = () => {
    if (quizIndex < QUIZ_QUESTIONS.length - 1) {
      setQuizDir(1);
      setQuizIndex(quizIndex + 1);
      window.scrollTo(0, 0);
      return;
    }
    setPersonality(scorePersonality(answers, state.session.goals));
    next();
  };

  const variants: Variants = {
    enter: (d: number) => (reduce ? { opacity: 0 } : { opacity: 0, x: d * 56, rotate: d * 0.8 }),
    center: { opacity: 1, x: 0, rotate: 0 },
    exit: (d: number) => (reduce ? { opacity: 0 } : { opacity: 0, x: d * -56, rotate: d * -0.8 }),
  };

  const renderStep = () => {
    switch (key) {
      case "welcome":
        return (
          <WelcomeStep
            reduce={reduce}
            onStart={() => {
              setAuthMode("signup");
              next();
            }}
            onLogin={() => {
              setAuthMode("login");
              next();
            }}
            onExplore={explore}
          />
        );
      case "account":
        return <AccountStep mode={authMode} onModeChange={setAuthMode} onDone={onAccount} />;
      case "name":
        return <NameStep onNext={next} />;
      case "avatar":
        return <AvatarStep onNext={next} reduce={reduce} />;
      case "goals":
        return <GoalsStep onNext={next} />;
      case "quiz":
        return (
          <QuizStep
            index={quizIndex}
            direction={quizDir}
            answers={answers}
            onAnswer={(q, o) => setAnswers((a) => ({ ...a, [q]: o }))}
            onNext={quizNext}
            reduce={reduce}
          />
        );
      case "result":
        return <ResultStep personality={resolvedPersonality} onNext={next} reduce={reduce} />;
      case "habit":
        return (
          <HabitStep
            personality={resolvedPersonality}
            habitId={habitId}
            onCreated={(id) => {
              setHabitId(id);
              next();
            }}
          />
        );
      case "friends":
        return <FriendsStep onNext={next} />;
      case "notifications":
        return <NotificationsStep onNext={next} />;
      case "done":
        return <DoneStep personality={personality ?? state.session.personality ?? null} habitId={habitId} onFinish={enterApp} reduce={reduce} />;
    }
  };

  return (
    <div className="relative z-[1] min-h-dvh lg:grid lg:grid-cols-[minmax(0,1fr)_minmax(560px,46%)]">
      <SideIllustration stepKey={key} reduce={reduce} className="hidden lg:sticky lg:top-0 lg:flex lg:h-dvh" />

      <main className="flex min-h-dvh w-full flex-col md:items-center md:justify-center md:px-6 md:py-10">
        <div className="flex w-full flex-1 flex-col overflow-x-clip md:min-h-[min(780px,calc(100dvh-5rem))] md:max-w-[480px] md:flex-none md:rounded-[var(--radius-card)] md:border md:border-line md:bg-cream md:shadow-[var(--shadow-lift)]">
          {step > 0 && (
            <div className="sticky top-0 z-20 grid grid-cols-[4.5rem_1fr_4.5rem] items-center bg-paper px-2 pb-1 pt-[max(0.5rem,env(safe-area-inset-top))] sm:px-4 md:rounded-t-[var(--radius-card)] md:bg-cream md:pt-3">
              <IconButton label={key === "quiz" && quizIndex > 0 ? "Previous question" : "Back"} onClick={back}>
                <ArrowLeft size={20} aria-hidden />
              </IconButton>
              <ProgressStamps current={step} label={LABELS[key]} />
              <div className="flex justify-end">
                {SKIPPABLE.has(key) && (
                  <Button variant="ghost" size="sm" className="min-h-11 px-3 text-muted" onClick={next} aria-label={key === "habit" ? "Skip for now" : `Skip ${LABELS[key].toLowerCase()}`}>
                    Skip
                  </Button>
                )}
              </div>
            </div>
          )}

          <StepFocusContext.Provider value={navigated}>
            <AnimatePresence mode="wait" initial={false} custom={dir}>
              <motion.div
                key={key}
                custom={dir}
                variants={variants}
                initial="enter"
                animate="center"
                exit="exit"
                transition={{ duration: reduce ? 0.15 : 0.32, ease: [0.22, 1, 0.36, 1] }}
                className="flex flex-1 flex-col"
              >
                {renderStep()}
              </motion.div>
            </AnimatePresence>
          </StepFocusContext.Provider>
        </div>
      </main>
    </div>
  );
}
