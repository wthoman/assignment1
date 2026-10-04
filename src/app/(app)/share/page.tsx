"use client";

import { toPng } from "html-to-image";
import { Download, FileJson, FileSpreadsheet, Link2, Share2, ShieldCheck } from "lucide-react";
import Link from "next/link";
import { useSearchParams } from "next/navigation";
import { Suspense, useEffect, useMemo, useRef, useState } from "react";
import { Illustration } from "@/components/illustrations/Illustration";
import { NativeSelect } from "@/components/settings/SettingsControls";
import { buildHistoryCSV, copyText, downloadBlob, downloadDataURL, downloadMyData } from "@/components/share/exportData";
import { buildShareContent, parseKind, pickerOptions, SHARE_KINDS, type ShareFormat, type ShareKind, type SharePrivacy } from "@/components/share/shareContent";
import { SharePreview } from "@/components/share/SharePreview";
import { Page } from "@/components/shell/Page";
import { Button } from "@/components/ui/Button";
import { Segmented, Toggle } from "@/components/ui/controls";
import { EmptyState, HandNote, Skeleton } from "@/components/ui/misc";
import { useToast } from "@/components/ui/Toast";
import { BRAND } from "@/lib/brand";
import { cn } from "@/lib/cn";
import { useToday } from "@/lib/hooks";
import { habitsFor } from "@/lib/selectors/habits";
import { useAppState } from "@/lib/store/provider";

const PRIVACY_ROWS: { key: keyof SharePrivacy; label: string; detail: string }[] = [
  { key: "hideName", label: "Hide my name & avatar", detail: "Shows the mascot instead" },
  { key: "hideTimes", label: "Hide exact dates & times", detail: "“Last week” instead of dates" },
  { key: "hideFriends", label: "Hide friends’ names", detail: "Groups and faces stay anonymous" },
  { key: "hideHabits", label: "Hide habit names", detail: "Says “a habit” instead" },
];

const FORMATS: { value: ShareFormat; label: string }[] = [
  { value: "story", label: "Story" },
  { value: "square", label: "Square" },
  { value: "message", label: "Message" },
];

function ShareStudio({ initialKind, initialId }: { initialKind: ShareKind; initialId?: string }) {
  const state = useAppState();
  const today = useToday();
  const toast = useToast();
  const { settings } = state;
  const hidesByDefault = settings.shareHidesDetails;
  const [kind, setKind] = useState<ShareKind>(initialKind);
  const [ids, setIds] = useState<Partial<Record<ShareKind, string>>>(initialId ? { [initialKind]: initialId } : {});
  const [format, setFormat] = useState<ShareFormat>("story");
  const [privacy, setPrivacy] = useState<SharePrivacy>({ hideName: hidesByDefault, hideTimes: hidesByDefault, hideFriends: hidesByDefault, hideHabits: hidesByDefault });
  const [busy, setBusy] = useState(false);
  const [csvHabit, setCsvHabit] = useState("all");
  const nodeRef = useRef<HTMLDivElement>(null);

  const options = useMemo(() => pickerOptions(state, kind), [state, kind]);
  const chosen = ids[kind];
  const selectedId = chosen && options.some((o) => o.id === chosen) ? chosen : options[0]?.id;
  const needsPick = Boolean(SHARE_KINDS.find((k) => k.key === kind)?.needs);
  const content = useMemo(() => buildShareContent(state, today, kind, selectedId, privacy), [state, today, kind, selectedId, privacy]);
  const friend = state.users[state.users[state.meId].friendIds[0]];
  const myHabits = habitsFor(state, state.meId, { includeInactive: true });

  useEffect(() => {
    if (window.location.hash === "#export") document.getElementById("export")?.scrollIntoView({ block: "start" });
  }, []);

  const download = async () => {
    const node = nodeRef.current;
    if (!node) return;
    setBusy(true);
    try {
      const dataUrl = await toPng(node, { pixelRatio: 3, cacheBust: true });
      downloadDataURL(`${BRAND.name.toLowerCase()}-${kind}-${format}.png`, dataUrl);
      toast({ title: "Image saved", body: "Check your downloads.", motif: "star" });
    } catch {
      toast({ title: "Couldn't create the image", body: "Try again, or take a screenshot of the preview." });
    } finally {
      setBusy(false);
    }
  };

  const copyLink = async () => {
    if (!content) return;
    const ok = await copyText(content.url);
    toast(ok ? { title: "Link copied", body: content.url.replace("https://", ""), motif: "ticket" } : { title: "Couldn't copy automatically", body: content.url, duration: 6000 });
  };

  const share = async () => {
    if (!content) return;
    if (typeof navigator !== "undefined" && typeof navigator.share === "function") {
      try {
        await navigator.share({ title: content.headline, text: content.shareText, url: content.url });
        return;
      } catch (e) {
        if (e instanceof DOMException && e.name === "AbortError") return;
      }
    }
    await copyLink();
  };

  return (
    <div className="flex flex-col gap-6 md:grid md:grid-cols-[minmax(0,1fr)_minmax(0,340px)] md:items-start md:gap-8">
      <div className="contents md:block md:space-y-6">
        {/* 1. What to share */}
        <section aria-labelledby="what-h" className="order-1 space-y-3">
          <h2 id="what-h" className="font-display text-[1.0625rem] font-bold text-ink">
            What are you sharing?
          </h2>
          <div role="radiogroup" aria-label="Share type" className="grid grid-cols-2 gap-2 sm:grid-cols-4 md:grid-cols-3 lg:grid-cols-4">
            {SHARE_KINDS.map((k) => {
              const active = k.key === kind;
              return (
                <button
                  key={k.key}
                  type="button"
                  role="radio"
                  aria-checked={active}
                  onClick={() => setKind(k.key)}
                  className={cn(
                    "flex min-h-12 items-center gap-2 rounded-[13px] border px-2.5 py-2 text-left text-sm font-semibold transition-colors",
                    active ? "border-accent bg-accent-soft text-accent" : "border-line bg-cream text-ink hover:border-line-strong",
                  )}
                >
                  <Illustration kind={k.icon} size={26} />
                  <span className="leading-tight">{k.label}</span>
                </button>
              );
            })}
          </div>
          {needsPick && options.length > 0 && (
            <div className="space-y-1.5">
              <label htmlFor="share-item" className="font-display text-sm font-semibold text-ink">
                {kind === "award" ? "Which award?" : kind === "group" ? "Which challenge?" : "Which habit?"}
              </label>
              <NativeSelect id="share-item" value={selectedId ?? ""} onChange={(e) => setIds((m) => ({ ...m, [kind]: e.target.value }))}>
                {options.map((o) => (
                  <option key={o.id} value={o.id}>
                    {o.label}
                  </option>
                ))}
              </NativeSelect>
            </div>
          )}
          <div className="space-y-1.5">
            <p id="format-label" className="font-display text-sm font-semibold text-ink">
              Format
            </p>
            <Segmented label="Card format" value={format} onChange={setFormat} options={FORMATS} />
            <p className="text-xs text-muted">{format === "story" ? "9:16 for stories and status updates." : format === "square" ? "1:1 for feeds and group chats." : "A link preview, as it would look in a chat."}</p>
          </div>
        </section>

        {/* 3. Privacy */}
        <section aria-labelledby="privacy-h" className="order-3 space-y-2">
          <div className="flex items-end justify-between gap-2">
            <h2 id="privacy-h" className="flex items-center gap-1.5 font-display text-[1.0625rem] font-bold text-ink">
              <ShieldCheck size={18} className="text-accent" aria-hidden /> Privacy
            </h2>
            <button
              type="button"
              className="min-h-11 px-1 text-sm font-semibold text-accent hover:underline"
              onClick={() => setPrivacy({ hideName: true, hideTimes: true, hideFriends: true, hideHabits: true })}
            >
              Hide everything
            </button>
          </div>
          <div className="card divide-y divide-line overflow-hidden">
            {PRIVACY_ROWS.map((r) => (
              <div key={r.key} className="flex min-h-14 items-center gap-3 px-4 py-2.5">
                <span className="min-w-0 flex-1">
                  <span className="block text-[0.9375rem] font-semibold text-ink">{r.label}</span>
                  <span className="block text-[0.8125rem] text-muted">{r.detail}</span>
                </span>
                <Toggle label={r.label} checked={privacy[r.key]} onChange={(v) => setPrivacy((p) => ({ ...p, [r.key]: v }))} />
              </div>
            ))}
          </div>
          <p className="px-1 text-[0.8125rem] text-muted">
            {hidesByDefault ? "Details start hidden." : "Details start visible."} Change the default in <Link href="/settings/privacy" className="font-semibold text-accent underline-offset-2 hover:underline">Privacy settings</Link>.
          </p>
        </section>

        {/* 4. Export */}
        <section id="export" aria-labelledby="export-h" className="order-4 scroll-mt-6 space-y-3">
          <h2 id="export-h" className="font-display text-[1.0625rem] font-bold text-ink">
            Export your data
          </h2>
          <div className="paper-panel space-y-4 rounded-[18px] border border-line p-4">
            <div className="flex flex-col gap-3 sm:flex-row sm:items-center">
              <div className="min-w-0 flex-1">
                <p className="font-semibold text-ink">Everything, as JSON</p>
                <p className="text-[0.8125rem] text-muted">Your profile, habits, check-ins and settings. Friends appear only as handles.</p>
              </div>
              <Button
                variant="secondary"
                icon={<FileJson size={16} aria-hidden />}
                onClick={() => {
                  downloadMyData(state);
                  toast({ title: "Data exported", body: "Saved as a JSON file.", motif: "book" });
                }}
              >
                Download JSON
              </Button>
            </div>
            <div className="hand-divider" aria-hidden />
            <div className="space-y-2">
              <label htmlFor="csv-habit" className="block font-semibold text-ink">
                Habit history, as CSV
              </label>
              <p className="text-[0.8125rem] text-muted">One row per check-in. Opens in any spreadsheet app.</p>
              <div className="flex flex-col gap-2 sm:flex-row">
                <NativeSelect id="csv-habit" value={csvHabit} onChange={(e) => setCsvHabit(e.target.value)} className="sm:flex-1">
                  <option value="all">All my habits</option>
                  {myHabits.map((h) => (
                    <option key={h.id} value={h.id}>
                      {h.name}
                    </option>
                  ))}
                </NativeSelect>
                <Button
                  variant="secondary"
                  icon={<FileSpreadsheet size={16} aria-hidden />}
                  onClick={() => {
                    const csv = buildHistoryCSV(state, csvHabit);
                    const slug = csvHabit === "all" ? "all-habits" : (myHabits.find((h) => h.id === csvHabit)?.name ?? "habit").toLowerCase().replace(/[^a-z0-9]+/g, "-");
                    downloadBlob(`${BRAND.name.toLowerCase()}-${slug}.csv`, csv, "text/csv;charset=utf-8");
                    toast({ title: "CSV exported", body: `${csv.split("\r\n").length - 1} check-ins.`, motif: "pencil" });
                  }}
                >
                  Export CSV
                </Button>
              </div>
            </div>
          </div>
        </section>
      </div>

      {/* 2. Preview + actions */}
      <section aria-labelledby="preview-h" className="order-2 space-y-3 md:sticky md:top-6">
        <div className="flex items-baseline justify-between">
          <h2 id="preview-h" className="font-display text-[1.0625rem] font-bold text-ink">
            Preview
          </h2>
          <HandNote className="text-base">not a screenshot</HandNote>
        </div>
        {content ? (
          <>
            <SharePreview content={content} format={format} accentKey={settings.accent} nodeRef={nodeRef} friend={friend} hideFriends={privacy.hideFriends} />
            <div className="grid grid-cols-3 gap-2">
              <Button variant="secondary" size="md" className="px-2" icon={<Download size={16} aria-hidden />} onClick={download} disabled={busy} aria-label="Download image">
                {busy ? "Saving…" : "Image"}
              </Button>
              <Button variant="secondary" size="md" className="px-2" icon={<Link2 size={16} aria-hidden />} onClick={copyLink} aria-label="Copy link">
                Link
              </Button>
              <Button size="md" className="px-2" icon={<Share2 size={16} aria-hidden />} onClick={share}>
                Share…
              </Button>
            </div>
            <p className="break-all text-center text-xs text-faint">{content.url.replace("https://", "")}</p>
          </>
        ) : (
          <EmptyState
            compact
            title={kind === "award" ? "No awards yet" : kind === "group" ? "No challenges yet" : "Nothing to share yet"}
            body={kind === "award" ? "Earn your first sticker by checking in." : kind === "group" ? "Join a group challenge to share its progress." : "Create a habit first."}
          />
        )}
      </section>
    </div>
  );
}

function StudioFromParams() {
  const params = useSearchParams();
  const kind = parseKind(params.get("kind"));
  const id = params.get("id") ?? undefined;
  return <ShareStudio key={`${kind}:${id ?? ""}`} initialKind={kind} initialId={id} />;
}

export default function SharePage() {
  return (
    <Page title="Share & export" subtitle="Make a card worth sending. Sensitive details start hidden." wide>
      <Suspense
        fallback={
          <div className="space-y-3" aria-busy="true">
            <Skeleton className="h-28" />
            <Skeleton className="h-96" />
          </div>
        }
      >
        <StudioFromParams />
      </Suspense>
    </Page>
  );
}
