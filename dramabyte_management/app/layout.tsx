import type { Metadata } from "next";
import "./globals.css";
import "../styles/dashboard-white.css";
import "../styles/management.css";
import "../styles/platform.css";
import "../styles/hybrid.css";

export const metadata: Metadata = {
  title: "DramaByte Management",
  description: "Create, review, and publish short-form drama.",
  other: {
    "codex-preview": "development",
  },
  icons: {
    icon: "/favicon.svg",
    shortcut: "/favicon.svg",
  },
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <body className="antialiased">{children}</body>
    </html>
  );
}
