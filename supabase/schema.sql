-- Schéma du serveur de synchronisation (Supabase / PostgreSQL).
-- À coller dans Supabase > SQL Editor, puis « Run ». On peut le relancer sans
-- risque : il met à jour un schéma plus ancien sans perdre les données.
--
-- Chaque compte a son propre stock : chaque ligne porte l'identifiant de son
-- propriétaire (owner_id) et un compte ne voit et ne modifie que ses lignes.

-- Numéro croissant partagé par les tables : chaque appareil retient
-- le dernier numéro vu et ne redemande que ce qui est plus récent.
create sequence if not exists sync_seq;

create table if not exists categories (
  owner_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  id text not null,
  name text not null,
  archived boolean not null default false,
  updated_at timestamptz not null,
  seq bigint not null default nextval('sync_seq'),
  primary key (owner_id, id)
);

create table if not exists products (
  owner_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  id text primary key,
  name text not null,
  category text not null,
  attributes text not null default '{}',
  purchase_price_cents integer,
  sale_price_cents integer,
  alert_threshold integer not null default 0,
  barcode text,
  archived boolean not null default false,
  deleted boolean not null default false,
  updated_at timestamptz not null,
  seq bigint not null default nextval('sync_seq')
);

-- Mise à jour : suppression de produits (la ligne reste, marquée supprimée).
alter table products add column if not exists deleted boolean not null default false;

create table if not exists movements (
  owner_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  id text primary key,
  product_id text not null references products (id),
  type text not null,
  delta integer not null,
  unit_price_cents integer,
  note text,
  cancels_id text references movements (id),
  created_at timestamptz not null,
  seq bigint not null default nextval('sync_seq')
);

-- Mise à jour d'un schéma sans comptes séparés (versions 1 et 2) :
-- les données existantes sont rattachées au premier compte créé.
do $$
declare
  t text;
  first_user uuid := (select id from auth.users order by created_at limit 1);
begin
  foreach t in array array['categories', 'products', 'movements'] loop
    if not exists (select 1 from information_schema.columns
                   where table_schema = 'public' and table_name = t and column_name = 'owner_id') then
      execute format('alter table %I add column owner_id uuid default auth.uid()
                      references auth.users (id) on delete cascade', t);
      execute format('update %I set owner_id = $1', t) using first_user;
      -- Sans aucun compte, ces lignes ne seraient visibles par personne.
      execute format('delete from %I where owner_id is null', t);
      execute format('alter table %I alter column owner_id set not null', t);
    end if;
  end loop;

  -- Deux comptes peuvent avoir une catégorie au même identifiant (ex. « autre »).
  if (select count(*) from information_schema.key_column_usage
      where table_schema = 'public' and table_name = 'categories'
        and constraint_name = 'categories_pkey') = 1 then
    alter table categories drop constraint categories_pkey;
    alter table categories add primary key (owner_id, id);
  end if;
end;
$$;

drop index if exists categories_seq;
drop index if exists products_seq;
drop index if exists movements_seq;
create index if not exists categories_owner_seq on categories (owner_id, seq);
create index if not exists products_owner_seq on products (owner_id, seq);
create index if not exists movements_owner_seq on movements (owner_id, seq);

-- Produit ou catégorie : la modification la plus récente gagne. Une version plus ancienne
-- envoyée en retard par un appareil resté hors ligne est ignorée.
create or replace function keep_latest() returns trigger
language plpgsql as $$
begin
  if new.updated_at < old.updated_at then
    return null;
  end if;
  new.seq := nextval('sync_seq');
  return new;
end;
$$;

drop trigger if exists products_keep_latest on products;
create trigger products_keep_latest before update on products
  for each row execute function keep_latest();

drop trigger if exists categories_keep_latest on categories;
create trigger categories_keep_latest before update on categories
  for each row execute function keep_latest();

-- Ancien nom de la fonction (version 1 du schéma).
drop function if exists products_keep_latest();

-- Chaque compte ne voit et ne modifie que ses propres lignes. Pas d'effacement réel :
-- un produit supprimé est marqué (deleted) pour que les autres appareils le sachent.
alter table categories enable row level security;
alter table products enable row level security;
alter table movements enable row level security;

drop policy if exists "lecture" on categories;
drop policy if exists "ajout" on categories;
drop policy if exists "modification" on categories;
create policy "lecture" on categories for select to authenticated
  using (owner_id = (select auth.uid()));
create policy "ajout" on categories for insert to authenticated
  with check (owner_id = (select auth.uid()));
create policy "modification" on categories for update to authenticated
  using (owner_id = (select auth.uid())) with check (owner_id = (select auth.uid()));

drop policy if exists "lecture" on products;
drop policy if exists "ajout" on products;
drop policy if exists "modification" on products;
create policy "lecture" on products for select to authenticated
  using (owner_id = (select auth.uid()));
create policy "ajout" on products for insert to authenticated
  with check (owner_id = (select auth.uid()));
create policy "modification" on products for update to authenticated
  using (owner_id = (select auth.uid())) with check (owner_id = (select auth.uid()));

drop policy if exists "lecture" on movements;
drop policy if exists "ajout" on movements;
create policy "lecture" on movements for select to authenticated
  using (owner_id = (select auth.uid()));
-- Un mouvement ne peut viser qu'un produit du même compte.
create policy "ajout" on movements for insert to authenticated
  with check (
    owner_id = (select auth.uid())
    and exists (select 1 from products p where p.id = product_id and p.owner_id = (select auth.uid()))
  );

-- Supabase donne déjà ces droits par défaut ; on les écrit pour être explicite.
grant usage on sequence sync_seq to authenticated;
grant select, insert, update on categories to authenticated;
grant select, insert, update on products to authenticated;
grant select, insert on movements to authenticated;

-- Mises à jour en direct : le serveur prévient les appareils connectés au même
-- compte dès qu'une ligne change. Chaque compte ne reçoit que ses propres
-- lignes (les règles de sécurité ci-dessus s'appliquent aussi ici).
do $$
declare
  t text;
begin
  if exists (select 1 from pg_publication where pubname = 'supabase_realtime') then
    foreach t in array array['categories', 'products', 'movements'] loop
      if not exists (select 1 from pg_publication_tables
                     where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = t) then
        execute format('alter publication supabase_realtime add table %I', t);
      end if;
    end loop;
  end if;
end;
$$;
