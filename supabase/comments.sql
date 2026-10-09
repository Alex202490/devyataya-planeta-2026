-- Run in a dedicated Supabase project for Девятая планета.
create table public.film_comments (
 id bigint generated always as identity primary key,
 author_name text not null check (char_length(author_name) between 2 and 60),
 body text not null check (char_length(body) between 5 and 2000),
 rating smallint not null check (rating between 1 and 5),
 status text not null default 'pending' check (status in ('pending','approved','rejected')),
 created_at timestamptz not null default now()
);
create table public.comment_moderators (
 user_id uuid primary key references auth.users(id) on delete cascade
);
alter table public.film_comments enable row level security;
alter table public.comment_moderators enable row level security;
create policy "Read approved comments" on public.film_comments for select to anon,authenticated using (status='approved' or exists (select 1 from public.comment_moderators m where m.user_id=(select auth.uid())));
create policy "Submit pending comments" on public.film_comments for insert to anon,authenticated with check (status='pending');
create policy "Moderators update comments" on public.film_comments for update to authenticated using (exists (select 1 from public.comment_moderators m where m.user_id=(select auth.uid()))) with check (exists (select 1 from public.comment_moderators m where m.user_id=(select auth.uid())));
create policy "Moderators delete comments" on public.film_comments for delete to authenticated using (exists (select 1 from public.comment_moderators m where m.user_id=(select auth.uid())));
create policy "Moderators read membership" on public.comment_moderators for select to authenticated using (user_id=(select auth.uid()));
-- After creating your admin user in Authentication, add their UUID securely in SQL Editor:
-- insert into public.comment_moderators(user_id) values ('ADMIN_AUTH_USER_UUID');
-- IMPORTANT: Add CAPTCHA/rate limiting through an Edge Function before enabling public submissions at scale.
