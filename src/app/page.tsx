import Link from "next/link";

export default function Home() {
  return (
    <main className="flex flex-1 flex-col items-center justify-center gap-6 px-4 py-24 text-center">
      <h1 className="max-w-2xl text-4xl font-semibold tracking-tight">
        Relatórios de performance e documentação técnica no piloto automático
      </h1>
      <p className="max-w-xl text-zinc-600 dark:text-zinc-400">
        Para agências de marketing e de software: gere relatórios executivos dos seus clientes em 1 clique e mantenha a documentação dos repositórios sempre atualizada.
      </p>
      <div className="flex gap-3">
        <Link href="/signup" className="rounded-md bg-zinc-900 px-4 py-2 text-sm font-medium text-white dark:bg-zinc-50 dark:text-zinc-900">
          Criar conta
        </Link>
        <Link href="/login" className="rounded-md border border-zinc-300 px-4 py-2 text-sm font-medium dark:border-zinc-700">
          Entrar
        </Link>
      </div>
    </main>
  );
}
