import { LogoMark } from "@/components/brand/Logo";
import { BRAND } from "@/lib/brand";

/** Shown for the instant before local data loads (and during server render). */
export function Splash() {
  return (
    <div className="grid min-h-dvh place-items-center" role="status" aria-live="polite">
      <div className="flex flex-col items-center gap-3">
        <LogoMark size={52} className="animate-pulse" />
        <p className="font-display text-lg font-extrabold tracking-[-0.03em] text-accent">{BRAND.name}</p>
        <span className="sr-only">Loading your daybook…</span>
      </div>
    </div>
  );
}
