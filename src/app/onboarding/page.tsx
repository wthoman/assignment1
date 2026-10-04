import type { Metadata } from "next";
import { OnboardingFlow } from "@/components/onboarding/OnboardingFlow";

export const metadata: Metadata = { title: "Welcome" };

/** Onboarding lives outside the (app) group, so it renders without the app shell. */
export default function OnboardingPage() {
  return <OnboardingFlow />;
}
