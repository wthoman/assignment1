"use client";

import { AnimatePresence, motion } from "motion/react";
import { Bell, BookHeart, CalendarCheck2, Gift, Palette, Plus, Settings, Share2, Sparkles, UserRound, Users, UsersRound } from "lucide-react";
import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";
import { useEffect, useState, type ReactNode } from "react";
import { Avatar } from "@/components/avatar/Avatar";
import { Logo } from "@/components/brand/Logo";
import { BottomSheet } from "@/components/ui/BottomSheet";
import { BRAND } from "@/lib/brand";
import { cn } from "@/lib/cn";
import { useAppState, useMe } from "@/lib/store/provider";

export const PRIMARY_NAV = [
  { href: "/today", label: "Today", icon: CalendarCheck2 },
  { href: "/friends", label: "Friends", icon: Users },
  { href: "/collection", label: "Collection", icon: BookHeart },
  { href: "/recap", label: "Recap", icon: Sparkles },
] as const;

export const SECONDARY_NAV = [
  { href: "/groups", label: "Groups", icon: UsersRound },
  { href: "/profile", label: "Profile", icon: UserRound },
  { href: "/profile/avatar", label: "Avatar & cosmetics", icon: Palette },
  { href: "/notifications", label: "Notifications", icon: Bell },
  { href: "/share", label: "Share & export", icon: Share2 },
  { href: "/settings", label: "Settings", icon: Settings },
] as const;

function isActive(pathname: string, href: string) {
  if (href === "/profile") return pathname === "/profile";
  return pathname === href || pathname.startsWith(href + "/");
}

function useUnreadCount() {
  const { notifications } = useAppState();
  return notifications.filter((n) => !n.read).length;
}

/* ---------- Mobile bottom navigation ---------- */
function BottomNav() {
  const pathname = usePathname();
  const items = [PRIMARY_NAV[0], PRIMARY_NAV[1], null, PRIMARY_NAV[2], PRIMARY_NAV[3]];
  return (
    <nav aria-label="Primary" className="fixed inset-x-0 bottom-0 z-40 border-t border-line bg-cream/95 pb-[env(safe-area-inset-bottom)] backdrop-blur-[2px] md:hidden">
      <ul className="mx-auto grid h-[4.25rem] max-w-lg grid-cols-5 items-center px-1">
        {items.map((item) => {
          if (!item)
            return (
              <li key="add" className="flex justify-center">
                <Link
                  href="/habits/new"
                  aria-label="New habit"
                  className="-mt-6 grid size-14 place-items-center rounded-[18px] border-[3px] border-paper bg-accent text-on-accent shadow-[var(--shadow-lift)] transition-transform active:scale-95"
                  style={{ transform: "rotate(-4deg)" }}
                >
                  <Plus size={26} strokeWidth={2.6} />
                </Link>
              </li>
            );
          const active = isActive(pathname, item.href);
          const Icon = item.icon;
          return (
            <li key={item.href}>
              <Link href={item.href} aria-current={active ? "page" : undefined} className="relative flex min-h-14 flex-col items-center justify-center gap-0.5 rounded-[14px]">
                <Icon size={22} strokeWidth={active ? 2.4 : 1.9} className={active ? "text-accent" : "text-muted"} aria-hidden />
                <span className={cn("text-[0.6875rem] font-semibold", active ? "text-accent" : "text-muted")}>{item.label}</span>
                {active && <motion.span layoutId="nav-dot" className="absolute -top-px h-[3px] w-7 rounded-b-full bg-accent" />}
              </Link>
            </li>
          );
        })}
      </ul>
    </nav>
  );
}

/* ---------- Desktop side rail ---------- */
function SideRail() {
  const pathname = usePathname();
  const me = useMe();
  const unread = useUnreadCount();
  const link = (item: { href: string; label: string; icon: typeof Bell }, badge?: number) => {
    const active = isActive(pathname, item.href);
    const Icon = item.icon;
    return (
      <li key={item.href}>
        <Link
          href={item.href}
          aria-current={active ? "page" : undefined}
          title={item.label}
          className={cn(
            "group relative flex min-h-11 items-center gap-3 rounded-[13px] px-3 font-display text-[0.9375rem] font-semibold transition-colors",
            active ? "bg-accent text-on-accent" : "text-ink hover:bg-accent-soft",
          )}
        >
          <Icon size={20} strokeWidth={active ? 2.3 : 1.9} aria-hidden className="shrink-0" />
          <span className="hidden lg:inline">{item.label}</span>
          {badge ? (
            <span className={cn("ml-auto grid min-w-5 place-items-center rounded-full px-1 text-[0.6875rem] font-bold max-lg:absolute max-lg:right-1 max-lg:top-1", active ? "bg-cream text-accent" : "bg-accent text-on-accent")}>{badge}</span>
          ) : null}
        </Link>
      </li>
    );
  };
  return (
    <aside className="sticky top-0 hidden h-dvh w-[76px] shrink-0 flex-col border-r border-line bg-cream/70 px-3 py-5 md:flex lg:w-[232px] lg:px-4">
      <Link href="/today" className="mb-6 flex items-center px-1.5" aria-label={`${BRAND.name} home`}>
        <Logo size={30} showName={false} className="lg:hidden" />
        <Logo size={30} className="hidden lg:inline-flex" />
      </Link>
      <Link
        href="/habits/new"
        className="mb-5 flex min-h-11 items-center justify-center gap-2 rounded-[13px] bg-accent font-display text-[0.9375rem] font-semibold text-on-accent shadow-[0_2px_0_rgb(0_0_0/0.18)] transition-transform hover:bg-accent-hover active:scale-[0.98]"
      >
        <Plus size={19} strokeWidth={2.5} aria-hidden />
        <span className="hidden lg:inline">New habit</span>
        <span className="sr-only lg:hidden">New habit</span>
      </Link>
      <nav aria-label="Primary" className="flex-1 overflow-y-auto no-scrollbar">
        <ul className="space-y-1">{PRIMARY_NAV.map((i) => link(i))}</ul>
        <div className="hand-divider my-4" aria-hidden />
        <ul className="space-y-1">
          {SECONDARY_NAV.map((i) => link(i, i.href === "/notifications" ? unread : undefined))}
        </ul>
      </nav>
      <Link href="/profile" className="mt-4 flex items-center gap-2.5 rounded-[14px] p-1.5 transition-colors hover:bg-accent-soft">
        <Avatar user={me} size={38} />
        <span className="hidden min-w-0 lg:block">
          <span className="block truncate font-display text-sm font-bold text-ink">{me.name}</span>
          <span className="block truncate text-xs text-muted">@{me.handle}</span>
        </span>
      </Link>
    </aside>
  );
}

/* ---------- Mobile "more" menu (opened from the avatar in any TopBar) ---------- */
export function AccountMenuSheet({ open, onClose }: { open: boolean; onClose: () => void }) {
  const me = useMe();
  const unread = useUnreadCount();
  const state = useAppState();
  const pendingGifts = state.gifts.filter((g) => g.toId === state.meId && !g.opened).length;
  return (
    <BottomSheet open={open} onClose={onClose} title="Menu" hideTitle size="sm">
      <div className="flex items-center gap-3 pb-4 pt-1">
        <Avatar user={me} size={56} />
        <div className="min-w-0">
          <p className="font-display text-lg font-bold text-ink">{me.name}</p>
          <p className="text-sm text-muted">@{me.handle}</p>
        </div>
      </div>
      <ul className="grid grid-cols-2 gap-2">
        {SECONDARY_NAV.map((item) => {
          const Icon = item.icon;
          const badge = item.href === "/notifications" ? unread : item.href === "/profile/avatar" ? pendingGifts : 0;
          return (
            <li key={item.href}>
              <Link href={item.href} onClick={onClose} className="relative flex min-h-[4.5rem] flex-col justify-between rounded-[16px] border border-line bg-paper/60 p-3 transition-colors hover:bg-accent-soft">
                <Icon size={20} className="text-accent" aria-hidden />
                <span className="font-display text-sm font-semibold text-ink">{item.label}</span>
                {badge > 0 && <span className="absolute right-2.5 top-2.5 grid min-w-5 place-items-center rounded-full bg-accent px-1 text-[0.6875rem] font-bold text-on-accent">{badge}</span>}
              </Link>
            </li>
          );
        })}
      </ul>
      {pendingGifts > 0 && (
        <Link href="/profile/avatar" onClick={onClose} className="mt-3 flex items-center gap-2 rounded-[14px] bg-gold-soft px-3 py-2.5 text-sm font-semibold text-ink">
          <Gift size={18} className="text-accent" aria-hidden /> You have {pendingGifts} unopened gift{pendingGifts > 1 ? "s" : ""}
        </Link>
      )}
    </BottomSheet>
  );
}

/** Bell + avatar cluster used in page headers. */
export function HeaderActions({ className }: { className?: string }) {
  const me = useMe();
  const unread = useUnreadCount();
  const [menu, setMenu] = useState(false);
  return (
    <div className={cn("flex items-center gap-1", className)}>
      <Link href="/notifications" aria-label={unread ? `Notifications, ${unread} unread` : "Notifications"} className="relative grid size-11 place-items-center rounded-[13px] text-ink transition-colors hover:bg-accent-soft">
        <Bell size={21} aria-hidden />
        <AnimatePresence>
          {unread > 0 && (
            <motion.span
              initial={{ scale: 0 }}
              animate={{ scale: 1 }}
              exit={{ scale: 0 }}
              className="absolute right-1.5 top-1.5 grid min-w-[18px] place-items-center rounded-full border-2 border-paper bg-accent px-1 text-[0.625rem] font-bold leading-[14px] text-on-accent"
            >
              {unread}
            </motion.span>
          )}
        </AnimatePresence>
      </Link>
      <button type="button" onClick={() => setMenu(true)} aria-label="Open menu" className="rounded-full p-0.5 transition-transform active:scale-95 md:hidden">
        <Avatar user={me} size={38} />
      </button>
      <Link href="/profile" aria-label="Your profile" className="hidden rounded-full p-0.5 md:block">
        <Avatar user={me} size={38} />
      </Link>
      <AccountMenuSheet open={menu} onClose={() => setMenu(false)} />
    </div>
  );
}

export function AppShell({ children }: { children: ReactNode }) {
  const pathname = usePathname();
  return (
    <div className="relative z-[1] flex min-h-dvh">
      <a href="#main" className="sr-only z-[100] rounded-[10px] bg-accent px-4 py-2 text-on-accent focus:not-sr-only focus:fixed focus:left-3 focus:top-3">
        Skip to content
      </a>
      <SideRail />
      <div className="min-w-0 flex-1">
        <motion.main
          id="main"
          key={pathname}
          initial={{ opacity: 0, y: 6 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.22, ease: [0.22, 1, 0.36, 1] }}
          className="pb-[calc(6rem+env(safe-area-inset-bottom))] md:pb-10"
        >
          {children}
        </motion.main>
      </div>
      <BottomNav />
    </div>
  );
}

/** Redirects to onboarding until the user has finished it. */
export function OnboardingGate({ children }: { children: ReactNode }) {
  const { session } = useAppState();
  const router = useRouter();
  useEffect(() => {
    if (!session.onboarded) router.replace("/onboarding");
  }, [session.onboarded, router]);
  if (!session.onboarded) return null;
  return <>{children}</>;
}
