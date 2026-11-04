---
# rbw-eajh
title: 'Fix #364: rbw edit corrupts entries with an individual item key (PR #368)'
status: completed
type: bug
priority: critical
created_at: 2026-11-04T20:01:59Z
updated_at: 2026-11-04T20:07:59Z
parent: rbw-4nie
---

Upstream issue: https://github.com/doy/rbw/issues/364
Upstream PR: https://github.com/doy/rbw/pull/368 (alternatives: #366, #371)

`rbw edit` re-encrypts password/notes with the user (or org) key and never
sends the cipher's `key` field on PUT. For entries that have their own item
key (common for entries created by the web vault / browser extension) this
produces a mixed-key cipher that no client can decrypt (`invalid mac`).

Fix: encrypt with the item key when the entry has one, and preserve `key`
in the PUT request.
