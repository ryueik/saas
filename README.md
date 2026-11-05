# SaaS · Docs & Analytics para agências

Relatórios de performance automáticos e documentação técnica de repositórios para agências de marketing e de software.

Next.js 16 (App Router) + Tailwind CSS v4 + TypeScript + Supabase Auth com RLS.
Veja o plano completo e as regras do projeto em [CLAUDE.md](./CLAUDE.md).

## Rodando localmente

1. `npm install`
2. `cp .env.example .env.local` e preencha com as chaves do seu projeto Supabase
   (Project Settings → API: URL e *publishable key*).
3. Aplique a migração em `supabase/migrations/` (SQL Editor do Supabase ou `supabase db push`).
4. Em Authentication → URL Configuration, adicione `http://localhost:3000/auth/callback` aos Redirect URLs.
5. `npm run dev` e abra http://localhost:3000

## Modelo de dados

Multi-tenant por `organizations`. Ao se cadastrar, o usuário ganha uma organização (como `owner`), um `profile` e uma `subscription` *starter/pending*. Todas as 8 tabelas têm RLS; detalhes em `supabase/migrations/20261105000000_initial_schema.sql` e no CLAUDE.md.

## Scripts

- `npm run dev` · `npm run build` · `npm run lint` · `npm run typecheck`
