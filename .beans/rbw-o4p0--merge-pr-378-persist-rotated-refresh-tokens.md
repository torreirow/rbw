---
# rbw-o4p0
title: 'Merge PR #378: persist rotated refresh tokens'
status: completed
type: bug
priority: normal
created_at: 2026-11-04T20:01:59Z
updated_at: 2026-11-04T20:52:17Z
parent: rbw-4nie
---

Upstream PR: https://github.com/doy/rbw/pull/378

`ConnectRefreshTokenRes` only deserializes `access_token`, so a rotated
`refresh_token` from the server is dropped and the original is replayed on
every refresh. Harmless against Bitwarden (no rotation), but breaks every
refresh after login on SSO-backed Vaultwarden, where the IdP consumes the token
on exchange.

PR deserializes it as Option, threads it through
`with_exchange_refresh_token` and persists it at the call sites.
+185 -61, 5 files. Touches the same call sites as #362; do these together.
Priority depends on whether we use Vaultwarden SSO.
