-- Day 1: multi-tenant schema (organizations, profiles, subscriptions, clients,
-- integrations, reports, documentation) with Row Level Security on every table.
--
-- Tenancy model: every user belongs to exactly one organization (agency).
-- RLS checks go through SECURITY DEFINER helpers in the `private` schema, which
-- PostgREST does not expose, so policies on `profiles` never recurse.

create schema if not exists private;

-- ---------------------------------------------------------------------------
-- Tables
-- ---------------------------------------------------------------------------

-- 1. Organizations / tenants
create table public.organizations (
  id uuid primary key default gen_random_uuid(),
  name text not null check (char_length(name) between 1 and 120),
  slug text not null unique check (slug ~ '^[a-z0-9]+(-[a-z0-9]+)*$' and char_length(slug) <= 80),
  logo_url text check (logo_url is null or logo_url ~ '^https://'),
  created_at timestamptz not null default now()
);

-- 2. User profiles, linked to an organization
create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  organization_id uuid references public.organizations (id) on delete cascade,
  full_name text check (char_length(full_name) <= 120),
  role text not null default 'member' check (role in ('owner', 'admin', 'member')),
  created_at timestamptz not null default now()
);
create index profiles_organization_id_idx on public.profiles (organization_id);

-- 3. Subscriptions (Mercado Pago). One per organization; written only by the server.
create table public.subscriptions (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null unique references public.organizations (id) on delete cascade,
  mp_subscription_id text unique,
  mp_payer_id text,
  status text not null default 'pending' check (status in ('active', 'pending', 'cancelled', 'past_due')),
  plan_tier text not null default 'starter' check (plan_tier in ('starter', 'pro', 'agency')),
  current_period_end timestamptz,
  updated_at timestamptz not null default now()
);

-- 4. The agency's own clients
create table public.clients (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations (id) on delete cascade,
  name text not null check (char_length(name) between 1 and 160),
  industry text check (char_length(industry) <= 80),
  contact_email text check (contact_email is null or contact_email ~* '^[^@\s]+@[^@\s]+\.[^@\s]+$'),
  created_at timestamptz not null default now(),
  -- Lets child tables reference (client_id, organization_id) so a row can never
  -- point at a client from another tenant.
  unique (id, organization_id)
);
create index clients_organization_id_idx on public.clients (organization_id);

-- 5. External API integrations. Tokens MUST be encrypted by the app before insert.
create table public.integrations (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations (id) on delete cascade,
  provider text not null check (provider in ('meta_ads', 'google_ads', 'ga4', 'github', 'gitlab')),
  access_token text not null,
  refresh_token text,
  token_expires_at timestamptz,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);
create index integrations_organization_id_idx on public.integrations (organization_id);

-- 6. Performance reports (MarTech)
create table public.reports (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations (id) on delete cascade,
  client_id uuid not null,
  title text not null check (char_length(title) between 1 and 200),
  period_start date not null,
  period_end date not null,
  metrics_summary jsonb not null default '{}'::jsonb, -- CTR, ROAS, conversions, cost
  pdf_url text,
  status text not null default 'draft' check (status in ('draft', 'generating', 'published')),
  created_at timestamptz not null default now(),
  check (period_end >= period_start),
  foreign key (client_id, organization_id)
    references public.clients (id, organization_id) on delete cascade
);
create index reports_organization_id_idx on public.reports (organization_id);
create index reports_client_id_idx on public.reports (client_id);

-- 7. Technical documentation projects (DevTool)
create table public.documentation_projects (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations (id) on delete cascade,
  client_id uuid,
  repository_url text not null check (repository_url ~ '^https://'),
  branch text not null default 'main' check (char_length(branch) <= 255),
  doc_title text not null check (char_length(doc_title) between 1 and 200),
  status text not null default 'pending' check (status in ('pending', 'processing', 'completed', 'failed')),
  last_synced_at timestamptz,
  created_at timestamptz not null default now(),
  -- Deleting a client keeps the docs project and only clears client_id.
  foreign key (client_id, organization_id)
    references public.clients (id, organization_id) on delete set null (client_id)
);
create index documentation_projects_organization_id_idx on public.documentation_projects (organization_id);
create index documentation_projects_client_id_idx on public.documentation_projects (client_id);

-- 8. Generated documentation pages
create table public.documentation_pages (
  id uuid primary key default gen_random_uuid(),
  project_id uuid not null references public.documentation_projects (id) on delete cascade,
  title text not null check (char_length(title) between 1 and 200),
  slug text not null check (slug ~ '^[a-z0-9]+(-[a-z0-9]+)*(/[a-z0-9]+(-[a-z0-9]+)*)*$'),
  content_markdown text not null,
  is_published boolean not null default true,
  updated_at timestamptz not null default now(),
  unique (project_id, slug)
);

-- ---------------------------------------------------------------------------
-- Helper functions (not exposed through the API)
-- ---------------------------------------------------------------------------

create function private.is_org_member(org_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.profiles p
    where p.id = (select auth.uid()) and p.organization_id = org_id
  );
$$;

create function private.has_org_role(org_id uuid, roles text[])
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.profiles p
    where p.id = (select auth.uid()) and p.organization_id = org_id and p.role = any (roles)
  );
$$;

grant usage on schema private to authenticated;
revoke execute on all functions in schema private from public, anon;
grant execute on function private.is_org_member(uuid) to authenticated;
grant execute on function private.has_org_role(uuid, text[]) to authenticated;

create function private.set_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger subscriptions_set_updated_at
  before update on public.subscriptions
  for each row execute function private.set_updated_at();

create trigger documentation_pages_set_updated_at
  before update on public.documentation_pages
  for each row execute function private.set_updated_at();

-- On sign-up: create the user's organization (they become its owner), the
-- profile and a pending starter subscription.
create function private.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  org_name text := left(coalesce(nullif(trim(new.raw_user_meta_data ->> 'organization_name'), ''), split_part(new.email, '@', 1)), 120);
  base_slug text;
  new_org_id uuid;
begin
  base_slug := trim(both '-' from regexp_replace(
    translate(lower(org_name), 'áàâãäéèêëíìîïóòôõöúùûüçñ', 'aaaaaeeeeiiiiooooouuuucn'),
    '[^a-z0-9]+', '-', 'g'
  ));
  if base_slug = '' then
    base_slug := 'org';
  end if;

  insert into public.organizations (name, slug)
  values (org_name, left(base_slug, 70) || '-' || substr(replace(gen_random_uuid()::text, '-', ''), 1, 8))
  returning id into new_org_id;

  insert into public.profiles (id, organization_id, full_name, role)
  values (new.id, new_org_id, left(new.raw_user_meta_data ->> 'full_name', 120), 'owner');

  insert into public.subscriptions (organization_id) values (new_org_id);

  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function private.handle_new_user();

-- ---------------------------------------------------------------------------
-- Row Level Security
-- ---------------------------------------------------------------------------

alter table public.organizations enable row level security;
alter table public.profiles enable row level security;
alter table public.subscriptions enable row level security;
alter table public.clients enable row level security;
alter table public.integrations enable row level security;
alter table public.reports enable row level security;
alter table public.documentation_projects enable row level security;
alter table public.documentation_pages enable row level security;

-- The anon role gets nothing; everything below is for signed-in users.
revoke all on all tables in schema public from anon;

-- organizations: members read; owners/admins edit. Created by the sign-up trigger.
create policy organizations_select on public.organizations
  for select to authenticated using (private.is_org_member(id));
create policy organizations_update on public.organizations
  for update to authenticated
  using (private.has_org_role(id, array['owner', 'admin']))
  with check (private.has_org_role(id, array['owner', 'admin']));
revoke insert, delete, update on public.organizations from authenticated;
grant update (name, logo_url) on public.organizations to authenticated;

-- profiles: see yourself and your teammates; edit only your own display name.
-- role / organization_id changes go through server-side code with the service role.
create policy profiles_select on public.profiles
  for select to authenticated
  using (id = (select auth.uid()) or private.is_org_member(organization_id));
create policy profiles_update_own on public.profiles
  for update to authenticated
  using (id = (select auth.uid()))
  with check (id = (select auth.uid()));
revoke insert, delete, update on public.profiles from authenticated;
grant update (full_name) on public.profiles to authenticated;

-- subscriptions: read-only for members; only Mercado Pago webhooks (service role) write.
create policy subscriptions_select on public.subscriptions
  for select to authenticated using (private.is_org_member(organization_id));
revoke insert, update, delete on public.subscriptions from authenticated;

-- clients: full CRUD for members of the organization.
create policy clients_all on public.clients
  for all to authenticated
  using (private.is_org_member(organization_id))
  with check (private.is_org_member(organization_id));

-- integrations: owners/admins only. Token columns are never readable via the API.
create policy integrations_all on public.integrations
  for all to authenticated
  using (private.has_org_role(organization_id, array['owner', 'admin']))
  with check (private.has_org_role(organization_id, array['owner', 'admin']));
revoke select on public.integrations from authenticated;
grant select (id, organization_id, provider, token_expires_at, metadata, created_at)
  on public.integrations to authenticated;

-- reports: full CRUD for members.
create policy reports_all on public.reports
  for all to authenticated
  using (private.is_org_member(organization_id))
  with check (private.is_org_member(organization_id));

-- documentation_projects: full CRUD for members.
create policy documentation_projects_all on public.documentation_projects
  for all to authenticated
  using (private.is_org_member(organization_id))
  with check (private.is_org_member(organization_id));

-- documentation_pages: access follows the parent project's organization.
create policy documentation_pages_all on public.documentation_pages
  for all to authenticated
  using (
    exists (
      select 1 from public.documentation_projects dp
      where dp.id = project_id and private.is_org_member(dp.organization_id)
    )
  )
  with check (
    exists (
      select 1 from public.documentation_projects dp
      where dp.id = project_id and private.is_org_member(dp.organization_id)
    )
  );
