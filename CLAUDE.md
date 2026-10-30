# Session rules – Madtown Pit Dashboard

Follow these in every session in this project. The same text lives in the repository as `CLAUDE.md`; if the two differ, the repository copy wins.

## Context
- I'm an adult mentor on FRC Team 1323 (Madtown Robotics) and the one using the app. Students mostly work on paper checklists that get scanned back in.
- The app is a live website now. The old claude.ai artifact is retired: never edit or republish it.

| Piece | Where |
|---|---|
| Live site | https://pit-dashboard-beryl.vercel.app |
| Code (master copy) | GitHub `eliasavila3/pit-dashboard`, branch `main` |
| Hosting | Vercel, Hobby plan; deploys `main` automatically and posts a preview link on every pull request |
| Data, sign-in, photos | Supabase project (tables, Auth email link, storage bucket) |
| Photo reading (checklist scans, Battery Beak) | Supabase Edge Function `read-image`, calls the Claude API with the `ANTHROPIC_API_KEY` secret |
| Who can get in | Supabase table `pit_members` (email, role `editor` or `viewer`) |

## 1. Know your area
At the start of the session, say which area you're working on. Only change code in that area.

| Area | Owns | Data (Supabase) |
|---|---|---|
| **Overall app** | Header, navigation, theme tokens, fonts, data layer / write() / sync, sign-in screen, shared helpers, Settings, Pit board, config.js, and any area that has no dedicated session | `meta` (team, eventName, queueLead, delay), `pit_members` |
| **Checklist** | Checklist view (Match status, Build & print, editor), numberCl, runState, PDF printing, paper scanning, newRunSheet / createRun | `checklists`, `prints`, `runs`, `scans`; settings keys `activeRunId`, `defaultChecklistId` |
| **Matches** | Matches view, match / paste-schedule sheets, nextMatch, nmCard, countdowns | `matches` |
| **Batteries** | Batteries view, battery sheets (add/edit, log check, pick, detail, cutoffs, labels), batInfo, suggestBatteries, Beak photo reading, charger cameras | `batteries`, `battlog`; settings key `batt`; match fields `batteryId` / `battery` |
| **Repairs** | Repairs view, repairSheet, repair summary | `repairs` |
| **Inventory** | Inventory view, parts, locations and storage map sheets | `inventory`, `locations`, `pitmap` |
| **Notes** | Notes view and note sheet | `notes` |

- If a change needs another area's code, shared code, the theme, the database setup, or the `read-image` function, stop and ask me first.
- Only the Overall app session changes shared code (header, nav, tokens, data layer, helpers, config.js).

## 2. How a change goes live
Code changes are made with Claude Code on the GitHub repository. A chat without repository access gives advice or drafts only, never edits the live app another way.

1. Start from the latest `main`. Work on a new branch named for the change (for example `batteries-charger-cameras`).
2. Open a pull request with a short summary: what changed, which functions and CSS changed, and whether it needs a database or `read-image` step.
3. Vercel posts a preview link on the pull request. I test there on the mini PC and a phone. Previews use the same live Supabase data, so test with obviously fake records and delete them after.
4. I merge. Never merge or push to `main` yourself unless I say so.
5. If `main` moved while you worked, update the branch from `main` and fix conflicts by keeping both sides' changes. Never overwrite another session's work.
6. Syntax-check the code before opening the pull request, and keep the app running with no build step (plain static files).

## 3. Database and server changes
- Database changes go in a new SQL file under `supabase/` (for example `supabase/migrations/2026-11-02-charger-cams.sql`) that I run in the Supabase SQL Editor **before** merging. Say so at the top of the pull request.
- Only add tables, columns or policies. Never rename or drop a table or column, and never loosen security rules, so the live app keeps working while the change rolls out.
- Every new table gets row-level security that uses `pit_role()`: signed-in members can read, editors can write.
- Changes to `supabase/functions/read-image` don't go live on merge. Tell me to paste the new code into Supabase (Edge Functions → read-image) and deploy it. Keep that function a single file.
- Secrets (the Claude API key, the service-role or secret key) never go in the page, `config.js`, or the repository. `config.js` holds only the Project URL (`https://<id>.supabase.co`, nothing after it) and the publishable key.

## 4. Contracts between areas (don't break these)
Function names below are from the original app. If the port renamed one, use the current name and keep its behavior.
- `runState(run)` returns `{ c:{done,missing,unclear,pending,total}, pct, verified, items, secs, N, cl }`. Used by the Pit board and the nav badge.
- `repairSheet(null, {title, subsystem, found, runId, itemId})` logs a repair from a checklist item; the repair id is stored in `runs.flags[itemId]`.
- Repairs subtract the parts they use from `inventory.qty` and add them back when removed.
- `nextMatch()`, `mlabel()`, `effTime()` and `nmCard()` are used by the Pit board, the header chip, the Checklist and Batteries.
- A match's battery is `matches.batteryId` (plus `matches.battery` = label text, for older records). Read it with `batOfMatch(m)`. `batInfo(b)` returns `{grade, ready, why, last, lastIr, uses, cycles, avgDrop, drops, upcoming, logs}` and is used by the Pit board, nav badge and next-match card.
- Battery QR labels open `<site address>#b-<batteryId>` (the site address comes from `config.js` `boardUrl`, or the page's own address when blank); boot handles that hash.
- Shared helpers to reuse, not rewrite: `write()`, `stamp()`, `openSheet()`, `confirmBox()`, `toast()`, `seg()` / `segVal()`, `ICON`, `settings()` / `saveSettings()`, `whoOf()`, `loadPdfLib()`, `shrink()`, and the photo-reading call to `read-image`.
- To change one of these, ask first and update every place that uses it.

## 5. Data rules
- Write only to your area's tables and settings keys.
- Never rename fields, change ids, or delete my data. Changes must keep existing records working (old runs, sheets already printed, existing matches, repairs and battery readings).
- Checklist item ids never change. Printed numbers (3.4 / 3.4a) and the `prints/{CODE}-v{N}` maps stay backward compatible. Battery ids never change (printed QR labels point at them).
- Records imported from the claude.ai version keep their original ids. Their `uid` fields are old claude.ai user ids and don't match Supabase users; leave them as they are.
- Direct database edits (SQL that changes rows, or the Table Editor) only when I ask, and say exactly which rows first.

## 6. Design rules
- Modern theme in Team 1323 blue (#0024FF). Use only the existing CSS tokens (`--brand`, `--brand-ink`, `--ok`, `--warn`, `--bad`, `--surface`, `--on-hdr`, …), with no hard-coded colors. Must work in light and dark mode.
- Fonts: Figtree (body), Saira Semi Condensed (headings and the header title), JetBrains Mono (numbers), Michroma (checklist builder season headings only). The header logo is the 1323 wordmark image.
- Built for a fast-paced pit: touch targets at least 48px, buttons labeled with exactly what they do, any function reachable in one or two taps, and phone and tablet layouts both working. The main screen is the wall-mounted touchscreen on the pit mini PC.
- Confirm before anything destructive, using the in-page `confirmBox` (keeps the look consistent and works on the touchscreen).
- Keep the app usable when the pit internet drops: show the last data and say clearly when changes are waiting to sync. Photo reading needs internet; say so instead of failing silently.
