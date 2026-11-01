# pit-dashboard

Madtown Robotics (FRC 1323) pit dashboard: one static page (`index.html`) backed by Supabase.

| Piece | Where |
| --- | --- |
| Page | `index.html` + `config.js` (host anywhere static: GitHub Pages, Netlify, Vercel…) |
| Database, sign-in rules, photo bucket | `supabase/schema.sql` |
| Photo reading (checklist scans, Battery Beak) | In the page, on each device (checklist page reader; Tesseract.js for the Battery Beak). No server or API key. |

## Set up

1. Create a Supabase project.
2. In the SQL editor, run `supabase/schema.sql`. Then add the team to `pit_members` (example at the bottom of the file). `editor` can change the board and `viewer` can only look.
3. Under **Authentication > URL Configuration**, set the Site URL to where the page is hosted and add that address to the Redirect URLs. Sign-in links bring people back there.
4. Under **Authentication > Sign In / Providers > Email**, keep Email on, keep **Allow new users to sign up** on, and turn **Confirm email** off. People sign in by typing their email; no email is sent.
5. In `config.js`, set `supabaseUrl` and `supabaseAnonKey` (Project settings > API). Then host both files over HTTPS. The camera needs HTTPS.

When no one is signed in, the page shows a sign-in screen that asks for an email. Every account uses the same built-in password (`BOARD_PW` in `index.html`), so this is light security: anyone who knows a member's email can sign in as them. Only emails in `pit_members` can see or change the board. Accounts made before this used emailed links; run `supabase/migrations/2026-11-01-email-sign-in.sql` once so they can sign in. If Supabase can't be reached, the page says so and keeps retrying instead of saving to the browser. Sign out from **Settings > Board sign-in**. Only with no Supabase project in `config.js` does the page save to that browser only.

## Notes

- Each collection (`meta`, `checklists`, `prints`, `runs`, `scans`, `matches`, `inventory`, `locations`, `repairs`, `notes`, `pitmap`, `batteries`, `battlog`) is a table of `id` + `data` (jsonb). `data` holds the record exactly as the app writes it.
- Updates merge into the stored record on the server (`pit_merge`), so two devices editing different fields don't overwrite each other.
- Photos are in the public `pit-photos` bucket under random 32-character ids. Only editors can add or remove them.
- Battery QR labels point at this page's address plus `#b-<batteryId>`. Labels printed from the old Claude artifact still point at the artifact.
