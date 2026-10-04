"use client";

import { useRouter } from "next/navigation";
import { useEffect } from "react";
import { RecapPlayer } from "@/components/recap/RecapPlayer";
import { useAppState } from "@/lib/store/provider";

/** Full-screen recap player. Lives outside the app shell, so it guards onboarding itself. */
export default function RecapPlayPage() {
  const { session } = useAppState();
  const router = useRouter();
  useEffect(() => {
    if (!session.onboarded) router.replace("/onboarding");
  }, [session.onboarded, router]);
  if (!session.onboarded) return null;
  return (
    <main aria-label="Weekly recap">
      <h1 className="sr-only">Your weekly recap</h1>
      <RecapPlayer />
    </main>
  );
}
