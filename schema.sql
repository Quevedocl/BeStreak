-- ============================================================
-- BeStreak — esquema de base de datos para Supabase
-- Pega esto completo en el SQL Editor de tu proyecto Supabase
-- ============================================================

-- 1) TABLAS -----------------------------------------------------

create table if not exists groups (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  punishment text not null,
  join_code text not null unique,
  created_at timestamptz not null default now()
);

create table if not exists profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  username text not null,
  group_id uuid not null references groups(id) on delete cascade,
  streak_count integer not null default 0,
  status text not null default 'active' check (status in ('active', 'failed')),
  created_at timestamptz not null default now()
);

create table if not exists posts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references profiles(id) on delete cascade,
  group_id uuid not null references groups(id) on delete cascade,
  image_url text not null,
  date date not null,
  created_at timestamptz not null default now(),
  unique (user_id, date) -- una sola foto por usuario por día
);

-- 2) ROW LEVEL SECURITY ------------------------------------------

alter table groups enable row level security;
alter table profiles enable row level security;
alter table posts enable row level security;

-- groups: cualquier usuario autenticado puede leer (necesario para
-- buscar un grupo por código) y crear grupos nuevos.
create policy "groups: leer" on groups for select
  using (auth.role() = 'authenticated');

create policy "groups: crear" on groups for insert
  with check (auth.role() = 'authenticated');

-- profiles: cada quien lee/edita su propia fila, y además puede ver
-- las filas de los miembros de su mismo grupo (para mostrar el feed).
create policy "profiles: leer propio y del grupo" on profiles for select
  using (
    id = auth.uid()
    or group_id in (select group_id from profiles where id = auth.uid())
  );

create policy "profiles: crear propio" on profiles for insert
  with check (id = auth.uid());

create policy "profiles: actualizar propio" on profiles for update
  using (id = auth.uid());

-- posts: cada quien ve los posts de su propio grupo, pero solo
-- puede crear posts a su propio nombre.
create policy "posts: leer del grupo" on posts for select
  using (
    group_id in (select group_id from profiles where id = auth.uid())
  );

create policy "posts: crear propio" on posts for insert
  with check (user_id = auth.uid());

-- 3) STORAGE -------------------------------------------------------
-- Crea manualmente un bucket PÚBLICO llamado "daily-snaps" desde
-- Storage → New bucket (marca "Public bucket"). Luego corre esto:

create policy "daily-snaps: lectura publica"
  on storage.objects for select
  using (bucket_id = 'daily-snaps');

create policy "daily-snaps: solo subir a tu propia carpeta"
  on storage.objects for insert
  with check (
    bucket_id = 'daily-snaps'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "daily-snaps: solo reemplazar tu propia foto"
  on storage.objects for update
  using (
    bucket_id = 'daily-snaps'
    and (storage.foldername(name))[1] = auth.uid()::text
  );
