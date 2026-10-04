"use client";

import { KeyRound, LogOut, Mail, Trash2 } from "lucide-react";
import { useRouter } from "next/navigation";
import { useState, type FormEvent } from "react";
import { Page } from "@/components/shell/Page";
import { BottomSheet } from "@/components/ui/BottomSheet";
import { Button, ButtonLink } from "@/components/ui/Button";
import { ConfirmationDialog } from "@/components/ui/ConfirmationDialog";
import { Field, TextInput } from "@/components/ui/controls";
import { SettingsGroup, SettingsRow } from "@/components/ui/misc";
import { useToast } from "@/components/ui/Toast";
import { useAppState, useDispatch } from "@/lib/store/provider";

const METHOD_LABEL = { email: "Email & password", apple: "Sign in with Apple", google: "Sign in with Google" } as const;

interface PwDraft {
  current: string;
  next: string;
  confirm: string;
}

function pwErrors(d: PwDraft) {
  const e: Partial<Record<keyof PwDraft, string>> = {};
  if (!d.current) e.current = "Enter your current password.";
  if (d.next.length < 8) e.next = "Use at least 8 characters.";
  else if (!/\d/.test(d.next) || !/[a-z]/i.test(d.next)) e.next = "Mix in at least one letter and one number.";
  else if (d.next === d.current) e.next = "Pick something different from your current password.";
  if (!d.confirm) e.confirm = "Type the new password again.";
  else if (d.confirm !== d.next) e.confirm = "Passwords don't match.";
  return e;
}

function PasswordForm({ onDone }: { onDone: () => void }) {
  const toast = useToast();
  const [d, setD] = useState<PwDraft>({ current: "", next: "", confirm: "" });
  const [submitted, setSubmitted] = useState(false);
  const errors = pwErrors(d);
  const err = (k: keyof PwDraft) => (submitted ? errors[k] : undefined);
  const submit = (e: FormEvent) => {
    e.preventDefault();
    setSubmitted(true);
    const first = (Object.keys(errors) as (keyof PwDraft)[])[0];
    if (first) {
      document.getElementById(`pw-${first}`)?.focus();
      return;
    }
    toast({ title: "Password updated", body: "Demo only: nothing was sent anywhere.", motif: "alarm" });
    onDone();
  };
  return (
    <form id="pw-form" noValidate onSubmit={submit} className="space-y-4">
      <Field label="Current password" htmlFor="pw-current" error={err("current")}>
        <TextInput id="pw-current" type="password" autoComplete="current-password" value={d.current} onChange={(e) => setD({ ...d, current: e.target.value })} invalid={Boolean(err("current"))} data-autofocus />
      </Field>
      <Field label="New password" htmlFor="pw-next" error={err("next")} hint="At least 8 characters, with a letter and a number.">
        <TextInput id="pw-next" type="password" autoComplete="new-password" value={d.next} onChange={(e) => setD({ ...d, next: e.target.value })} invalid={Boolean(err("next"))} />
      </Field>
      <Field label="Confirm new password" htmlFor="pw-confirm" error={err("confirm")}>
        <TextInput id="pw-confirm" type="password" autoComplete="new-password" value={d.confirm} onChange={(e) => setD({ ...d, confirm: e.target.value })} invalid={Boolean(err("confirm"))} />
      </Field>
    </form>
  );
}

function DeleteForm({ onCancel, onDelete }: { onCancel: () => void; onDelete: () => void }) {
  const [text, setText] = useState("");
  const [submitted, setSubmitted] = useState(false);
  const ok = text.trim() === "DELETE";
  const error = submitted && !ok ? (text ? "That doesn't match. Type DELETE in capitals." : "Type DELETE to confirm.") : undefined;
  return (
    <form
      noValidate
      onSubmit={(e) => {
        e.preventDefault();
        setSubmitted(true);
        if (ok) onDelete();
      }}
      className="space-y-4"
    >
      <p className="text-[0.9375rem] leading-relaxed text-muted">
        This erases your habits, check-ins, stickers and friends from this device. Friends will no longer see you. <strong className="text-ink">It can&apos;t be undone.</strong>
      </p>
      <Field label="Type DELETE to confirm" htmlFor="delete-confirm" error={error}>
        <TextInput id="delete-confirm" value={text} onChange={(e) => setText(e.target.value)} invalid={Boolean(error)} autoCapitalize="characters" autoComplete="off" spellCheck={false} data-autofocus />
      </Field>
      <div className="flex flex-col-reverse gap-2 sm:flex-row sm:justify-end">
        <Button variant="secondary" onClick={onCancel}>
          Keep my account
        </Button>
        <Button type="submit" variant="danger" aria-disabled={!ok || undefined} className={ok ? undefined : "opacity-60"} icon={<Trash2 size={16} aria-hidden />}>
          Delete account
        </Button>
      </div>
    </form>
  );
}

export default function AccountSettingsPage() {
  const { session } = useAppState();
  const dispatch = useDispatch();
  const router = useRouter();
  const [pwOpen, setPwOpen] = useState(false);
  const [pwKey, setPwKey] = useState(0);
  const [delOpen, setDelOpen] = useState(false);
  const [delKey, setDelKey] = useState(0);
  const [logoutOpen, setLogoutOpen] = useState(false);
  const account = session.account;

  return (
    <Page title="Account" back="/settings">
      <div className="space-y-7">
        {account ? (
          <SettingsGroup title="Sign-in">
            <SettingsRow icon={<Mail size={18} />} label="Email" detail={account.email} />
            <SettingsRow icon={<KeyRound size={18} />} label="Sign-in method" detail={`${METHOD_LABEL[account.method]} · since ${new Date(account.createdAt).toLocaleDateString("en-US", { month: "long", year: "numeric" })}`} />
            {account.method === "email" && (
              <SettingsRow
                icon={<KeyRound size={18} />}
                label="Change password"
                onClick={() => {
                  setPwKey((k) => k + 1);
                  setPwOpen(true);
                }}
              />
            )}
          </SettingsGroup>
        ) : (
          <div className="card p-5">
            <p className="font-display text-lg font-bold text-ink">Not signed in</p>
            <p className="mt-1 text-sm text-muted">You&apos;re using a local demo profile. Create an account during onboarding to back up and sync.</p>
            <ButtonLink href="/onboarding" variant="soft" size="sm" className="mt-3">
              Set up an account
            </ButtonLink>
          </div>
        )}

        <SettingsGroup title="Session">
          <SettingsRow icon={<LogOut size={18} />} label="Log out" detail="Your data stays on this device" onClick={() => setLogoutOpen(true)} />
        </SettingsGroup>

        <SettingsGroup title="Danger zone" footer="Deleting removes everything stored on this device and returns you to onboarding.">
          <SettingsRow
            icon={<Trash2 size={18} />}
            tone="danger"
            label="Delete account"
            onClick={() => {
              setDelKey((k) => k + 1);
              setDelOpen(true);
            }}
          />
        </SettingsGroup>
      </div>

      <BottomSheet
        key={`pw-${pwKey}`}
        open={pwOpen}
        onClose={() => setPwOpen(false)}
        title="Change password"
        description="Preview: passwords aren't really stored."
        footer={
          <div className="flex gap-2">
            <Button variant="secondary" block onClick={() => setPwOpen(false)}>
              Cancel
            </Button>
            <Button type="submit" form="pw-form" block>
              Update password
            </Button>
          </div>
        }
      >
        <PasswordForm onDone={() => setPwOpen(false)} />
      </BottomSheet>

      <BottomSheet key={`del-${delKey}`} open={delOpen} onClose={() => setDelOpen(false)} title="Delete your account?" role="alertdialog" size="sm">
        <DeleteForm
          onCancel={() => setDelOpen(false)}
          onDelete={() => {
            setDelOpen(false);
            dispatch({ type: "session/reset" });
            router.replace("/onboarding");
          }}
        />
      </BottomSheet>

      <ConfirmationDialog
        open={logoutOpen}
        onClose={() => setLogoutOpen(false)}
        title="Log out?"
        body="Your habits stay saved on this device. You'll go back to the welcome screen."
        confirmLabel="Log out"
        onConfirm={() => {
          dispatch({ type: "session/logout" });
          router.replace("/onboarding");
        }}
      />
    </Page>
  );
}
