Session rules – Madtown Pit Dashboard

Follow these in every session in this project.

Context
I'm an adult mentor on FRC Team 1323 (Madtown Robotics) and the one using the app. Students mostly work on paper checklists that get scanned back in.
The app is ONE published artifact shared by every session: https://claude.ai/artifact/EQN4NqUShdNM7ci6mxXFEW
1. Know your area

At the start of the session, say which area you're working on. Only change code in that area.

Area	Owns	Data collections
Overall app	Header, navigation, theme tokens, fonts, Store / write() / sync, shared helpers, Settings, Pit board, and any area that has no dedicated session	meta (team, eventName, queueLead, delay)
Checklist	Checklist view (Match status, Build & print, editor), numberCl, runState, PDF printing, paper scanning, newRunSheet / createRun	checklists, prints, runs, scans; settings keys activeRunId, defaultChecklistId
Matches	Matches view, match / paste-schedule sheets, nextMatch, nmCard, countdowns	matches
Batteries	Batteries view, battery sheets (add/edit, log check, pick, detail, cutoffs, labels), batInfo, suggestBatteries, Beak photo reading	batteries, battlog; settings key batt; match fields batteryId / battery
Repairs	Repairs view, repairSheet, repair summary	repairs
Inventory	Inventory view, parts, locations and storage map sheets	inventory, locations, pitmap
Notes	Notes view and note sheet	notes
If a change needs another area's code, shared code, or the theme, stop and ask me first.
Only the Overall app session changes shared code (header, nav, tokens, Store, helpers).
2. Publishing
Read the live artifact (Artifact read on the URL above) before editing, and build on that version. Never start from an old local copy; another session may have changed it.
Publish back to the same URL. Never create a new artifact.
On republish, leave out capabilities so the current ones carry over (assets, db, user with profile scope, sample with images, downloads). Never remove one. Add a new one only after asking me.
Syntax-check the script before publishing. After publishing, read the stored data back once.
If a publish is refused because another session published first, reapply your changes on top of the new live version. Never overwrite it.
End by listing which functions and CSS you changed, so other sessions can stay in sync.
3. Contracts between areas (don't break these)
runState(run) returns { c:{done,missing,unclear,pending,total}, pct, verified, items, secs, N, cl }. Used by the Pit board and the nav badge.
repairSheet(null, {title, subsystem, found, runId, itemId}) logs a repair from a checklist item; the repair id is stored in runs.flags[itemId].
Repairs subtract the parts they use from inventory.qty and add them back when removed.
nextMatch(), mlabel(), effTime() and nmCard() are used by the Pit board, the header chip, the Checklist and Batteries.
A match's battery is matches.batteryId (plus matches.battery = label text, for older records). Read it with batOfMatch(m). batInfo(b) returns {grade, ready, why, last, lastIr, uses, cycles, avgDrop, drops, upcoming, logs} and is used by the Pit board, nav badge and next-match card.
Battery QR labels open ARTIFACT_URL#b-<batteryId>; boot handles that hash.
Shared helpers to reuse, not rewrite: write(), stamp(), openSheet(), confirmBox(), toast(), seg() / segVal(), ICON, settings() / saveSettings(), whoOf(), loadPdfLib(), ensureSample(), shrink().
To change one of these, ask first and update every place that uses it.
4. Data rules
Write only to your area's collections and settings keys.
Never rename fields, change ids, or delete my data. Changes must keep existing records working (old runs, sheets already printed, existing matches, repairs and battery readings).
Checklist item ids never change. Printed numbers (3.4 / 3.4a) and the prints/{CODE}-v{N} maps stay backward compatible. Battery ids never change (printed QR labels point at them).
Direct database writes (ArtifactData) only when I ask, and always with if_version.
5. Design rules
Modern theme in Team 1323 blue (
#0024FF). Use only the existing CSS tokens (--brand, --brand-ink, --ok, --warn, --bad, --surface, …), with no hard-coded colors. Must work in light and dark mode.
Fonts: Figtree (body), Saira Semi Condensed (headings), JetBrains Mono (numbers), Michroma (brand only).
Built for a fast-paced pit: touch targets at least 48px, buttons labeled with exactly what they do, any function reachable in one or two taps, and phone and tablet layouts both working.
Confirm before anything destructive, using the in-page confirmBox (browser confirm() doesn't work in the artifact).
The page can't open the print dialog; files go out through the downloads capability.
