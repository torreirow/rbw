---
# rbw-dwmn
title: 'Fix #377: rbw edit with empty non-tty stdin wipes password and notes'
status: completed
type: bug
priority: high
created_at: 2026-11-04T20:01:59Z
updated_at: 2026-11-04T20:07:59Z
parent: rbw-4nie
---

Upstream issue: https://github.com/doy/rbw/issues/377 (no upstream PR)

When stdin is not a terminal, `rbw edit` reads the new contents from stdin
instead of launching $EDITOR. Empty (or whitespace-only) input is accepted
and saved: the password and notes are silently cleared.

Fix: refuse to save when the piped contents are empty.
