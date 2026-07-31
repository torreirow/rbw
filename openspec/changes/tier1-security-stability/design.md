## Context

See proposal.md — Why. Three patches from upstream, applied with minimal
delta to our fork. Two of them interact with code we already modified:

- PR #328 (`src/api.rs`) — we added `prelogin_blocking()` and `server_config()`
  in the `rbw-doctor` change. PR #328 introduces `BITWARDEN_CLIENT_VERSION`
  and applies it to the sync and cipher-update paths. Our new blocking clients
  are also missing this header.
- PR #332 (`src/bin/rbw-agent/agent.rs`) — no conflict with our changes.
- PR #325 (`Cargo.lock`) — pure dependency bump, no code conflict.

## Goals / Non-Goals

Goals: apply all three upstream patches cleanly; extend the client-version
header to our new blocking clients for consistency.

Non-goals: changing any other request headers; auditing all other blocking
clients for missing headers (out of scope for a security patch).

## Decisions

### Decision: Apply upstream diffs verbatim, extend header to our additions

PR #328 adds `const BITWARDEN_CLIENT_VERSION: &str = "2024.12.0"` and applies it
to the default async client and the cipher-update blocking client. Our
`prelogin_blocking()` and `server_config()` both create a bare
`reqwest::blocking::Client::new()` without any headers. We extend PR #328 to
also set `Bitwarden-Client-Version` on these two calls.

`server_config()` calls an unauthenticated endpoint (`GET /api/config`) where
the header is cosmetic, but consistent behaviour across all outgoing requests
is the right default.

Alternative considered: leave our new clients without the header since they
work today. Rejected — `rbw edit` broke exactly because one client was
inconsistent; we should not repeat the pattern.

### Decision: No structural change to the blocking client pattern

Each blocking call still creates its own `reqwest::blocking::Client::new()`.
Introducing a shared client builder helper would be a larger refactor and is
out of scope for a security patch.

## Risks / Trade-offs

- Cargo.lock bump is a transitive change only — no direct dependency version
  changes. If either crate introduces a regression in a patch release that is not
  caught without tests, it would be silent. Mitigation: `cargo deny check` passes;
  upstream validated with `cargo test`.
- `BITWARDEN_CLIENT_VERSION = "2024.12.0"` is a static string. If Bitwarden
  deprecates this version string in a future server release, `rbw edit` (and
  our new blocking calls) would break again. Mitigation: same risk existed
  before; this PR consolidates it to one place so it only needs updating once.

## Open Questions

None.
