import { cn } from "@/lib/cn";

type Mood = "happy" | "sleepy" | "cheer" | "wave" | "thinking" | "proud";

const INK = "#2e1b1a";
const S = { stroke: INK, strokeWidth: 3, strokeLinecap: "round" as const, strokeLinejoin: "round" as const };

/**
 * "Pip", the app mascot: a small rosy blob with a sprout. Used for onboarding,
 * empty states and celebrations. Swap freely when the brand changes.
 */
export function Mascot({ mood = "happy", size = 120, className, title }: { mood?: Mood; size?: number; className?: string; title?: string }) {
  const armsUp = mood === "cheer" || mood === "proud";
  return (
    <svg viewBox="0 0 120 120" width={size} height={size} className={cn("overflow-visible", className)} role={title ? "img" : undefined} aria-label={title} aria-hidden={title ? undefined : true}>
      <g filter="url(#ink-wobble)">
        <ellipse cx="60" cy="108" rx="30" ry="5" fill="#2e1b1a" opacity="0.12" />
        {/* arms */}
        {armsUp ? (
          <>
            <path d="M28 64 C20 56 18 46 20 40" {...S} fill="none" />
            <path d="M92 64 C100 56 102 46 100 40" {...S} fill="none" />
          </>
        ) : mood === "wave" ? (
          <>
            <path d="M28 70 C22 74 20 80 22 84" {...S} fill="none" />
            <path d="M92 64 C101 58 104 48 101 41" {...S} fill="none" />
          </>
        ) : mood === "thinking" ? (
          <>
            <path d="M28 70 C22 74 20 80 22 84" {...S} fill="none" />
            <path d="M90 74 C84 76 78 72 76 66" {...S} fill="none" />
          </>
        ) : (
          <>
            <path d="M28 70 C22 74 20 80 22 84" {...S} fill="none" />
            <path d="M92 70 C98 74 100 80 98 84" {...S} fill="none" />
          </>
        )}
        {/* feet */}
        <path d="M46 100 q-2 6 -8 7 M74 100 q2 6 8 7" {...S} fill="none" />
        {/* body */}
        <path d="M60 24 C84 24 96 46 96 66 C96 88 80 102 60 102 C40 102 24 88 24 66 C24 46 36 24 60 24 Z" fill="#d9a3a0" {...S} />
        <path d="M38 52 C40 42 46 36 53 34" stroke="#fbf6ec" strokeWidth="4" strokeLinecap="round" fill="none" opacity="0.7" />
        {/* sprout */}
        <path d="M60 24 C60 16 62 11 67 8" {...S} fill="none" />
        <path d="M65 10 C70 3 79 3 81 6 C77 12 70 13 65 10 Z" fill="#8fa382" {...S} strokeWidth={2.4} />
        <path d="M60 18 C55 12 48 12 46 15 C50 19 56 20 60 18 Z" fill="#8fa382" {...S} strokeWidth={2.4} />
        {/* face */}
        {mood === "sleepy" ? (
          <>
            <path d="M44 62 q5 4 10 0 M66 62 q5 4 10 0" {...S} fill="none" />
            <path d="M84 30 h8 l-8 8 h8 M96 18 h6 l-6 6 h6" {...S} strokeWidth={2.2} fill="none" />
          </>
        ) : mood === "happy" || mood === "proud" || mood === "cheer" ? (
          <>
            <path d="M44 63 q5 -6 10 0 M66 63 q5 -6 10 0" {...S} fill="none" />
          </>
        ) : (
          <>
            <circle cx="49" cy="61" r="4" fill={INK} />
            <circle cx="71" cy="61" r="4" fill={INK} />
            <circle cx="50.5" cy="59.5" r="1.2" fill="#fbf6ec" />
            <circle cx="72.5" cy="59.5" r="1.2" fill="#fbf6ec" />
          </>
        )}
        {mood === "thinking" ? <path d="M54 76 h12" {...S} fill="none" /> : mood === "cheer" ? <path d="M50 72 q10 12 20 0 Z" fill="#7a1d2c" {...S} strokeWidth={2.4} /> : <path d="M52 73 q8 7 16 0" {...S} fill="none" />}
        <ellipse cx="40" cy="72" rx="5" ry="3" fill="#7a1d2c" opacity="0.3" />
        <ellipse cx="80" cy="72" rx="5" ry="3" fill="#7a1d2c" opacity="0.3" />
        {mood === "proud" && <path d="M44 92 l8 -4 l8 6 l8 -6 l8 4" stroke="#d4ad55" strokeWidth="3" fill="none" strokeLinecap="round" strokeLinejoin="round" />}
        {mood === "thinking" && (
          <>
            <circle cx="96" cy="34" r="3" fill="#fbf6ec" {...S} strokeWidth={2} />
            <circle cx="104" cy="22" r="5" fill="#fbf6ec" {...S} strokeWidth={2} />
          </>
        )}
      </g>
    </svg>
  );
}
