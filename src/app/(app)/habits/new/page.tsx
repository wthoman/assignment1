"use client";

import { useSearchParams } from "next/navigation";
import { Suspense } from "react";
import { HabitForm, presetFromParams } from "@/components/habits/HabitForm";
import { Page } from "@/components/shell/Page";
import { Skeleton } from "@/components/ui/misc";

function NewHabitForm() {
  const params = useSearchParams();
  const preset = presetFromParams(params);
  return <HabitForm key={params.toString()} preset={preset} />;
}

export default function NewHabitPage() {
  return (
    <Page back="/today" title="New habit" subtitle="Start small. You can tweak anything later." wide>
      <Suspense fallback={<Skeleton className="h-96" />}>
        <NewHabitForm />
      </Suspense>
    </Page>
  );
}
