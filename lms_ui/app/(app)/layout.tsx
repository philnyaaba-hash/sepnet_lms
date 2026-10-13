import type { ReactNode } from "react";
import { cookies } from "next/headers";
import { redirect } from "next/navigation";
import AppShell from "@/components/AppShell";
import { SearchProvider } from "@/components/SearchContext";
import { SESSION_COOKIE, verifySessionToken } from "@/lib/auth";

export default async function ProtectedLayout({
  children,
}: {
  children: ReactNode;
}) {
  const store = await cookies();
  if (!verifySessionToken(store.get(SESSION_COOKIE)?.value)) {
    redirect("/login");
  }

  return (
    <SearchProvider>
      <AppShell>{children}</AppShell>
    </SearchProvider>
  );
}
