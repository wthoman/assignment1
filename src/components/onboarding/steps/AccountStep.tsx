"use client";

import { Eye, EyeOff, LoaderCircle, Mail, Smartphone, Globe } from "lucide-react";
import { useEffect, useRef, useState } from "react";
import { Button, IconButton } from "@/components/ui/Button";
import { Field, Segmented, TextInput } from "@/components/ui/controls";
import { useDispatch, useMe } from "@/lib/store/provider";
import type { Account } from "@/lib/types";
import { StepShell } from "../StepShell";

export type AuthMode = "signup" | "login";
type Method = Account["method"];

const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/;
const DELAY = 700;

function validate(email: string, password: string) {
  return {
    email: !email.trim() ? "Enter your email address." : !EMAIL_RE.test(email.trim()) ? "That doesn't look like an email address." : undefined,
    password: !password ? "Enter a password." : password.length < 8 ? "Passwords need at least 8 characters." : undefined,
  };
}

export function AccountStep({ mode, onModeChange, onDone }: { mode: AuthMode; onModeChange: (m: AuthMode) => void; onDone: (mode: AuthMode) => void }) {
  const dispatch = useDispatch();
  const me = useMe();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [show, setShow] = useState(false);
  const [attempted, setAttempted] = useState(false);
  const [loading, setLoading] = useState<Method | null>(null);
  const [formError, setFormError] = useState<string | null>(null);
  const [resetSent, setResetSent] = useState(false);
  const timer = useRef<ReturnType<typeof setTimeout> | null>(null);

  useEffect(() => () => {
    if (timer.current) clearTimeout(timer.current);
  }, []);

  const errors: { email?: string; password?: string } = attempted ? validate(email, password) : {};
  const login = mode === "login";

  const finish = (method: Method, address: string) => {
    dispatch({ type: "session/account", account: { email: address, method, createdAt: new Date().toISOString() } });
    setPassword("");
    setLoading(null);
    onDone(mode);
  };

  const submit = () => {
    if (loading) return;
    setAttempted(true);
    setFormError(null);
    const v = validate(email, password);
    if (v.email || v.password) return;
    setLoading("email");
    timer.current = setTimeout(() => {
      if (login && password === "wrongpass") {
        setLoading(null);
        setFormError("That password doesn't match. Try again or reset it.");
        return;
      }
      finish("email", email.trim().toLowerCase());
    }, DELAY);
  };

  const social = (method: Exclude<Method, "email">) => {
    if (loading) return;
    setFormError(null);
    setLoading(method);
    const handle = me.handle || "you";
    timer.current = setTimeout(() => finish(method, method === "apple" ? `${handle}@privaterelay.appleid.com` : `${handle}@gmail.com`), DELAY);
  };

  const switchMode = (m: AuthMode) => {
    onModeChange(m);
    setFormError(null);
    setAttempted(false);
    setResetSent(false);
  };

  return (
    <StepShell
      eyebrow={login ? "Welcome back" : "Your account"}
      title={login ? "Log in to your daybook" : "Make your daybook"}
      description={login ? "Pick up right where you left off." : "Just an email and a password. You can add a photo and friends in a minute."}
      onSubmit={submit}
      footer={
        <Button type="submit" size="lg" block disabled={loading !== null && loading !== "email"} aria-busy={loading === "email"}>
          {loading === "email" ? (
            <>
              <LoaderCircle size={18} className="animate-spin" aria-hidden />
              {login ? "Logging in…" : "Creating account…"}
            </>
          ) : login ? (
            "Log in"
          ) : (
            "Create account"
          )}
        </Button>
      }
    >
      <Segmented
        label="Account"
        value={mode}
        onChange={switchMode}
        options={[
          { value: "signup", label: "Sign up" },
          { value: "login", label: "Log in" },
        ]}
        className="mb-5"
      />

      <div className="space-y-2.5">
        <Button variant="secondary" block icon={loading === "apple" ? <LoaderCircle size={18} className="animate-spin" aria-hidden /> : <Smartphone size={18} aria-hidden />} onClick={() => social("apple")} disabled={loading !== null} aria-busy={loading === "apple"}>
          Continue with Apple
        </Button>
        <Button variant="secondary" block icon={loading === "google" ? <LoaderCircle size={18} className="animate-spin" aria-hidden /> : <Globe size={18} aria-hidden />} onClick={() => social("google")} disabled={loading !== null} aria-busy={loading === "google"}>
          Continue with Google
        </Button>
      </div>

      <div className="my-5 flex items-center gap-3 text-xs font-semibold uppercase tracking-[0.08em] text-faint" aria-hidden>
        <span className="hand-divider flex-1" />
        or with email
        <span className="hand-divider flex-1" />
      </div>

      <div className="space-y-4">
        <Field label="Email" htmlFor="ob-email" error={errors.email}>
          <div className="relative">
            <Mail size={18} className="pointer-events-none absolute left-3.5 top-1/2 -translate-y-1/2 text-faint" aria-hidden />
            <TextInput
              id="ob-email"
              type="email"
              inputMode="email"
              autoComplete="email"
              autoCapitalize="none"
              spellCheck={false}
              placeholder="you@example.com"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              invalid={!!errors.email}
              disabled={loading !== null}
              className="pl-10"
            />
          </div>
        </Field>

        <Field label="Password" htmlFor="ob-password" error={errors.password} hint={login ? undefined : "At least 8 characters."}>
          <div className="relative">
            <TextInput
              id="ob-password"
              type={show ? "text" : "password"}
              autoComplete={login ? "current-password" : "new-password"}
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              invalid={!!errors.password || !!formError}
              disabled={loading !== null}
              className="pr-12"
            />
            <IconButton label={show ? "Hide password" : "Show password"} onClick={() => setShow((s) => !s)} className="absolute right-0.5 top-1/2 -translate-y-1/2 text-muted" aria-pressed={show}>
              {show ? <EyeOff size={18} aria-hidden /> : <Eye size={18} aria-hidden />}
            </IconButton>
          </div>
        </Field>

        {formError && (
          <div role="alert" className="rounded-[13px] border border-[#a3301f]/30 bg-[#f6ddd6] px-3.5 py-3 text-sm font-medium text-[#8e2a1e] dark:bg-[#4a2228] dark:text-[#f0a090]">
            {formError}
          </div>
        )}

        {login && (
          <div className="flex flex-wrap items-center gap-x-2">
            <button
              type="button"
              onClick={() => setResetSent(true)}
              className="min-h-11 text-sm font-semibold text-accent underline decoration-dashed underline-offset-4"
            >
              Forgot password?
            </button>
            {resetSent && (
              <span className="text-sm text-muted" role="status">
                {EMAIL_RE.test(email.trim()) ? `Reset link sent to ${email.trim()}.` : "Enter your email above and we'll send a link."}
              </span>
            )}
          </div>
        )}

        <p className="pt-1 text-xs leading-relaxed text-faint">
          This is a prototype: nothing leaves your device and your password is never saved.
          {login && " Tip: try the password “wrongpass” to see the error state."}
        </p>
      </div>
    </StepShell>
  );
}
