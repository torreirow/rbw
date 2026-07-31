---
# rbw-f6jf
title: 'Merge PR #325: patch RUSTSEC-2026-0007 + RUSTSEC-2026-0049 (bytes + rustls-webpki)'
status: todo
type: task
priority: critical
created_at: 2026-07-31T09:01:31Z
updated_at: 2026-07-31T09:01:31Z
parent: rbw-k7r3
---

Upstream PR: https://github.com/doy/rbw/pull/325

Cargo.lock-only update:
- bytes 1.11.0 → 1.11.1  (RUSTSEC-2026-0007)
- rustls-webpki 0.103.8 → 0.103.10  (RUSTSEC-2026-0049)

Current repo is vulnerable. `cargo deny check` would fail on these advisories.
Simple fix: `cargo update --package bytes --package rustls-webpki`
