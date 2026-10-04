import Link from "next/link";
import { forwardRef, type ButtonHTMLAttributes, type ComponentProps, type ReactNode } from "react";
import { cn } from "@/lib/cn";

type Variant = "primary" | "secondary" | "soft" | "ghost" | "danger";
type Size = "sm" | "md" | "lg";

const base =
  "relative inline-flex items-center justify-center gap-2 font-display font-semibold tracking-[-0.01em] transition-[transform,background-color,box-shadow,color] duration-150 active:scale-[0.97] disabled:opacity-45 disabled:pointer-events-none select-none whitespace-nowrap";

const variants: Record<Variant, string> = {
  primary: "bg-accent text-on-accent hover:bg-accent-hover shadow-[0_2px_0_rgb(0_0_0/0.18)]",
  secondary: "bg-cream text-accent border border-line-strong hover:bg-accent-soft",
  soft: "bg-accent-soft text-accent hover:brightness-[0.97]",
  ghost: "text-accent hover:bg-accent-soft",
  danger: "bg-[#8e2a1e] text-[#fbf6ec] hover:bg-[#76221a]",
};

const sizes: Record<Size, string> = {
  sm: "min-h-9 px-3 text-sm rounded-[11px]",
  md: "min-h-11 px-4 text-[0.9375rem] rounded-[13px]",
  lg: "min-h-13 px-5 text-base rounded-[15px]",
};

export interface ButtonProps extends ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: Variant;
  size?: Size;
  icon?: ReactNode;
  block?: boolean;
}

export const Button = forwardRef<HTMLButtonElement, ButtonProps>(function Button(
  { variant = "primary", size = "md", icon, block, className, children, type = "button", ...rest },
  ref,
) {
  return (
    <button ref={ref} type={type} className={cn(base, variants[variant], sizes[size], block && "w-full", className)} {...rest}>
      {icon}
      {children}
    </button>
  );
});

export function ButtonLink({
  variant = "primary",
  size = "md",
  icon,
  block,
  className,
  children,
  ...rest
}: ComponentProps<typeof Link> & { variant?: Variant; size?: Size; icon?: ReactNode; block?: boolean }) {
  return (
    <Link className={cn(base, variants[variant], sizes[size], block && "w-full", className)} {...rest}>
      {icon}
      {children}
    </Link>
  );
}

export const IconButton = forwardRef<HTMLButtonElement, ButtonHTMLAttributes<HTMLButtonElement> & { label: string; tone?: "plain" | "soft" | "solid"; size?: "sm" | "md" }>(
  function IconButton({ label, tone = "plain", size = "md", className, children, type = "button", ...rest }, ref) {
    return (
      <button
        ref={ref}
        type={type}
        aria-label={label}
        title={label}
        className={cn(
          "relative inline-grid shrink-0 place-items-center rounded-[13px] transition-[transform,background-color] duration-150 active:scale-[0.94] disabled:opacity-40",
          size === "md" ? "size-11" : "size-9 before:absolute before:-inset-1 before:content-['']",
          tone === "plain" && "text-ink hover:bg-accent-soft",
          tone === "soft" && "bg-cream border border-line text-accent hover:bg-accent-soft",
          tone === "solid" && "bg-accent text-on-accent hover:bg-accent-hover",
          className,
        )}
        {...rest}
      >
        {children}
      </button>
    );
  },
);
