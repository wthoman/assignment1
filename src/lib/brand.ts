/**
 * Temporary product identity. Everything user-facing reads the name from here,
 * and the mark lives in components/brand/Logo.tsx, so a rename is a two-file change.
 */
export const BRAND = {
  name: "Daybook",
  tagline: "Small habits, kept together.",
  shortPitch: "A habit tracker you share with the people who cheer you on.",
  shareDomain: "daybook.app",
} as const;
