"use client";

import { AnimatePresence, motion, useReducedMotionConfig } from "motion/react";
import { ChevronLeft, ChevronRight, Download, Pause, Play, RotateCcw, Share2, X } from "lucide-react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { useCallback, useEffect, useMemo, useRef, useState, type PointerEvent as ReactPointerEvent } from "react";
import { BottomSheet } from "@/components/ui/BottomSheet";
import { Button } from "@/components/ui/Button";
import { useToast } from "@/components/ui/Toast";
import { BRAND } from "@/lib/brand";
import { cn } from "@/lib/cn";
import { buildRecap } from "@/lib/selectors/recap";
import { useAppState } from "@/lib/store/provider";
import { useToday } from "@/lib/hooks";
import { RecapSlide } from "./RecapSlide";
import { buildSlides, weekLabel } from "./slides";

const DURATION = 6000;
const SWIPE = 48;
const HOLD_MS = 220;

const chromeBase =
  "grid size-11 shrink-0 place-items-center rounded-[13px] transition-[background-color,transform] duration-150 active:scale-95 disabled:opacity-35";

/**
 * Full-screen weekly recap. Slides are stacked sheets of paper: going forward the top
 * sheet is flung off to reveal the next one underneath; going back drops the previous
 * sheet back on top. With reduced motion the sheets cross-fade instead.
 */
export function RecapPlayer() {
  const state = useAppState();
  const today = useToday();
  const router = useRouter();
  const toast = useToast();
  const reduce = Boolean(useReducedMotionConfig());

  const recap = useMemo(() => buildRecap(state, today), [state, today]);
  const slides = useMemo(() => buildSlides(state, recap), [state, recap]);
  const total = slides.length;

  const [[index, dir], setNav] = useState<[number, number]>([0, 1]);
  const [paused, setPaused] = useState(false);
  const [held, setHeld] = useState(false);
  const [shareOpen, setShareOpen] = useState(false);
  const [saving, setSaving] = useState(false);
  const [finished, setFinished] = useState(false);

  const stageRef = useRef<HTMLDivElement>(null);
  const barRef = useRef<HTMLSpanElement>(null);
  const elapsed = useRef(0);
  const press = useRef<{ x: number; y: number; t: number; timer: number } | null>(null);

  const current = slides[Math.min(index, total - 1)];
  const atEnd = index === total - 1;
  const halted = paused || held || shareOpen || saving || finished;
  const duration = current.duration ?? DURATION;

  const go = useCallback(
    (delta: number) => {
      setNav(([i]) => {
        const next = Math.max(0, Math.min(total - 1, i + delta));
        return next === i ? [i, delta] : [next, delta];
      });
      setFinished(false);
    },
    [total],
  );

  const replay = useCallback(() => {
    setNav([0, -1]);
    setFinished(false);
    setPaused(false);
  }, []);

  // Restart the progress segment whenever the slide changes.
  useEffect(() => {
    elapsed.current = 0;
    if (barRef.current) barRef.current.style.transform = "scaleX(0)";
  }, [index]);

  // Auto-advance. Progress is written straight to the bar so the slide never re-renders per frame.
  useEffect(() => {
    if (halted) return;
    let raf = 0;
    let last = performance.now();
    const tick = (now: number) => {
      elapsed.current += now - last;
      last = now;
      const p = Math.min(1, elapsed.current / duration);
      if (barRef.current) barRef.current.style.transform = `scaleX(${p})`;
      if (p >= 1) {
        if (atEnd) setFinished(true);
        else go(1);
        return;
      }
      raf = requestAnimationFrame(tick);
    };
    raf = requestAnimationFrame(tick);
    return () => cancelAnimationFrame(raf);
  }, [halted, index, duration, atEnd, go]);

  // Pause while the tab is hidden.
  useEffect(() => {
    const onVis = () => {
      if (document.hidden) setPaused(true);
    };
    document.addEventListener("visibilitychange", onVis);
    return () => document.removeEventListener("visibilitychange", onVis);
  }, []);

  // Keyboard: arrows to move, space for next, P/K to pause, Escape to leave.
  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      if (shareOpen || e.metaKey || e.ctrlKey || e.altKey) return;
      const target = e.target as HTMLElement | null;
      const onControl = Boolean(target?.closest("button, a, input, select, textarea"));
      if (e.key === "ArrowRight") {
        e.preventDefault();
        go(1);
      } else if (e.key === "ArrowLeft") {
        e.preventDefault();
        go(-1);
      } else if (e.key === " " && !onControl) {
        e.preventDefault();
        if (atEnd) replay();
        else go(1);
      } else if (e.key === "p" || e.key === "k") {
        setPaused((p) => !p);
      } else if (e.key === "Escape") {
        router.push("/recap");
      }
    };
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [go, replay, atEnd, shareOpen, router]);

  /* ---------- Pointer: tap halves, swipe, press-and-hold ---------- */
  const onPointerDown = (e: ReactPointerEvent<HTMLDivElement>) => {
    if ((e.target as HTMLElement).closest("button, a")) return;
    if (e.pointerType === "mouse" && e.button !== 0) return;
    const timer = window.setTimeout(() => setHeld(true), HOLD_MS);
    press.current = { x: e.clientX, y: e.clientY, t: performance.now(), timer };
  };
  const endPress = (e: ReactPointerEvent<HTMLDivElement>, cancelled = false) => {
    const p = press.current;
    if (!p) return;
    press.current = null;
    window.clearTimeout(p.timer);
    const wasHeld = performance.now() - p.t >= HOLD_MS;
    setHeld(false);
    if (cancelled) return;
    const dx = e.clientX - p.x;
    const dy = e.clientY - p.y;
    if (Math.abs(dx) > SWIPE && Math.abs(dx) > Math.abs(dy) * 1.2) {
      go(dx < 0 ? 1 : -1);
      return;
    }
    if (wasHeld || Math.abs(dx) > 12 || Math.abs(dy) > 12) return;
    const rect = stageRef.current?.getBoundingClientRect();
    if (!rect) return;
    if (e.clientX - rect.left < rect.width * 0.35) go(-1);
    else if (atEnd) setFinished(true);
    else go(1);
  };

  /* ---------- Export ---------- */
  const saveImage = async () => {
    const node = stageRef.current?.querySelector<HTMLElement>(`[data-slide-index="${index}"]`);
    if (!node) return;
    setSaving(true);
    try {
      const { toPng } = await import("html-to-image");
      const bg = getComputedStyle(node).backgroundColor;
      const url = await toPng(node, {
        pixelRatio: 2,
        cacheBust: true,
        backgroundColor: bg,
        filter: (n) => !(n instanceof HTMLElement && n.dataset.captureSkip === "true"),
      });
      const a = document.createElement("a");
      a.href = url;
      a.download = `${BRAND.name.toLowerCase()}-recap-${recap.start}-${index + 1}.png`;
      document.body.appendChild(a);
      a.click();
      a.remove();
      toast({ title: "Card saved", body: "Check your downloads.", motif: "ticket" });
    } catch {
      toast({ title: "Couldn't save that card", body: "Your browser blocked the image. Try Share instead." });
    } finally {
      setSaving(false);
    }
  };

  /* ---------- Sheet motion ---------- */
  const variants = reduce
    ? {
        enter: { opacity: 0, zIndex: 2 },
        center: { opacity: 1, zIndex: 2, transition: { duration: 0.35 } },
        exit: { opacity: 0, zIndex: 1, transition: { duration: 0.35 } },
      }
    : {
        enter: (d: number) => (d > 0 ? { x: 0, y: 0, rotate: 0, scale: 0.94, opacity: 1, zIndex: 1 } : { x: "-118%", y: 24, rotate: -9, scale: 1, opacity: 1, zIndex: 3 }),
        center: { x: 0, y: 0, rotate: 0, scale: 1, opacity: 1, zIndex: 2, transition: { type: "spring" as const, stiffness: 240, damping: 30 } },
        exit: (d: number) =>
          d > 0
            ? { x: "-118%", y: 30, rotate: -11, zIndex: 3, transition: { duration: 0.55, ease: [0.4, 0, 0.6, 1] as const } }
            : { scale: 0.94, zIndex: 1, transition: { duration: 0.45 } },
      };

  const onDark = current.tone === "accent";
  const chromeBtn = cn(chromeBase, onDark ? "text-on-accent hover:bg-on-accent/15" : "text-ink hover:bg-ink/10");

  return (
    <div className="fixed inset-0 z-[60] flex items-center justify-center overflow-hidden bg-[#2a1a17] md:gap-6 md:p-6">
      {/* warm backdrop glow (desktop) */}
      <span
        aria-hidden
        className="pointer-events-none absolute inset-0 hidden md:block"
        style={{ background: "radial-gradient(ellipse 50% 60% at 50% 30%, rgb(224 154 95 / 0.22), transparent 70%), radial-gradient(ellipse 40% 50% at 50% 100%, rgb(111 23 37 / 0.45), transparent 70%)" }}
      />

      <button
        type="button"
        onClick={() => go(-1)}
        disabled={index === 0}
        aria-label="Previous slide"
        className="relative z-10 hidden size-14 shrink-0 place-items-center rounded-full border border-[#fbf6ec]/20 bg-[#fbf6ec]/10 text-[#fbf6ec] transition-[background-color,transform] hover:bg-[#fbf6ec]/20 active:scale-95 disabled:opacity-30 md:grid"
      >
        <ChevronLeft size={26} aria-hidden />
      </button>

      <div
        ref={stageRef}
        className="relative h-dvh w-full touch-pan-y select-none md:aspect-[9/16] md:h-[min(92dvh,880px)] md:w-auto md:max-w-[430px]"
        onPointerDown={onPointerDown}
        onPointerUp={(e) => endPress(e)}
        onPointerCancel={(e) => endPress(e, true)}
        onPointerLeave={(e) => press.current && endPress(e, true)}
        onContextMenu={(e) => e.preventDefault()}
      >
        {/* paper sheets waiting underneath */}
        <span aria-hidden className="absolute inset-0 hidden translate-x-2 translate-y-3 rotate-[2.5deg] rounded-[22px] bg-paper-deep md:block" />
        <span aria-hidden className="absolute inset-0 hidden -translate-x-1.5 translate-y-1.5 -rotate-[1.5deg] rounded-[22px] bg-paper md:block" />

        <div className="absolute inset-0 overflow-hidden md:overflow-visible">
          <AnimatePresence initial={false} custom={dir}>
            <motion.div
              key={index}
              custom={dir}
              variants={variants}
              initial="enter"
              animate="center"
              exit="exit"
              className="absolute inset-0 overflow-hidden shadow-[0_24px_60px_-24px_rgb(0_0_0/0.7)] md:rounded-[22px]"
              style={{ transformOrigin: "30% 90%" }}
            >
              <RecapSlide index={index} total={total} title={current.title} tone={current.tone} paused={halted}>
                {current.render({ paused: halted })}
              </RecapSlide>
            </motion.div>
          </AnimatePresence>
        </div>

        {/* top chrome: progress + title + pause + close */}
        <div className={cn("pointer-events-none absolute inset-x-0 top-0 z-20 px-3 pt-[max(0.6rem,env(safe-area-inset-top))]", onDark ? "text-on-accent" : "text-ink")}>
          <div className="flex gap-1" aria-hidden>
            {slides.map((s, i) => (
              <span key={s.key} className={cn("relative h-[3px] flex-1 overflow-hidden rounded-full", onDark ? "bg-on-accent/30" : "bg-ink/15")}>
                <span
                  key={i === index ? "active" : "idle"}
                  ref={i === index ? barRef : undefined}
                  className={cn("absolute inset-0 origin-left rounded-full", onDark ? "bg-on-accent" : "bg-accent")}
                  style={{ transform: i < index || (i === index && finished) ? "scaleX(1)" : "scaleX(0)" }}
                />
              </span>
            ))}
          </div>
          <div className="pointer-events-auto mt-1.5 flex items-center gap-1">
            <p className="min-w-0 flex-1 truncate pl-1 font-display text-[0.8125rem] font-semibold opacity-80">
              {BRAND.name} recap · {weekLabel(recap.start, recap.end)}
            </p>
            <button type="button" onClick={() => setPaused((p) => !p)} aria-label={paused ? "Play" : "Pause"} aria-pressed={paused} className={chromeBtn}>
              {paused ? <Play size={20} aria-hidden /> : <Pause size={20} aria-hidden />}
            </button>
            <Link href="/recap" aria-label="Close recap" className={chromeBtn}>
              <X size={22} aria-hidden />
            </Link>
          </div>
        </div>

        {/* bottom chrome */}
        <div className={cn("absolute inset-x-0 bottom-0 z-20 flex items-center gap-1.5 px-3 pb-[max(0.75rem,env(safe-area-inset-bottom))]", onDark ? "text-on-accent" : "text-ink")}>
          <button type="button" onClick={() => go(-1)} disabled={index === 0} aria-label="Previous slide" className={cn(chromeBtn, "md:hidden")}>
            <ChevronLeft size={22} aria-hidden />
          </button>
          {atEnd ? (
            <div className="flex min-w-0 flex-1 gap-1.5">
              <Button variant="secondary" size="md" onClick={replay} icon={<RotateCcw size={17} aria-hidden />} className="min-w-0 flex-1 px-2">
                Replay
              </Button>
              <Button size="md" onClick={() => router.push("/share?kind=recap")} icon={<Share2 size={17} aria-hidden />} className="min-w-0 flex-1 px-2">
                Share recap
              </Button>
            </div>
          ) : (
            <div className="min-w-0 flex-1" />
          )}
          <button type="button" onClick={() => setShareOpen(true)} aria-label="Share this card" className={chromeBtn}>
            <Share2 size={20} aria-hidden />
          </button>
          <button type="button" onClick={saveImage} disabled={saving} aria-label="Save as image" className={chromeBtn}>
            <Download size={20} aria-hidden />
          </button>
          <button type="button" onClick={() => go(1)} disabled={atEnd} aria-label="Next slide" className={cn(chromeBtn, "md:hidden")}>
            <ChevronRight size={22} aria-hidden />
          </button>
        </div>

        {held && (
          <span className="pointer-events-none absolute left-1/2 top-1/2 z-30 -translate-x-1/2 -translate-y-1/2 rounded-[12px] bg-ink/70 px-3 py-1.5 font-display text-sm font-semibold text-paper" aria-hidden>
            Paused
          </span>
        )}
      </div>

      <button
        type="button"
        onClick={() => (atEnd ? replay() : go(1))}
        aria-label={atEnd ? "Replay recap" : "Next slide"}
        className="relative z-10 hidden size-14 shrink-0 place-items-center rounded-full border border-[#fbf6ec]/20 bg-[#fbf6ec]/10 text-[#fbf6ec] transition-[background-color,transform] hover:bg-[#fbf6ec]/20 active:scale-95 md:grid"
      >
        {atEnd ? <RotateCcw size={24} aria-hidden /> : <ChevronRight size={26} aria-hidden />}
      </button>

      <p className="sr-only" aria-live="polite" aria-atomic="true">
        Slide {index + 1} of {total}: {current.title}
        {paused ? ". Paused" : ""}
      </p>

      <BottomSheet open={shareOpen} onClose={() => setShareOpen(false)} title="Share this card" description={current.title} size="sm">
        <div className="space-y-2">
          <Button block onClick={() => router.push(`/share?kind=recap-card&slide=${index + 1}`)} icon={<Share2 size={18} aria-hidden />} data-autofocus>
            Open in Share studio
          </Button>
          <Button
            block
            variant="secondary"
            onClick={() => {
              setShareOpen(false);
              window.setTimeout(saveImage, 260);
            }}
            icon={<Download size={18} aria-hidden />}
          >
            Save as image
          </Button>
          <Button block variant="ghost" onClick={() => router.push("/share?kind=recap")}>
            Share the full recap instead
          </Button>
        </div>
      </BottomSheet>
    </div>
  );
}
