"use client";

import { ChevronLeft } from "lucide-react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import type { ReactNode } from "react";
import { cn } from "@/lib/cn";
import { HeaderActions } from "./AppShell";

/**
 * Standard page frame. Main column is constrained to a comfortable reading width;
 * `aside` becomes a sticky secondary column on wide screens and stacks below on phones
 * (or is hidden there with `asideOnMobile={false}`).
 */
export function Page({
  title,
  eyebrow,
  subtitle,
  back,
  actions,
  headerExtra,
  aside,
  asideOnMobile = true,
  children,
  wide = false,
  hideHeaderActions = false,
}: {
  title: ReactNode;
  eyebrow?: ReactNode;
  subtitle?: ReactNode;
  /** A path, or `true` to go back in history. */
  back?: string | true;
  actions?: ReactNode;
  headerExtra?: ReactNode;
  aside?: ReactNode;
  asideOnMobile?: boolean;
  children: ReactNode;
  wide?: boolean;
  hideHeaderActions?: boolean;
}) {
  return (
    <div className={cn("mx-auto w-full px-4 sm:px-6", aside ? "max-w-[1120px]" : wide ? "max-w-[960px]" : "max-w-[720px]")}>
      <PageHeader title={title} eyebrow={eyebrow} subtitle={subtitle} back={back} actions={actions} hideHeaderActions={hideHeaderActions}>
        {headerExtra}
      </PageHeader>
      {aside ? (
        <div className="lg:grid lg:grid-cols-[minmax(0,1fr)_320px] lg:gap-8">
          <div className="min-w-0">{children}</div>
          <aside className={cn("mt-8 space-y-5 lg:sticky lg:top-6 lg:mt-0 lg:self-start", !asideOnMobile && "hidden lg:block")} aria-label="Details">
            {aside}
          </aside>
        </div>
      ) : (
        children
      )}
    </div>
  );
}

export function PageHeader({
  title,
  eyebrow,
  subtitle,
  back,
  actions,
  children,
  hideHeaderActions,
}: {
  title: ReactNode;
  eyebrow?: ReactNode;
  subtitle?: ReactNode;
  back?: string | true;
  actions?: ReactNode;
  children?: ReactNode;
  hideHeaderActions?: boolean;
}) {
  const router = useRouter();
  const backCls = "-ml-2 grid size-11 shrink-0 place-items-center rounded-[13px] text-ink transition-colors hover:bg-accent-soft";
  return (
    <header className="pb-4 pt-[max(0.75rem,env(safe-area-inset-top))] md:pt-7">
      <div className="flex min-h-12 items-center gap-2">
        {back === true ? (
          <button type="button" onClick={() => router.back()} className={backCls} aria-label="Go back">
            <ChevronLeft size={24} aria-hidden />
          </button>
        ) : back ? (
          <Link href={back} className={backCls} aria-label="Go back">
            <ChevronLeft size={24} aria-hidden />
          </Link>
        ) : null}
        <div className="min-w-0 flex-1">
          {eyebrow && <p className="eyebrow">{eyebrow}</p>}
          <h1 className="line-clamp-2 break-words font-display text-[1.5rem] font-extrabold leading-[1.1] tracking-[-0.035em] text-ink sm:text-[1.625rem] md:text-[1.875rem]">{title}</h1>
        </div>
        {actions}
        {!hideHeaderActions && <HeaderActions />}
      </div>
      {subtitle && <p className="mt-1 max-w-prose text-[0.9375rem] leading-relaxed text-muted">{subtitle}</p>}
      {children}
    </header>
  );
}
