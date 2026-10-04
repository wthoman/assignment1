"use client";

import { Settings, Share2 } from "lucide-react";
import Link from "next/link";
import { Page } from "@/components/shell/Page";
import { EarnedSuperlatives, FavoriteHabits, FriendsPreview, GroupsList, HabitHistory, PastRecaps, PrivacyShortcut } from "@/components/profile/ProfileLists";
import { ProfileHeader } from "@/components/profile/ProfileHeader";
import { ConsistencyCard, PatternsCard, StatsSummary } from "@/components/profile/ProfileStats";
import { ShowcaseShelf } from "@/components/profile/ShowcaseShelf";

const iconLink = "grid size-11 place-items-center rounded-[13px] text-ink transition-colors hover:bg-accent-soft";

export default function ProfilePage() {
  return (
    <Page
      title="Profile"
      actions={
        <>
          <Link href="/share?kind=invite" className={iconLink} aria-label="Share your profile">
            <Share2 size={20} aria-hidden />
          </Link>
          <Link href="/settings" className={iconLink} aria-label="Settings">
            <Settings size={20} aria-hidden />
          </Link>
        </>
      }
      aside={
        <>
          <div className="hidden lg:block">
            <StatsSummary />
          </div>
          <GroupsList />
          <PrivacyShortcut />
        </>
      }
    >
      <div className="space-y-8">
        <ProfileHeader />
        <div className="lg:hidden">
          <StatsSummary />
        </div>
        <ShowcaseShelf />
        <FriendsPreview />
        <FavoriteHabits />
        <ConsistencyCard />
        <PatternsCard />
        <EarnedSuperlatives />
        <PastRecaps />
        <HabitHistory />
      </div>
    </Page>
  );
}
