import { Check } from "lucide-react";
import { cn } from "@/lib/cn";
import type { User } from "@/lib/types";
import { Avatar } from "./Avatar";

/** Overlapping avatars. Users in `doneIds` get a small check badge. */
export function FriendAvatarStack({ users, size = 26, max = 4, doneIds, className, label }: { users: User[]; size?: number; max?: number; doneIds?: string[]; className?: string; label?: string }) {
  const shown = users.slice(0, max);
  const extra = users.length - shown.length;
  const names = users.map((u) => u.name.split(" ")[0]).join(", ");
  return (
    <span className={cn("inline-flex items-center", className)} aria-label={label ?? `With ${names}`} role="img">
      {shown.map((u, i) => (
        <span key={u.id} className="relative rounded-full bg-cream" style={{ marginLeft: i ? -size * 0.32 : 0, zIndex: shown.length - i }}>
          <Avatar user={u} size={size} />
          {doneIds?.includes(u.id) && (
            <span className="absolute -bottom-0.5 -right-0.5 grid size-3.5 place-items-center rounded-full border border-cream bg-sage text-[#1f2a1a]">
              <Check size={9} strokeWidth={4} />
            </span>
          )}
        </span>
      ))}
      {extra > 0 && (
        <span
          className="relative grid place-items-center rounded-full border border-line bg-paper-deep font-display text-[0.6875rem] font-bold text-muted"
          style={{ width: size, height: size, marginLeft: -size * 0.32 }}
        >
          +{extra}
        </span>
      )}
    </span>
  );
}
