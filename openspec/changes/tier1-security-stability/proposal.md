## Why

Three upstream PRs address active security advisories and critical stability
regressions that affect real users: two transitive dependencies carry known CVEs,
the agent silently panics under a timing condition that is easy to hit on macOS,
and `rbw edit` has been broken for users on recent Bitwarden server versions.
These are low-risk, targeted patches that should ship before any new features.

## What Changes

- `Cargo.lock`: bump `bytes` 1.11.0 → 1.11.1 (RUSTSEC-2026-0007) and
  `rustls-webpki` 0.103.8 → 0.103.10 (RUSTSEC-2026-0049)
- `src/bin/rbw-agent/agent.rs`: replace `.unwrap()` with `log::warn!()` on
  socket send failure so the agent does not silently crash when a client
  disconnects mid-pinentry (broken pipe, os error 32)
- `src/api.rs`: introduce `BITWARDEN_CLIENT_VERSION` constant and apply it
  consistently to all request paths, including the cipher-update blocking
  client that was missing the header and causing `rbw edit` to fail

## Non-goals

- Upgrading any direct Cargo dependency beyond the minimum version that clears
  the advisories
- Changing the user-visible behaviour of any command beyond restoring `rbw edit`

## Capabilities

### New Capabilities

*(none)*

### Modified Capabilities

- `dependency-management`: transitive dependencies with active RUSTSEC advisories
  must be patched as part of normal maintenance
- `error-handling`: the agent must not panic when a client disconnects while a
  response is in flight; send failures are logged as warnings

## Impact

- `Cargo.lock` only for the dependency bump (no `Cargo.toml` changes)
- `src/bin/rbw-agent/agent.rs` (rbw-agent) — 13 additions, 6 deletions
- `src/api.rs` (shared library) — 4 additions, 2 deletions; our new
  `prelogin_blocking()` and `server_config()` blocking clients should also
  receive the `Bitwarden-Client-Version` header for consistency
