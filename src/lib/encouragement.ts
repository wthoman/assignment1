import type { EncouragementStyle } from "./types";

type Ctx = { done: number; total: number; name: string };

const DAY_MESSAGES: Record<EncouragementStyle, ((c: Ctx) => string)[]> = {
  gentle: [
    (c) => (c.done === 0 ? "One small thing is plenty to start with." : c.done >= c.total ? "Everything's stamped. Be proud of today." : `${c.done} down. Small steps still count.`),
  ],
  cheeky: [
    (c) => (c.done === 0 ? "The day is young and so are your excuses." : c.done >= c.total ? "Full sheet. Someone call the newspapers." : `${c.done} down. The couch is getting nervous.`),
  ],
  coach: [
    (c) => (c.done === 0 ? "First rep is the hardest. Pick one." : c.done >= c.total ? "All done. Recover well — same time tomorrow." : `${c.done} of ${c.total}. Keep the tempo.`),
  ],
};

export function dayMessage(style: EncouragementStyle, ctx: Ctx) {
  return DAY_MESSAGES[style][0](ctx);
}

const CHECKIN_MESSAGES: Record<EncouragementStyle, string[]> = {
  gentle: ["Nicely done.", "That counts.", "One more page in the book.", "Look at you, showing up.", "Gently stamped."],
  cheeky: ["Stamped. Smug face allowed.", "Okay, show-off.", "Another one for the scrapbook.", "Your future self says thanks (begrudgingly).", "Ink's still wet."],
  coach: ["Good rep.", "That's the standard.", "Logged. Next.", "Consistency beats intensity.", "Strong work."],
};

export function checkInMessage(style: EncouragementStyle, seed: number) {
  const list = CHECKIN_MESSAGES[style];
  return list[Math.abs(seed) % list.length];
}

export function comebackMessage(style: EncouragementStyle) {
  return style === "cheeky" ? "Look who's back. We saved your seat." : style === "coach" ? "Back in the game. That's the real skill." : "Welcome back. Coming back is the whole skill.";
}
