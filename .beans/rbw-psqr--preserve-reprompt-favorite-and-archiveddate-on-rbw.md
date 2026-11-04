---
# rbw-psqr
title: Preserve reprompt, favorite and archivedDate on rbw edit
status: completed
type: bug
priority: high
created_at: 2026-11-04T20:10:59Z
updated_at: 2026-11-04T20:12:17Z
parent: rbw-4nie
---

Found in the fork analysis; upstream m11y PR https://github.com/doy/rbw/pull/371 fixes this too, as part of a larger change.

`rbw edit` sends a full cipher PUT without `reprompt`, `favorite` and
`archivedDate`. Both servers treat a missing field as "reset":

| field        | Vaultwarden          | Bitwarden          |
|--------------|----------------------|--------------------|
| reprompt     | reset to none        | reset to none      |
| favorite     | unchanged (Option)   | reset to false     |
| archivedDate | entry is unarchived  | entry is unarchived |

So editing an entry silently removes master password reprompt protection
(security downgrade) and unarchives it, and on Bitwarden also unfavorites it.

Fix: keep `favorite` and `archivedDate` from sync in the local db and send
them, together with the already stored reprompt type, on every PUT.

Out of scope: `lastKnownRevisionDate` (conflict detection, also in #371).
