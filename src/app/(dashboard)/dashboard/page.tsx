import { redirect } from "next/navigation";
import { Suspense } from "react";
import { Button } from "@/components/ui/button";
import { createClient } from "@/lib/supabase/server";
import { signOut } from "../../(auth)/actions";

async function AccountSummary() {
  const supabase = await createClient();
  const { data: claimsData } = await supabase.auth.getClaims();
  const claims = claimsData?.claims;
  if (!claims) redirect("/login");

  // RLS guarantees these only return rows from the caller's own organization.
  const [{ data: profile }, { data: subscription }] = await Promise.all([
    supabase
      .from("profiles")
      .select("full_name, role, organizations(name)")
      .eq("id", claims.sub)
      .maybeSingle(),
    supabase.from("subscriptions").select("plan_tier, status").maybeSingle(),
  ]);
  const org = profile?.organizations as { name: string } | { name: string }[] | null | undefined;
  const orgName = Array.isArray(org) ? org[0]?.name : org?.name;

  return (
    <dl className="grid gap-4 sm:grid-cols-3">
      <div className="rounded-lg border border-zinc-200 p-4 dark:border-zinc-800">
        <dt className="text-sm text-zinc-500">Usuário</dt>
        <dd className="font-medium">{profile?.full_name ?? claims.email}</dd>
      </div>
      <div className="rounded-lg border border-zinc-200 p-4 dark:border-zinc-800">
        <dt className="text-sm text-zinc-500">Organização</dt>
        <dd className="font-medium">
          {orgName ?? "—"} <span className="text-sm text-zinc-500">({profile?.role ?? "member"})</span>
        </dd>
      </div>
      <div className="rounded-lg border border-zinc-200 p-4 dark:border-zinc-800">
        <dt className="text-sm text-zinc-500">Plano</dt>
        <dd className="font-medium">
          {subscription?.plan_tier ?? "starter"}{" "}
          <span className="text-sm text-zinc-500">({subscription?.status ?? "pending"})</span>
        </dd>
      </div>
    </dl>
  );
}

export default function DashboardPage() {
  return (
    <main className="mx-auto flex w-full max-w-4xl flex-col gap-6 px-4 py-16">
      <header className="flex items-center justify-between">
        <h1 className="text-2xl font-semibold">Dashboard</h1>
        <form action={signOut}>
          <Button type="submit">Sair</Button>
        </form>
      </header>
      <Suspense fallback={<p className="animate-pulse text-zinc-400">Carregando conta...</p>}>
        <AccountSummary />
      </Suspense>
    </main>
  );
}
