# Daybook

A playful social-accountability habit tracker: daily check-ins, shared habits with friends, group challenges, a sticker-book collection and an award-show weekly recap. It's a working, local-first prototype. Every major control works, and changes persist in your browser.

> "Daybook" is a temporary name. Rename it in `src/lib/brand.ts` and replace the mark in `src/components/brand/Logo.tsx`.

## Run it

```bash
npm install
npm run dev        # http://localhost:3000
```

The first visit starts onboarding. To skip it, choose **Explore with sample data** on the welcome screen.

| Script | What it does |
| --- | --- |
| `npm run dev` | Development server |
| `npm run build` / `npm start` | Production build and serve |
| `npm run typecheck` | TypeScript, no emit |
| `npm run lint` | ESLint (Next core-web-vitals + TS rules) |
| `npm test` | Vitest: data layer, reducer, selectors, personality scoring |

To reset the demo, go to Settings → Reset demo data, or clear the `daybook:v1` localStorage key.

## Stack

Next.js 16 (App Router) · React 19 · TypeScript · Tailwind CSS v4 · `motion` · `lucide-react` · `html-to-image` · Vitest

## What's inside

See [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) for the layers, route map, design tokens and component inventory.

* **Data layer:** typed domain model, deterministic seed data generated around today's date, a pure reducer with an award engine, and selectors for consistency, comebacks, patterns and recaps. The data lives in localStorage behind `src/lib/store/store.ts`, so a backend can replace it without touching UI code.
* **Consistency over streaks:** the headline metric is a forgiving 28-day rolling score that forgives one missed day per week. Optional habits never count against you. Streaks are secondary and can be turned off.

## Mocked or simulated

* Authentication: accounts are local only, and passwords are never stored.
* Friends, their check-ins, groups, quizzes and notifications are seeded sample data.
* Photo proof uses illustrated placeholder "snapshots", not a real camera.
* Connected services (Apple Health, Screen Time, Calendar, Weather) are polished mock states.
* Push notifications, sharing to other apps and gifting are simulated in the UI. Image export (PNG) and data export (JSON/CSV) do work.
