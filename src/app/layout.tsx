import type { Metadata, Viewport } from "next";
import { Bricolage_Grotesque, Caveat, Figtree } from "next/font/google";
import { Providers } from "@/components/shell/Providers";
import { BRAND } from "@/lib/brand";
import "./globals.css";

const display = Bricolage_Grotesque({ variable: "--font-display-face", subsets: ["latin"], weight: ["500", "600", "700", "800"] });
const body = Figtree({ variable: "--font-body-face", subsets: ["latin"], weight: ["400", "500", "600", "700"] });
const hand = Caveat({ variable: "--font-hand-face", subsets: ["latin"], weight: ["500", "700"] });

export const metadata: Metadata = {
  title: { default: BRAND.name, template: `%s · ${BRAND.name}` },
  description: BRAND.shortPitch,
};

export const viewport: Viewport = {
  width: "device-width",
  initialScale: 1,
  viewportFit: "cover",
  themeColor: "#f3e8d2",
};

export default function RootLayout({ children }: LayoutProps<"/">) {
  return (
    <html lang="en" data-theme="light" data-accent="burgundy" className={`${display.variable} ${body.variable} ${hand.variable} antialiased`}>
      <body className="min-h-dvh">
        <Providers>{children}</Providers>
      </body>
    </html>
  );
}
