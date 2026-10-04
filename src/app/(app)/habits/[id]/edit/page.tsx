"use client";

import { Archive, ArchiveRestore, Pause, Play, Trash2 } from "lucide-react";
import { useParams, useRouter } from "next/navigation";
import { useState } from "react";
import { HabitForm } from "@/components/habits/HabitForm";
import { Page } from "@/components/shell/Page";
import { ButtonLink } from "@/components/ui/Button";
import { ConfirmationDialog } from "@/components/ui/ConfirmationDialog";
import { EmptyState, SettingsGroup, SettingsRow } from "@/components/ui/misc";
import { useToast } from "@/components/ui/Toast";
import { habitById } from "@/lib/selectors/habits";
import { useAppState, useDispatch } from "@/lib/store/provider";

export default function EditHabitPage() {
  const { id } = useParams<{ id: string }>();
  const state = useAppState();
  const dispatch = useDispatch();
  const router = useRouter();
  const toast = useToast();
  const habit = habitById(state, id);
  const [confirm, setConfirm] = useState<"archive" | "delete" | null>(null);
  const [removed, setRemoved] = useState(false);

  if (!habit) {
    if (removed) return null;
    return (
      <Page back="/today" title="Edit habit">
        <EmptyState
          title="We couldn't find that habit"
          body="It may have been deleted, or the link is a little off."
          action={
            <ButtonLink href="/today" variant="secondary">
              Back to Today
            </ButtonLink>
          }
        />
      </Page>
    );
  }

  const paused = habit.status === "paused";
  const archived = habit.status === "archived";

  const setStatus = (status: typeof habit.status, title: string, body: string) => {
    dispatch({ type: "habit/status", id: habit.id, status });
    toast({ title, body, motif: habit.icon });
  };

  return (
    <Page back={`/habits/${habit.id}`} title="Edit habit" subtitle={habit.name} wide>
      <HabitForm habit={habit} />

      <div className="mt-8 lg:max-w-[calc(100%-304px)]">
        <SettingsGroup title="Manage" footer="Pausing keeps your history and never counts against your consistency. Archiving tucks the habit away; you can restore it any time.">
          {!archived && (
            <SettingsRow
              icon={paused ? <Play size={17} aria-hidden /> : <Pause size={17} aria-hidden />}
              label={paused ? "Resume habit" : "Pause habit"}
              detail={paused ? "Bring it back to your Today list." : "Take a break — no missed days while paused."}
              onClick={() =>
                paused ? setStatus("active", "Welcome back", `“${habit.name}” is back on Today.`) : setStatus("paused", "Habit paused", "Rest is part of the plan. Resume whenever.")
              }
            />
          )}
          {archived ? (
            <SettingsRow icon={<ArchiveRestore size={17} aria-hidden />} label="Restore habit" detail="Put it back on your Today list." onClick={() => setStatus("active", "Habit restored", `“${habit.name}” is back on Today.`)} />
          ) : (
            <SettingsRow icon={<Archive size={17} aria-hidden />} label="Archive habit" detail="Hide it but keep every check-in." onClick={() => setConfirm("archive")} />
          )}
          <SettingsRow icon={<Trash2 size={17} aria-hidden />} label="Delete habit" detail="Removes it and all its check-ins for good." tone="danger" onClick={() => setConfirm("delete")} />
        </SettingsGroup>
      </div>

      <ConfirmationDialog
        open={confirm === "archive"}
        onClose={() => setConfirm(null)}
        onConfirm={() => {
          setStatus("archived", "Habit archived", "Your history is safe. Restore it any time.");
          router.push("/today");
        }}
        title="Archive this habit?"
        body={`“${habit.name}” will leave your Today list. Every check-in stays in your history, and you can restore it whenever you like.`}
        confirmLabel="Archive"
      />
      <ConfirmationDialog
        open={confirm === "delete"}
        onClose={() => setConfirm(null)}
        onConfirm={() => {
          setRemoved(true);
          router.replace("/today");
          dispatch({ type: "habit/delete", id: habit.id });
          toast({ title: "Habit deleted", body: "Clean slate. Start something new whenever you're ready." });
        }}
        title="Delete this habit?"
        body={`This removes “${habit.name}” and all of its check-ins. It can't be undone. Archiving keeps the history instead.`}
        confirmLabel="Delete for good"
        cancelLabel="Keep it"
        tone="danger"
      />
    </Page>
  );
}
