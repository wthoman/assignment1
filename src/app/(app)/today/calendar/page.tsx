"use client";

import { CalendarView } from "@/components/habits/CalendarView";
import { Page } from "@/components/shell/Page";

export default function CalendarPage() {
  return (
    <Page back="/today" eyebrow="Planner" title="Calendar" wide>
      <CalendarView />
    </Page>
  );
}
