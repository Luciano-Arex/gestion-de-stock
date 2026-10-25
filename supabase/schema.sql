-- Schéma du serveur de synchronisation (Supabase / PostgreSQL).
-- À coller une fois dans Supabase > SQL Editor, puis « Run ».

-- Numéro croissant partagé par les deux tables : chaque appareil retient
-- le dernier numéro vu et ne redemande que ce qui est plus récent.
create sequence if not exists sync_seq;

create table if not exists products (
  id text primary key,
  name text not null,
  category text not null,
  attributes text not null default '{}',
  purchase_price_cents integer,
  sale_price_cents integer,
  alert_threshold integer not null default 0,
  barcode text,
  archived boolean not null default false,
  updated_at timestamptz not null,
  seq bigint not null default nextval('sync_seq')
);

create table if not exists movements (
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

create index if not exists products_seq on products (seq);
create index if not exists movements_seq on movements (seq);

-- Produit : la modification la plus récente gagne. Une version plus ancienne
-- envoyée en retard par un appareil resté hors ligne est ignorée.
create or replace function products_keep_latest() returns trigger
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
  for each row execute function products_keep_latest();

-- Accès réservé au compte connecté. Pas de suppression : on archive.
alter table products enable row level security;
alter table movements enable row level security;

drop policy if exists "lecture" on products;
drop policy if exists "ajout" on products;
drop policy if exists "modification" on products;
create policy "lecture" on products for select to authenticated using (true);
create policy "ajout" on products for insert to authenticated with check (true);
create policy "modification" on products for update to authenticated using (true);

drop policy if exists "lecture" on movements;
drop policy if exists "ajout" on movements;
create policy "lecture" on movements for select to authenticated using (true);
create policy "ajout" on movements for insert to authenticated with check (true);

-- Supabase donne déjà ces droits par défaut ; on les écrit pour être explicite.
grant usage on sequence sync_seq to authenticated;
grant select, insert, update on products to authenticated;
grant select, insert on movements to authenticated;
