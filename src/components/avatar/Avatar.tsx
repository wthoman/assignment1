import type { AvatarConfig, User } from "@/lib/types";
import { cn } from "@/lib/cn";
import { TINT_HEX } from "@/components/illustrations/Illustration";

const INK = "#2e1b1a";
const S = { stroke: INK, strokeWidth: 2.4, strokeLinecap: "round" as const, strokeLinejoin: "round" as const };

const BG_SOFT: Record<string, string> = {
  cream: "#f6ecd8",
  rose: "#f2d9d5",
  sage: "#dde6d1",
  sky: "#dbe7ef",
  gold: "#f1e2b8",
  orange: "#f6dcc0",
  burgundy: "#ecd3d3",
};

function Head({ a }: { a: AvatarConfig }) {
  switch (a.head) {
    case "bean":
      return <path d="M32 14 C43 14 47 22 46 31 C45 41 40 46 32 46 C23 46 18 41 18 31 C18 21 22 14 32 14 Z" fill={a.skin} {...S} />;
    case "square":
      return <rect x="18.5" y="15" width="27" height="30" rx="9" fill={a.skin} {...S} />;
    case "tall":
      return <ellipse cx="32" cy="30" rx="12.5" ry="16.5" fill={a.skin} {...S} />;
    default:
      return <circle cx="32" cy="30.5" r="14.5" fill={a.skin} {...S} />;
  }
}

function HairBack({ a }: { a: AvatarConfig }) {
  if (a.hair === "long") return <path d="M17 30 C16 18 22 12.5 32 12.5 C42 12.5 48 18 47 30 L48 48 H16 Z" fill={a.hairColor} {...S} />;
  if (a.hair === "bob") return <path d="M16.5 32 C15.5 18 22 12.5 32 12.5 C42 12.5 48.5 18 47.5 32 L46 39 H18 Z" fill={a.hairColor} {...S} />;
  return null;
}

function HairFront({ a }: { a: AvatarConfig }) {
  const f = a.hairColor;
  switch (a.hair) {
    case "buzz":
      return <path d="M18.5 27 C18.5 19 24 15.5 32 15.5 C40 15.5 45.5 19 45.5 27 C40 22.5 24 22.5 18.5 27 Z" fill={f} {...S} strokeWidth={2} />;
    case "bob":
      return <path d="M17.5 27 C18 18.5 24 14.5 32 14.5 C40 14.5 46 18.5 46.5 27 C41 24 37 21 34 18 C30 22 24 25 17.5 27 Z" fill={f} {...S} />;
    case "curly":
      return (
        <path
          d="M16.5 29 C14 25 16 20 19.5 19 C19.5 14.5 24 12 27.5 13.5 C29.5 10.5 35 10.5 37 13.5 C41 12 45 15 44.5 19 C48 20.5 49.5 25 47 29 C44 26 41 25.5 38 26 C35 23.5 29 23.5 26 26 C23 25.5 19.5 26 16.5 29 Z"
          fill={f}
          {...S}
        />
      );
    case "bun":
      return (
        <>
          <circle cx="32" cy="11" r="5.5" fill={f} {...S} />
          <path d="M17.5 28 C18 19 24 15 32 15 C40 15 46 19 46.5 28 C42 23 37 21 32 21 C27 21 22 23 17.5 28 Z" fill={f} {...S} />
        </>
      );
    case "long":
      return <path d="M17.5 28 C18 19 24 15 32 15 C40 15 46 19 46.5 28 C43 22 36 19.5 32 19.5 C28 22 22 25 17.5 28 Z" fill={f} {...S} />;
    case "swoop":
      return <path d="M17.5 28 C17 19 23 13.5 33 14 C41 14.5 47 19 46.5 27 C42 21 34 20 26 24 C23 25.5 20 26.5 17.5 28 Z" fill={f} {...S} />;
    default:
      return null;
  }
}

function Face({ a }: { a: AvatarConfig }) {
  const eyes = (() => {
    switch (a.eyes) {
      case "happy":
        return <path d="M24.5 31 q2 -2.4 4 0 M35.5 31 q2 -2.4 4 0" {...S} strokeWidth={2} fill="none" />;
      case "sleepy":
        return <path d="M24.5 30.5 q2 1.8 4 0 M35.5 30.5 q2 1.8 4 0" {...S} strokeWidth={2} fill="none" />;
      case "wink":
        return (
          <>
            <circle cx="26.5" cy="30.5" r="1.8" fill={INK} />
            <path d="M35.5 31 q2 -2.4 4 0" {...S} strokeWidth={2} fill="none" />
          </>
        );
      default:
        return (
          <>
            <circle cx="26.5" cy="30.5" r="1.8" fill={INK} />
            <circle cx="37.5" cy="30.5" r="1.8" fill={INK} />
          </>
        );
    }
  })();
  const mouth = (() => {
    switch (a.mouth) {
      case "grin":
        return <path d="M27.5 36 q4.5 5 9 0 Z" fill="#7a1d2c" {...S} strokeWidth={1.8} />;
      case "flat":
        return <path d="M29 37 h6" {...S} strokeWidth={2} />;
      case "o":
        return <ellipse cx="32" cy="37.5" rx="1.9" ry="2.3" fill="#7a1d2c" {...S} strokeWidth={1.6} />;
      default:
        return <path d="M28.5 36 q3.5 3.4 7 0" {...S} strokeWidth={2} fill="none" />;
    }
  })();
  return (
    <>
      {eyes}
      {mouth}
      {a.cheeks && (
        <>
          <ellipse cx="22.5" cy="35" rx="2.4" ry="1.5" fill="#c8545f" opacity="0.28" />
          <ellipse cx="41.5" cy="35" rx="2.4" ry="1.5" fill="#c8545f" opacity="0.28" />
        </>
      )}
    </>
  );
}

function Body({ a }: { a: AvatarConfig }) {
  const c = a.outfitColor;
  return (
    <g>
      <path d="M12 64 C12 52 20 46 32 46 C44 46 52 52 52 64 Z" fill={c} {...S} />
      {a.outfit === "hoodie" && <path d="M24 47 C25 52 39 52 40 47 M29 52 v5 M35 52 v5" {...S} strokeWidth={1.8} fill="none" />}
      {a.outfit === "stripe" && <path d="M14.5 56 H49.5 M13 61 H51" stroke="#fbf6ec" strokeWidth="2.6" />}
      {a.outfit === "overalls" && (
        <>
          <path d="M22 64 V54 H42 V64" fill="#a9c3d4" {...S} strokeWidth={1.8} />
          <path d="M22 54 L20 47.5 M42 54 L44 47.5" {...S} strokeWidth={1.8} />
        </>
      )}
      {a.outfit === "sweater" && <path d="M26 47.5 q6 4 12 0 M16 58 h4 M44 58 h4" {...S} strokeWidth={1.8} fill="none" />}
      {a.outfit === "tee" && <path d="M27 47 q5 3.5 10 0" {...S} strokeWidth={1.8} fill="none" />}
    </g>
  );
}

function Accessory({ a }: { a: AvatarConfig }) {
  switch (a.accessory) {
    case "glasses":
      return (
        <g fill="none" {...S} strokeWidth={1.8}>
          <circle cx="26.5" cy="30.5" r="4.2" />
          <circle cx="37.5" cy="30.5" r="4.2" />
          <path d="M30.7 30.5 h2.6" />
        </g>
      );
    case "beanie":
      return (
        <>
          <path d="M17 25 C17 15 24 11 32 11 C40 11 47 15 47 25 Z" fill="#e09a5f" {...S} />
          <path d="M16 23.5 H48 V27.5 H16 Z" fill="#fbf6ec" {...S} strokeWidth={2} />
          <circle cx="32" cy="9.5" r="3" fill="#fbf6ec" {...S} strokeWidth={2} />
        </>
      );
    case "flower":
      return (
        <g transform="translate(42 18)">
          {[0, 72, 144, 216, 288].map((r) => (
            <ellipse key={r} cx="0" cy="-3.2" rx="2.3" ry="3" fill="#d9a3a0" {...S} strokeWidth={1.4} transform={`rotate(${r})`} />
          ))}
          <circle r="2" fill="#d4ad55" {...S} strokeWidth={1.4} />
        </g>
      );
    case "headphones":
      return (
        <>
          <path d="M16.5 31 C16 19 23 13 32 13 C41 13 48 19 47.5 31" {...S} strokeWidth={2.6} fill="none" />
          <rect x="13.5" y="28" width="6" height="9" rx="2.5" fill="#6f1725" {...S} strokeWidth={2} />
          <rect x="44.5" y="28" width="6" height="9" rx="2.5" fill="#6f1725" {...S} strokeWidth={2} />
        </>
      );
    case "cap":
      return (
        <>
          <path d="M17.5 25 C17.5 16 24 12.5 32 12.5 C40 12.5 46.5 16 46.5 25 Z" fill="#8fa382" {...S} />
          <path d="M30 25 H52 a2 2 0 0 1 -2 3 H30 Z" fill="#8fa382" {...S} strokeWidth={2} />
        </>
      );
    case "bandana":
      return <path d="M17.5 24 C20 18 26 15 32 15 C38 15 44 18 46.5 24 C40 22 24 22 17.5 24 Z M44 23 l6 -2 l-2 5 Z" fill="#b4473a" {...S} strokeWidth={2} />;
    default:
      return null;
  }
}

function Companion({ kind }: { kind: AvatarConfig["companion"] }) {
  if (kind === "none") return null;
  return (
    <g transform="translate(46 46)">
      {kind === "sprout" && (
        <>
          <path d="M6 14 C6 8 6.5 5 8 2" {...S} strokeWidth={1.8} fill="none" />
          <path d="M8 4 C10 0 15 0 16 2 C14 5 10 6 8 4 Z" fill="#8fa382" {...S} strokeWidth={1.6} />
          <path d="M6.5 7 C4 4 0 4 -1 6 C1 8 4.5 9 6.5 7 Z" fill="#8fa382" {...S} strokeWidth={1.6} />
          <path d="M1 12 H12 L11 17 H2 Z" fill="#e09a5f" {...S} strokeWidth={1.6} />
        </>
      )}
      {kind === "cat" && (
        <>
          <path d="M0 16 C0 9 3 6 7 6 C11 6 14 9 14 16 Z M1.5 8 L1 2.5 L5 6 M12.5 8 L13 2.5 L9 6" fill="#e09a5f" {...S} strokeWidth={1.6} />
          <circle cx="5" cy="11" r="0.9" fill={INK} />
          <circle cx="9" cy="11" r="0.9" fill={INK} />
        </>
      )}
      {kind === "snail" && (
        <>
          <path d="M-1 16 H15 C15 14 13 13 11 13" fill="none" {...S} strokeWidth={1.6} />
          <circle cx="6" cy="10" r="5.5" fill="#d4ad55" {...S} strokeWidth={1.6} />
          <path d="M6 10 m-2 0 a2 2 0 1 0 2 -2" fill="none" {...S} strokeWidth={1.3} />
          <path d="M13 13 L14 7 M15 13 L17 8" {...S} strokeWidth={1.3} />
        </>
      )}
      {kind === "bird" && (
        <>
          <path d="M1 12 C1 6 5 4 8 4 C12 4 14 7 14 11 C14 15 10 16 6 16 C3 16 1 14.5 1 12 Z" fill="#a9c3d4" {...S} strokeWidth={1.6} />
          <path d="M14 8 L17.5 9 L14 10.5" fill="#e09a5f" {...S} strokeWidth={1.3} />
          <circle cx="10.5" cy="8" r="0.9" fill={INK} />
        </>
      )}
    </g>
  );
}

function Frame({ kind }: { kind: AvatarConfig["frame"] }) {
  switch (kind) {
    case "stamp":
      return <circle cx="32" cy="32" r="30" fill="none" stroke="#6f1725" strokeWidth="2.2" strokeDasharray="3 3.4" />;
    case "scallop":
      return (
        <g fill="none" stroke="#6f1725" strokeWidth="2">
          {Array.from({ length: 16 }, (_, i) => {
            const a = (i / 16) * Math.PI * 2;
            return <circle key={i} cx={32 + Math.cos(a) * 29.5} cy={32 + Math.sin(a) * 29.5} r="3.6" />;
          })}
        </g>
      );
    case "gold":
      return <circle cx="32" cy="32" r="30.5" fill="none" stroke="#d4ad55" strokeWidth="3.5" />;
    case "tape":
      return <rect x="20" y="-1" width="24" height="7" fill="rgb(233 214 168 / 0.85)" transform="rotate(-8 32 3)" />;
    default:
      return null;
  }
}

export function AvatarArt({ config, size = 40, className, title }: { config: AvatarConfig; size?: number; className?: string; title?: string }) {
  const clipId = `av-${config.head}-${config.hair}-${config.outfit}`;
  return (
    <svg viewBox="0 0 64 64" width={size} height={size} className={cn("shrink-0 overflow-visible", className)} role={title ? "img" : undefined} aria-label={title} aria-hidden={title ? undefined : true}>
      <defs>
        <clipPath id={clipId}>
          <circle cx="32" cy="32" r="30" />
        </clipPath>
      </defs>
      <circle cx="32" cy="32" r="30" fill={BG_SOFT[config.background] ?? BG_SOFT.cream} />
      <circle cx="32" cy="32" r="30" fill={TINT_HEX[config.background]} opacity="0.18" />
      <g clipPath={`url(#${clipId})`}>
        <HairBack a={config} />
        <Body a={config} />
        <Head a={config} />
        <Face a={config} />
        <HairFront a={config} />
        <Accessory a={config} />
      </g>
      <circle cx="32" cy="32" r="30" fill="none" stroke={INK} strokeOpacity="0.85" strokeWidth="1.6" />
      <Frame kind={config.frame} />
      <Companion kind={config.companion} />
    </svg>
  );
}

/** Avatar for a user. Shows the companion only at larger sizes to stay legible. */
export function Avatar({ user, size = 40, className, ring }: { user: Pick<User, "name" | "avatar">; size?: number; className?: string; ring?: boolean }) {
  const config = size < 44 ? { ...user.avatar, companion: "none" as const, frame: user.avatar.frame === "tape" ? ("none" as const) : user.avatar.frame } : user.avatar;
  return (
    <span className={cn("inline-grid shrink-0 place-items-center rounded-full", ring && "ring-2 ring-cream", className)} style={{ width: size, height: size }}>
      <AvatarArt config={config} size={size} title={user.name} />
    </span>
  );
}
