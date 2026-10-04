# Daybook — architecture & UI conventions

Daybook (temporary name, see `src/lib/brand.ts` + `src/components/brand/Logo.tsx`) is a local-first,
mobile-first social habit tracker built with Next.js 16 (App Router), React 19, TypeScript,
Tailwind CSS v4, `motion` (Framer Motion) and `lucide-react`.

## Layers

| Layer | Location | Notes |
| --- | --- | --- |
| Types | `src/lib/types.ts` | Every domain shape. UI and data share only these. |
| Seed data | `src/lib/data/seed.ts`, `src/lib/data/catalog.ts` | Deterministic, generated around "today". Catalogs: collectibles, cosmetics, personalities, categories, goals. |
| State | `src/lib/store/*` | `actions.ts` (discriminated union), `reducer.ts` (pure, plus award engine), `store.ts` (external store, localStorage persistence), `provider.tsx` (hooks). |
| Selectors | `src/lib/selectors/*` | Pure derived data: `habits.ts` (schedule, sections, streaks), `stats.ts` (consistency, windows, patterns), `recap.ts` (weekly recap + superlatives). |
| Components | `src/components/<area>/*` | Reusable UI, grouped by feature. |
| Routes | `src/app/**` | Thin pages composing components. `(app)` group = inside the shell. |

The whole app renders client-side after local state loads (server render shows `<Splash/>`).
Replacing localStorage with a backend means changing `store.ts` only.

### Reading and writing state

```tsx
"use client";
import { useAppState, useDispatch, useMe } from "@/lib/store/provider";
const state = useAppState();          // full AppState (never null inside the app)
const dispatch = useDispatch();
dispatch({ type: "checkin/complete", habitId, date });
```

* Compute derived data with selectors inside `useMemo` or directly in render. Don't store derived data.
* Use `useToday()` from `src/lib/hooks.ts` for the current date (ISO `YYYY-MM-DD`).
* All user text goes through the reducer, which runs `cleanText` (length caps, control chars). Render
  user text only as React text children — never `dangerouslySetInnerHTML`.
* Adding an action: append to the union in `actions.ts` and add a `case` before `default` in `reducer.ts`.

## Routes

| Route | Purpose |
| --- | --- |
| `/` | Redirects to `/onboarding` or `/today` |
| `/onboarding` | 11-step onboarding |
| `/today`, `/today/calendar` | Daily check-ins; monthly planner calendar |
| `/habits/new`, `/habits/[id]`, `/habits/[id]/edit` | Create, detail/history, edit |
| `/friends`, `/friends/[id]`, `/friends/quizzes` | Social feed, friend profile, friend quizzes |
| `/groups`, `/groups/new`, `/groups/[id]` | Groups, challenges, predictions |
| `/collection` | Sticker book / grid |
| `/recap`, `/recap/play` | Recap hub; full-screen swipeable recap |
| `/profile`, `/profile/avatar` | Profile; avatar builder, cosmetics and gifts |
| `/notifications` | Notification center |
| `/share` | Share & export studio (`?kind=…&id=…` preselects) |
| `/settings`, `/settings/*` | Settings sections, connected services |

## Visual language

* Palette tokens (Tailwind classes): `bg-paper` (page), `bg-cream` (cards), `text-ink`, `text-muted`,
  `text-faint`, `border-line`, `border-line-strong`, `bg-accent`/`text-accent` (burgundy, user-switchable),
  `text-on-accent`, `bg-accent-soft`, and supporting `rose|orange|gold|sage|sky` with `-soft` variants.
  Never hard-code the burgundy hex in UI — use `accent` so accent/theme settings work.
* Fonts: `font-display` (Bricolage Grotesque, headings, numbers, buttons), `font-sans` (Figtree, body),
  `font-hand` (Caveat, handwritten annotations — sparingly).
* Surfaces: `.card` (cream, line border, soft shadow, 18px radius), `.card-flat`, `.paper-panel` (ruled),
  `.eyebrow` (small burgundy uppercase label), `.scribble` (hand underline), `.hand-divider`, `<Tape/>`,
  `<HandNote/>`, `.sticker-shadow`.
* Icons: `lucide-react` for UI chrome only. Habit/collectible art uses `<Illustration kind=…/>` or
  `<IllustrationTile kind tint/>` (hand-drawn SVGs with the shared `#ink-wobble` filter). No emoji as icons.
* Colour should be earned: neutral by default; stronger fills on completion, reactions, awards.
* Avoid: identical card grids everywhere, pill-shaped everything (use 10–14px radii for controls),
  gradients except warm spotlights in the recap, confetti.

## Shared components

* `ui/Button` (`Button`, `ButtonLink`, `IconButton`), `ui/BottomSheet` (all modals — animates in/out,
  focus trap, Esc, desktop dialog), `ui/ConfirmationDialog`, `ui/controls` (`Toggle`, `Segmented`,
  `Chip`, `Field`, `TextInput`, `TextArea`, `CharCount`, `ProgressBar`, `ProgressRing`),
  `ui/misc` (`EmptyState`, `SectionHeading`, `SettingsRow`, `SettingsGroup`, `Tape`, `HandNote`,
  `Skeleton`, `Badge`), `ui/Stamp`, `ui/Toast` (`useToast()`, `haptic()`).
* `avatar/Avatar` (`Avatar`, `AvatarArt`), `avatar/FriendAvatarStack`.
* `illustrations/Illustration`, `illustrations/Mascot` (Pip the mascot, moods for empty states).
* `collection/Sticker`, `collection/CollectibleDetail`.
* `social/ReactionBar`.
* `shell/Page` — every in-app page uses `<Page title … back? actions? aside?>`. `aside` becomes the
  desktop secondary column.

## Accessibility & responsiveness

* Mobile first from 320px; no horizontal overflow; touch targets ≥ 44px (`min-h-11`, `size-11`).
* Bottom nav on phones, side rail on ≥ 768px; the main column is width-constrained.
* All interactive elements are real `button`/`a` elements with labels; dialogs via `BottomSheet`.
* Motion respects the OS setting and the in-app Motion setting (`MotionConfig` + CSS guard).
