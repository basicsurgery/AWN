-- AWN v2 — Run this in Supabase SQL Editor to add director permissions

-- Allow directors to update any resident's profile (role & tenure)
drop policy if exists "Users can update own profile" on profiles;

create policy "Users can update own profile" on profiles
  for update using (auth.uid() = id);

create policy "Directors can update any profile" on profiles
  for update using (
    exists (
      select 1 from profiles
      where id = auth.uid()
      and role in ('director', 'admin')
    )
  );

-- Allow directors to update issue status and notes
drop policy if exists "Directors can update issues" on issues;

create policy "Directors can update issues" on issues
  for update using (
    exists (select 1 from profiles where id = auth.uid() and role in ('director', 'admin'))
    or reporter_id = auth.uid()
  );

-- Allow directors to close polls
drop policy if exists "Directors can update polls" on polls;

create policy "Directors can update polls" on polls
  for update using (
    exists (select 1 from profiles where id = auth.uid() and role in ('director', 'admin'))
  );

-- Create storage bucket for documents (if not exists)
insert into storage.buckets (id, name, public)
values ('documents', 'documents', false)
on conflict (id) do nothing;

-- Storage policy — directors can upload
create policy "Directors can upload documents" on storage.objects
  for insert with check (
    bucket_id = 'documents' and
    exists (select 1 from profiles where id = auth.uid() and role in ('director', 'admin'))
  );

-- Storage policy — authenticated users can read
create policy "Authenticated users can read documents" on storage.objects
  for select using (
    bucket_id = 'documents' and auth.role() = 'authenticated'
  );
