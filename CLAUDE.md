# 🚀 PROJETO SAAS MASTER: DOCS & ANALYTICS AUTOMATION (B2B)

## 📄 1. DEFINIÇÃO DO PRODUTO (SAAS)

### O que é o Produto?

Um **SaaS B2B Híbrido de Documentação & Analytics** projetado para Agências de Marketing, Agências de Software e Times de Engenharia. A plataforma automatiza duas tarefas críticas de alto custo operacional:

1. **Geração Automática de Relatórios de Mídia/Performance:** Coleta métricas de campanhas e tráfego para gerar relatórios visuais e executivos em PDF/Canva em 1 clique.

2. **Portal de Documentação & Engenharia:** Conecta-se a repositórios de código para extrair arquitetura, catalogar endpoints e manter documentações técnicas de APIs e sistemas sempre atualizadas.

### Objetivos do Projeto

1. **Monetização Rápida (MRR):** Planos de assinatura baseados no número de clientes atendidos ou repositórios conectados, cobrados via Mercado Pago.

2. **Engenharia de Elite para Portfólio:** Arquitetura limpa em Next.js App Router, banco relacional com RLS no Supabase/Neon, auditoria contínua de segurança (`OWASP Top 10`) e observabilidade completa (`Sentry` + `Logfire`).

3. **Escalabilidade & Custo Zero Inicial:** Infraestrutura serverless baseada em Supabase/Neon + Vercel, permitindo margem de lucro de quase 100% no início.

## 🛠️ 2. PILHA TECNOLÓGICA (GOLDEN STACK)

| Camada | Tecnologia / Skill MCP | Função no Projeto | 
| ----- | ----- | ----- | 
| **Frontend & UI** | Next.js (App Router), Tailwind CSS, Superdesign | Interface de alta conversão, responsiva e acessível | 
| **Backend & Banco** | Supabase / Neon PostgreSQL | Banco relacional com RLS (Row Level Security) e Auth | 
| **Pagamentos** | Mercado Pago Developer Toolkit | Checkout Pro, assinaturas, webhooks e gestão de transações | 
| **Automação & Scraping** | Firecrawl, Browser Use, Playwright | Extração de dados da web, captura de telas e verificação de métricas | 
| **Integração de Mídia & Docs** | Canva MCP, Mintlify | Geração de assets de apresentação e publicação de documentações | 
| **Segurança** | Claude Security & Security Guidance | Análise de vulnerabilidades OWASP Top 10 e patches automatizados | 
| **Observabilidade** | Sentry + Logfire | Rastreamento de erros em tempo real e performance de rotas serverless | 
| **Infra & Deploy** | Vercel + GitHub / GitLab | CI/CD automatizado com auditoria em commits e deploys instantâneos | 

## 🗄️ 3. ESQUEMA DO BANCO DE DADOS (MODELAGEM DIA 2)

O banco de dados utiliza **PostgreSQL com Row Level Security (RLS)** ativo em todas as tabelas para isolamento entre contas/tenants.

```
-- 1. Organizações / Tenants (Agências ou Empresas)
CREATE TABLE organizations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  slug TEXT UNIQUE NOT NULL,
  logo_url TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Perfil de Usuários e Vínculo com Organização
CREATE TABLE profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  organization_id UUID REFERENCES organizations(id) ON DELETE CASCADE,
  full_name TEXT,
  role TEXT CHECK (role IN ('owner', 'admin', 'member')) DEFAULT 'member',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Assinaturas e Planos (Integração Mercado Pago)
CREATE TABLE subscriptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID REFERENCES organizations(id) ON DELETE CASCADE,
  mp_subscription_id TEXT UNIQUE,
  mp_payer_id TEXT,
  status TEXT CHECK (status IN ('active', 'pending', 'cancelled', 'past_due')) DEFAULT 'pending',
  plan_tier TEXT CHECK (plan_tier IN ('starter', 'pro', 'agency')) DEFAULT 'starter',
  current_period_end TIMESTAMPTZ,
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. Clientes da Agência (Para quem os relatórios e docs são gerados)
CREATE TABLE clients (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID REFERENCES organizations(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  industry TEXT,
  contact_email TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 5. Integrações / Credenciais de APIs Externas
CREATE TABLE integrations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID REFERENCES organizations(id) ON DELETE CASCADE,
  provider TEXT CHECK (provider IN ('meta_ads', 'google_ads', 'ga4', 'github', 'gitlab')) NOT NULL,
  access_token TEXT NOT NULL,
  refresh_token TEXT,
  token_expires_at TIMESTAMPTZ,
  metadata JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 6. Módulo de Performance & Relatórios (MarTech)
CREATE TABLE reports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID REFERENCES organizations(id) ON DELETE CASCADE,
  client_id UUID REFERENCES clients(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  period_start DATE NOT NULL,
  period_end DATE NOT NULL,
  metrics_summary JSONB DEFAULT '{}'::jsonb, -- CTR, ROAS, Conversões, Custo
  pdf_url TEXT,
  status TEXT CHECK (status IN ('draft', 'generating', 'published')) DEFAULT 'draft',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 7. Módulo de Documentação Técnica (DevTool)
CREATE TABLE documentation_projects (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID REFERENCES organizations(id) ON DELETE CASCADE,
  client_id UUID REFERENCES clients(id),
  repository_url TEXT NOT NULL,
  branch TEXT DEFAULT 'main',
  doc_title TEXT NOT NULL,
  status TEXT CHECK (status IN ('pending', 'processing', 'completed', 'failed')) DEFAULT 'pending',
  last_synced_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 8. Documentos & Páginas Geradas
CREATE TABLE documentation_pages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id UUID REFERENCES documentation_projects(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  slug TEXT NOT NULL,
  content_markdown TEXT NOT NULL,
  is_published BOOLEAN DEFAULT true,
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

```

## 📂 4. ESTRUTURA DE DIRETÓRIOS DO PROJETO

```
├── .github/
│   └── workflows/              # Pipelines CI/CD com auditoria de código
├── src/
│   ├── app/                    # Next.js App Router
│   │   ├── (auth)/             # Login, Cadastro, Recuperação de Senha
│   │   ├── (dashboard)/        # Área autenticada
│   │   │   ├── clients/        # Gestão de Clientes da Agência
│   │   │   ├── reports/        # Módulo de Relatórios de Performance
│   │   │   ├── docs/           # Módulo de Documentação de Repositórios
│   │   │   └── settings/       # Configurações de Integradores & Assinatura
│   │   ├── api/                # API Routes & Webhooks
│   │   │   ├── payments/       # Webhooks do Mercado Pago
│   │   │   ├── integrations/   # OAuth callbacks (GitHub, Meta, Google)
│   │   │   └── webhooks/       # Disparos automatizados
│   │   └── page.tsx            # Landing Page de alta conversão
│   ├── components/             # UI Components (Superdesign & Tailwind)
│   │   ├── ui/                 # Botões, Modais, Inputs, Badges
│   │   └── modules/            # Gráficos de Ads, Pré-visualizador de PDF e Markdown
│   ├── lib/                    # Conexões Supabase, Mercado Pago, Sentry, Logfire
│   ├── services/               # Serviços de Negócio (Extração de Ads, Parser de Git)
│   ├── types/                  # Tipagem de dados TypeScript
│   └── utils/                  # Formato de moedas, cálculo de ROAS/CTR, datas
├── public/                     # Imagens estáticas e favicons
├── CLAUDE.md                   # Instruções de contexto do agente
├── package.json
└── tailwind.config.js

```

## 🛡️ 5. DIRETRIZES RÍGIDAS DE SEGURANÇA E PERFORMANCE

1. **Zero Hardcoded Secrets:** Nenhuma chave de API (Mercado Pago, tokens de Ads ou GitHub) deve constar no repositório. Use `.env.local` e variáveis da Vercel.

2. **Row Level Security (RLS) Obrigatório:** Habilite o RLS em 100% das tabelas do Postgres.

3. **Criptografia de Tokens:** Tokens de acesso armazenados na tabela `integrations` devem ser criptografados antes do armazenamento.

4. **Validação de Webhooks de Pagamento:** Rotas de webhook do Mercado Pago devem verificar a assinatura HMAC antes de atualizar o status do plano na tabela `subscriptions`.

5. **Sanitização de Inputs:** Use `Zod` para validar rigorosamente todas as entradas de formulários e payloads de API.

6. **Observabilidade Ativa:** Todos os erros críticos devem disparar alertas no `Sentry`, e o tempo de execução dos parsers de documentos/mídia deve ser medido via `Logfire`.

## 📋 6. WORKFLOW DE DESENVOLVIMENTO (CRONOGRAMA DE 7 DIAS)

### Dia 1: Infraestrutura, Autenticação & RLS

* \[ \] Setup do repositório GitHub https://github.com/ryueik/saas e projeto Next.js com Tailwind CSS.

* \[ \] Conexão com Supabase/Neon e aplicação das migrations do banco de dados.

* \[ \] Habilitação das políticas RLS no banco de dados.

* \[ \] Configuração inicial do `CLAUDE.md`.

### Dia 2: Modelagem de Dados & Serviços Core

* \[ \] Implementação do CRUD de `clients` e `integrations`.

* \[ \] Criação dos serviços de cálculo de métricas (ROAS, CTR, ROI) e parser básico de código.

* \[ \] Conexão com ferramentas de raspagem/automação (Firecrawl/Playwright).

### Dia 3: Gateway de Pagamentos (Mercado Pago)

* \[ \] Configuração de credenciais Sandbox/Produção no Mercado Pago.

* \[ \] Criação do fluxo de assinatura (Planos Starter, Pro e Agency).

* \[ \] Configuração e teste de Webhook HMAC para atualização instantânea de planos.

### Dia 4: Frontend & UI de Alta Conversão

* \[ \] Design da Landing Page otimizada para B2B usando diretrizes de **Frontend Design / Superdesign**.

* \[ \] Desenvolvimento do Dashboard (Visualização de relatórios, listas de projetos e gráficos).

* \[ \] Componente visual de exportação/leitura de relatórios em PDF.

### Dia 5: Observabilidade e Auditoria de Segurança

* \[ \] Configuração do Sentry e Logfire.

* \[ \] Execução das análises de código (`Security guidance` / `securitymaxxing`).

* \[ \] Correção de vulnerabilidades apontadas nas varreduras.

### Dia 6: Documentação & Testes E2E

* \[ \] Geração da documentação pública e de desenvolvedores via Mintlify.

* \[ \] Teste do ciclo completo: Cadastro -> Assinatura Mercado Pago -> Conexão de Cliente -> Geração de Relatório/Doc.

* \[ \] Otimização do tempo de carregamento de páginas e requisições.

### Dia 7: Deploy & Lançamento

* \[ \] Publicação do projeto em produção na Vercel.

* \[ \] Publicação de repositório no GitHub para apresentação a recrutadores/investidores.

* \[ \] Abertura oficial do canal de vendas B2B.

## 💬 7. CONVENÇÕES DE CÓDIGO E COMMITS

* **Linguagem:** Código, comentários e documentação em **Inglês**.

* **Padrão de Nomeação:** `camelCase` para funções e variáveis, `PascalCase` para componentes React e tipos, `kebab-case` para arquivos.

* **Commits Semânticos:**

  * `feat: ...` (Nova funcionalidade)

  * `fix: ...` (Correção de bugs)

  * `sec: ...` (Melhorias ou correções de segurança)

  * `docs: ...` (Atualização de documentação)

  * `refactor: ...` (Otimização de código)
## 🔧 8. NOTAS TÉCNICAS PARA O AGENTE

* **Next.js 16:** o antigo `middleware.ts` agora é `src/proxy.ts` (exporta `proxy`). Cache Components está ativo: dados dinâmicos (`cookies()`, `searchParams`, queries) precisam ficar dentro de `<Suspense>`. Leia `node_modules/next/dist/docs/` antes de usar APIs novas (veja `AGENTS.md`).
* **Tailwind CSS v4:** configuração via CSS (`@import "tailwindcss"` em `src/app/globals.css`); não existe `tailwind.config.js`.
* **Supabase:** use `src/lib/supabase/server.ts` em Server Components/Actions/Route Handlers e `src/lib/supabase/client.ts` só em Client Components. Para identidade no servidor use `supabase.auth.getClaims()` ou `getUser()`, nunca `getSession()`.
* **Migrations:** ficam em `supabase/migrations/`. Toda tabela nova precisa de `enable row level security` + policies. Checagens de tenant usam `private.is_org_member(org_id)` e `private.has_org_role(org_id, roles)`.
* **Multi-tenant:** toda tabela de negócio tem `organization_id NOT NULL`. FKs para `clients` são compostas `(client_id, organization_id)`, então é impossível ligar um relatório/doc a um cliente de outra organização.
* **Campos de servidor:** `subscriptions` (inteira), `profiles.role`, `profiles.organization_id` e os tokens de `integrations` não são legíveis/graváveis pelo usuário via API; só pelo servidor com a service role (webhooks, server actions com criptografia).
* **Variáveis de ambiente:** documente em `.env.example`; valores reais só em `.env.local` e na Vercel.
