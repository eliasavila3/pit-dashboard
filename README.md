# pit-dashboard

Madtown Robotics (FRC 1323) pit dashboard: one static page (`index.html`) backed by Supabase.

| Piece | Where |
| --- | --- |
| Page | `index.html` + `config.js` (host anywhere static: GitHub Pages, Netlify, Vercel…) |
| Database, sign-in rules, photo bucket | `supabase/schema.sql` |
| Photo reading (checklist scans, Battery Beak) | `supabase/functions/read-image/` |

## Set up

1. Create a Supabase project.
2. In the SQL editor, run `supabase/schema.sql`. Then add the team to `pit_members` (example at the bottom of the file). `editor` can change the board and `viewer` can only look.
3. Under **Authentication > URL Configuration**, set the Site URL to where the page is hosted and add that address to the Redirect URLs. Sign-in links bring people back there.
4. Deploy the photo reader:
   ```bash
   supabase secrets set ANTHROPIC_API_KEY=sk-ant-...
   supabase functions deploy read-image
   ```
5. In `config.js`, set `supabaseUrl` and `supabaseAnonKey` (Project settings > API). Then host both files over HTTPS. The camera needs HTTPS.

People sign in from **Settings > Board sign-in** with an emailed link. Anyone can request a link, but only emails in `pit_members` can see or change the board. Without signing in, the page saves to that browser only.

## Notes

- Each collection (`meta`, `checklists`, `prints`, `runs`, `scans`, `matches`, `inventory`, `locations`, `repairs`, `notes`, `pitmap`, `batteries`, `battlog`) is a table of `id` + `data` (jsonb). `data` holds the record exactly as the app writes it.
- Updates merge into the stored record on the server (`pit_merge`), so two devices editing different fields don't overwrite each other.
- Photos are in the public `pit-photos` bucket under random 32-character ids. Only editors can add or remove them.
- Battery QR labels point at this page's address plus `#b-<batteryId>`. Labels printed from the old Claude artifact still point at the artifact.
