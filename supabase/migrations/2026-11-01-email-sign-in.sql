-- Email-only sign-in (no emailed link).
-- Run once in the Supabase SQL Editor before merging.
--
-- The page now signs everyone in with their email plus one shared board password
-- (BOARD_PW in index.html). Accounts made earlier by an emailed link have no password,
-- so this gives them that password.
--
-- Rows changed: auth.users rows whose email is in public.pit_members AND that have no
-- password yet. Their ids stay the same, so nothing that points at them breaks.
-- No tables, columns or policies change. Safe to run more than once.
--
-- If you ever change BOARD_PW in index.html, change it here too.

update auth.users u
   set encrypted_password = extensions.crypt('madtown-1323-pit-board', extensions.gen_salt('bf')),
       email_confirmed_at = coalesce(u.email_confirmed_at, now()),
       updated_at = now()
 where lower(u.email) in (select email from public.pit_members)
   and coalesce(u.encrypted_password, '') = '';

-- Shows who was updated (and who in pit_members has no account yet; they get one the first time they sign in).
select m.email, m.role, (u.id is not null) as has_account
  from public.pit_members m
  left join auth.users u on lower(u.email) = m.email
 order by m.email;
