import { act, cleanup, fireEvent, render, screen } from "@testing-library/react";
import { MotionGlobalConfig } from "motion/react";
import { afterEach, beforeAll, describe, expect, it, vi } from "vitest";
import { Providers } from "@/components/shell/Providers";
import { getSnapshot } from "@/lib/store/store";
import { OnboardingFlow } from "./OnboardingFlow";

const replace = vi.fn();
vi.mock("next/navigation", () => ({ useRouter: () => ({ replace, push: vi.fn(), back: vi.fn() }) }));

beforeAll(() => {
  MotionGlobalConfig.skipAnimations = true;
  window.matchMedia ??= ((query: string) => ({
    matches: false,
    media: query,
    onchange: null,
    addEventListener: () => {},
    removeEventListener: () => {},
    addListener: () => {},
    removeListener: () => {},
    dispatchEvent: () => false,
  })) as unknown as typeof window.matchMedia;
  window.scrollTo = () => {};
});

afterEach(cleanup);

const click = async (name: RegExp | string) => {
  const el = await screen.findByRole("button", { name }, { timeout: 3000 });
  await act(async () => {
    fireEvent.click(el);
  });
};

describe("OnboardingFlow", () => {
  it("walks through all eleven steps and dispatches along the way", async () => {
    render(
      <Providers>
        <OnboardingFlow />
      </Providers>,
    );

    await click(/get started/i);

    // Account: validation, then success after the simulated delay
    await click(/create account/i);
    expect(await screen.findByText(/enter your email address/i)).toBeTruthy();
    fireEvent.change(screen.getByLabelText("Email"), { target: { value: "sam@example.com" } });
    fireEvent.change(screen.getByLabelText("Password"), { target: { value: "longenough" } });
    await click(/create account/i);
    expect(await screen.findByText(/what should friends call you/i, {}, { timeout: 3000 })).toBeTruthy();
    expect(getSnapshot()?.session.account?.email).toBe("sam@example.com");

    fireEvent.change(screen.getByLabelText("Display name"), { target: { value: "Sam Rivera" } });
    expect((screen.getByLabelText("Handle") as HTMLInputElement).value).toBe("sam.rivera");
    await click(/^continue$/i);

    await click(/surprise me/i);
    await click(/looks like me/i);

    await click(/^move more$/i);
    await click(/^continue$/i);
    expect(getSnapshot()?.session.goals).toContain("move");

    for (let i = 0; i < 5; i++) {
      const radios = await screen.findAllByRole("radio");
      await act(async () => {
        fireEvent.click(radios[0]);
      });
      await click(i < 4 ? /next question/i : /see my result/i);
    }

    await click(/use these settings/i);
    expect(getSnapshot()?.session.personality).toBeTruthy();

    await click(/add habit/i);
    expect(getSnapshot()?.habits.some((h) => h.ownerId === "u-me" && h.startDate && h.privacy === "friends" && h.reminderTimes.length === 1)).toBe(true);

    await click(/invite ben carter/i);
    expect(await screen.findByText(/1 invited/i)).toBeTruthy();
    await click(/^continue$/i);

    await click(/^allow$/i);
    await click(/save and continue/i);

    expect(await screen.findByText(/you.re all set/i)).toBeTruthy();
    await click(/open today/i);
    expect(getSnapshot()?.session.onboarded).toBe(true);
    expect(getSnapshot()?.users["u-me"].name).toBe("Sam Rivera");
    expect(replace).toHaveBeenCalledWith("/today");
  }, 20000);

  it("shows the wrong-password error in log in mode, and sample data skips straight to Today", async () => {
    render(
      <Providers>
        <OnboardingFlow />
      </Providers>,
    );
    await click(/i already have an account/i);
    fireEvent.change(screen.getByLabelText("Email"), { target: { value: "riley@example.com" } });
    fireEvent.change(screen.getByLabelText("Password"), { target: { value: "wrongpass" } });
    await click(/^log in$/i);
    expect(await screen.findByText(/that password doesn.t match/i, {}, { timeout: 3000 })).toBeTruthy();

    await click(/^back$/i);
    replace.mockClear();
    await click(/explore with sample data/i);
    expect(replace).toHaveBeenCalledWith("/today");
  }, 10000);
});
