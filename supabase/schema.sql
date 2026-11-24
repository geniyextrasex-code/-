-- Сололевелинг: таблица для облачной синхронизации.
-- Запустить один раз: Supabase → SQL Editor → New query → вставить → Run.

create table if not exists public.sll_state (
  user_id    uuid primary key references auth.users (id) on delete cascade,
  data       jsonb not null,
  updated_at timestamptz not null default now(),
  -- защита от раздувания: одна копия не больше ~2 МБ
  constraint sll_state_size check (pg_column_size(data) < 2000000)
);

-- Row Level Security: каждый пользователь видит и меняет только свою строку.
-- Без этого любой, у кого есть publishable-ключ (он лежит в коде страницы), прочитал бы чужие данные.
alter table public.sll_state enable row level security;

drop policy if exists "sll own select" on public.sll_state;
drop policy if exists "sll own insert" on public.sll_state;
drop policy if exists "sll own update" on public.sll_state;
drop policy if exists "sll own delete" on public.sll_state;

create policy "sll own select" on public.sll_state
  for select to authenticated using ((select auth.uid()) = user_id);
create policy "sll own insert" on public.sll_state
  for insert to authenticated with check ((select auth.uid()) = user_id);
create policy "sll own update" on public.sll_state
  for update to authenticated using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);
create policy "sll own delete" on public.sll_state
  for delete to authenticated using ((select auth.uid()) = user_id);

-- Анонимам доступа нет вообще, вошедшим — только через политики выше.
revoke all on public.sll_state from anon;
grant select, insert, update, delete on public.sll_state to authenticated;
