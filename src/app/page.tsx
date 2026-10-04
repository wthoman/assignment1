"use client";

import { useRouter } from "next/navigation";
import { useEffect } from "react";
import { Splash } from "@/components/shell/Splash";
import { useAppState } from "@/lib/store/provider";

/** Entry point: routes to onboarding or Today depending on the local session. */
export default function Home() {
  const { session } = useAppState();
  const router = useRouter();
  useEffect(() => {
    router.replace(session.onboarded ? "/today" : "/onboarding");
  }, [session.onboarded, router]);
  return <Splash />;
}
