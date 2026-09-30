import type { Metadata } from "next";
import { Inter, Manrope } from "next/font/google";
import { AccountCacheProvider } from "@/features/account/components/account-cache-provider";
import { themeInit } from "@/components/theme/theme-init";
import { SiteHeader } from "@/components/navigation/site-header";
import "./globals.css";
import "./theme.css";

const inter = Inter({ subsets: ["latin"], variable: "--font-body" });
const manrope = Manrope({ subsets: ["latin"], variable: "--font-display" });

export const metadata: Metadata = {
  metadataBase: new URL(process.env.NEXT_PUBLIC_SITE_URL ?? "http://localhost:3001"),
  title: { default: "Dramabyte — Stories worth one more episode", template: "%s | Dramabyte" },
  description: "Watch original bite-sized drama series, discover new stories, and pick up exactly where you left off.",
  applicationName: "Dramabyte",
  openGraph: { title: "Dramabyte", description: "Original drama, one irresistible episode at a time.", type: "website" },
  robots: { index: true, follow: true },
};

export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return <html lang="en" suppressHydrationWarning><head><script dangerouslySetInnerHTML={{ __html: themeInit }} /></head><body className={`${inter.variable} ${manrope.variable}`}><AccountCacheProvider><SiteHeader /><div className="site-content">{children}</div></AccountCacheProvider></body></html>;
}
