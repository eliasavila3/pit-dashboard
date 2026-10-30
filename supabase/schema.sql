-- Madtown Pit Dashboard: Supabase database setup.
-- Run once in the Supabase SQL editor (safe to run again).
--
-- Every collection the app used in the artifact database is a table of
--   id text primary key, data jsonb   (the record exactly as before, minus its id)
-- so no field is renamed and existing ids keep working.

-- ---------------------------------------------------------------
-- Who can use the board
-- ---------------------------------------------------------------
-- Add people here by email (lowercase). role: 'editor' can change the board,
-- 'viewer' can only look. name is shown next to their checks, repairs and notes.
create table if not exists public.pit_members (
  email      text primary key check (email = lower(email)),
  role       text not null default 'editor' check (role in ('editor', 'viewer')),
  name       text not null default '',
  user_id    uuid unique references auth.users (id) on delete set null,
  created_at timestamptz not null default now()
);
alter table public.pit_members enable row level security;

-- The signed-in user's role, or null when their email isn't on the board.
create or replace function public.pit_role()
returns text
language sql stable security definer
set search_path = public
as $$
  select role from public.pit_members
  where email = lower(coalesce(auth.jwt() ->> 'email', ''))
$$;

-- Called by the app after sign-in: links the auth user to their member row
-- (so names resolve) and returns their role.
create or replace function public.pit_claim()
returns text
language plpgsql security definer
set search_path = public
as $$
begin
  update public.pit_members
     set user_id = auth.uid()
   where email = lower(coalesce(auth.jwt() ->> 'email', ''))
     and user_id is distinct from auth.uid();
  return public.pit_role();
end
$$;

revoke all on function public.pit_role()  from public, anon;
revoke all on function public.pit_claim() from public, anon;
grant execute on function public.pit_role()  to authenticated;
grant execute on function public.pit_claim() to authenticated;

drop policy if exists pit_members_read on public.pit_members;
create policy pit_members_read on public.pit_members
  for select to authenticated using (public.pit_role() is not null);

-- ---------------------------------------------------------------
-- Collections
-- ---------------------------------------------------------------
create or replace function public.pit_touch()
returns trigger
language plpgsql
as $$
begin
  new.updated_at := now();
  new.updated_by := auth.uid();
  return new;
end
$$;

do $$
declare
  t text;
begin
  foreach t in array array['meta','checklists','prints','runs','scans','matches','inventory',
                           'locations','repairs','notes','pitmap','batteries','battlog'] loop
    execute format($f$
      create table if not exists public.%I (
        id         text primary key,
        data       jsonb not null default '{}'::jsonb,
        updated_at timestamptz not null default now(),
        updated_by uuid default auth.uid()
      )$f$, t);
    execute format('alter table public.%I enable row level security', t);

    execute format('drop policy if exists pit_read on public.%I', t);
    execute format('create policy pit_read on public.%I for select to authenticated using (public.pit_role() is not null)', t);
    execute format('drop policy if exists pit_insert on public.%I', t);
    execute format('create policy pit_insert on public.%I for insert to authenticated with check (public.pit_role() = ''editor'')', t);
    execute format('drop policy if exists pit_update on public.%I', t);
    execute format('create policy pit_update on public.%I for update to authenticated using (public.pit_role() = ''editor'') with check (public.pit_role() = ''editor'')', t);
    execute format('drop policy if exists pit_delete on public.%I', t);
    execute format('create policy pit_delete on public.%I for delete to authenticated using (public.pit_role() = ''editor'')', t);

    execute format('drop trigger if exists pit_touch on public.%I', t);
    execute format('create trigger pit_touch before insert or update on public.%I for each row execute function public.pit_touch()', t);

    -- realtime: every device sees changes within seconds
    if not exists (select 1 from pg_publication_tables
                   where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = t) then
      execute format('alter publication supabase_realtime add table public.%I', t);
    end if;
  end loop;
end
$$;

-- Same rule as deepMerge() in index.html: objects merge key by key,
-- anything else (arrays, numbers, strings, null) replaces.
create or replace function public.pit_deep_merge(t jsonb, s jsonb)
returns jsonb
language plpgsql immutable
as $$
declare
  k text;
  v jsonb;
  r jsonb := coalesce(t, '{}'::jsonb);
begin
  for k, v in select * from jsonb_each(coalesce(s, '{}'::jsonb)) loop
    if jsonb_typeof(v) = 'object' and jsonb_typeof(r -> k) = 'object' then
      r := r || jsonb_build_object(k, public.pit_deep_merge(r -> k, v));
    else
      r := r || jsonb_build_object(k, v);
    end if;
  end loop;
  return r;
end
$$;

-- write(col, id, "update", patch): merges the patch into the stored record in
-- one statement, so two devices updating different fields never overwrite each
-- other. Runs as the caller, so row-level security still applies. Does nothing
-- when the record doesn't exist (same as before).
create or replace function public.pit_merge(col text, doc_id text, patch jsonb)
returns void
language plpgsql security invoker
set search_path = public
as $$
begin
  if not (col = any (array['meta','checklists','prints','runs','scans','matches','inventory',
                           'locations','repairs','notes','pitmap','batteries','battlog'])) then
    raise exception 'unknown collection %', col using errcode = '22023';
  end if;
  execute format('update public.%I set data = public.pit_deep_merge(data, $1) where id = $2', col)
    using patch, doc_id;
end
$$;

revoke all on function public.pit_merge(text, text, jsonb) from public, anon;
grant execute on function public.pit_merge(text, text, jsonb) to authenticated;

-- ---------------------------------------------------------------
-- Photos (storage unit fronts, scanned checklist pages)
-- ---------------------------------------------------------------
-- Public read: photos load by URL like the old /_blob/ links. File names are
-- random 32-character ids, so they can't be guessed. Only editors can add or
-- remove photos.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('pit-photos', 'pit-photos', true, 10485760, array['image/jpeg', 'image/png', 'image/webp'])
on conflict (id) do nothing;

drop policy if exists pit_photos_read on storage.objects;
create policy pit_photos_read on storage.objects
  for select to authenticated using (bucket_id = 'pit-photos' and public.pit_role() is not null);
drop policy if exists pit_photos_insert on storage.objects;
create policy pit_photos_insert on storage.objects
  for insert to authenticated with check (bucket_id = 'pit-photos' and public.pit_role() = 'editor');
drop policy if exists pit_photos_delete on storage.objects;
create policy pit_photos_delete on storage.objects
  for delete to authenticated using (bucket_id = 'pit-photos' and public.pit_role() = 'editor');

-- ---------------------------------------------------------------
-- Add yourself and the team (edit, then run)
-- ---------------------------------------------------------------
-- insert into public.pit_members (email, role, name) values
--   ('mentor@example.com',  'editor', 'Mentor'),
--   ('student@example.com', 'editor', 'Ana R.'),
--   ('parent@example.com',  'viewer', 'Parent')
-- on conflict (email) do update set role = excluded.role, name = excluded.name;
