---
# rbw-tub1
title: 'Merge PR #332: fix silent panic when client disconnects during pinentry'
status: done
type: bug
priority: critical
created_at: 2026-07-31T09:01:41Z
updated_at: 2026-07-31T11:10:59Z
parent: rbw-k7r3
---

Upstream PR: https://github.com/doy/rbw/pull/332

Agent crashes (silent tokio panic) when client disconnects mid-pinentry (e.g. terminal closed).
User sees: `EOF while parsing a value at line 1 column 0`

Fix: handle broken pipe gracefully in agent.rs instead of .unwrap() on socket send.
