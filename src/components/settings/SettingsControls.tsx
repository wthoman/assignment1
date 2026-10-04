"use client";

import { ChevronDown } from "lucide-react";
import type { ReactNode, SelectHTMLAttributes } from "react";
import { cn } from "@/lib/cn";

/** Styled native <select>; keeps platform pickers on phones. */
export function NativeSelect({ className, children, ...rest }: SelectHTMLAttributes<HTMLSelectElement> & { children: ReactNode }) {
  return (
    <span className={cn("relative inline-flex w-full", className)}>
      <select
        {...rest}
        className="min-h-11 w-full appearance-none rounded-[12px] border border-line-strong bg-cream py-2 pl-3 pr-9 text-[0.9375rem] text-ink focus:border-accent focus:outline-none focus:ring-3 focus:ring-accent/15 disabled:opacity-50"
      >
        {children}
      </select>
      <ChevronDown size={16} className="pointer-events-none absolute right-3 top-1/2 -translate-y-1/2 text-muted" aria-hidden />
    </span>
  );
}

/** A labelled block inside a SettingsGroup that holds a wider control (segmented, swatches…). */
export function SettingsBlock({ label, detail, children, id }: { label: string; detail?: string; children: ReactNode; id?: string }) {
  return (
    <div className="space-y-2.5 px-4 py-3.5" id={id}>
      <div>
        <p className="text-[0.9375rem] font-semibold text-ink">{label}</p>
        {detail && <p className="mt-0.5 text-[0.8125rem] leading-snug text-muted">{detail}</p>}
      </div>
      {children}
    </div>
  );
}
