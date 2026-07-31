## Context

See proposal.md — Why. The key constraint driving the design is that `rbw doctor`
must work even when the agent is broken, so it cannot be routed through the
existing IPC-based `actions.rs` path used by most CLI commands.

The Bitwarden API exposes two unauthenticated endpoints that are useful here:
- `GET /api/config` — returns server name, version, and feature flags. Works on
  both official Bitwarden and Vaultwarden without credentials.
- `POST /accounts/prelogin` — returns KDF type and parameters. Already used by
  `src/api.rs`; requires only an email address.

## Goals / Non-Goals

Goals: implement all checks listed in `specs/doctor-command/spec.md` with no new
dependencies and no IPC changes. Output is always human-readable terminal text.

Non-goals: machine-readable output, repair actions, feature-flag interpretation
beyond display.

## Decisions

### Decision: Doctor runs directly in the CLI binary, not via the agent

The command reads the config file and db file directly via `rbw::config::Config`
and `rbw::db::Db`, makes its own blocking HTTP calls, and optionally talks to the
agent via the existing socket only to read lock state.

Alternative considered: routing everything through a new IPC action `Doctor`. 
Rejected because a non-running agent is exactly the failure mode doctor is meant
to diagnose.

### Decision: New `server_config()` method on `api::Client`

A new struct `ServerConfig` (with `server_name`, `server_url`, `version` fields,
all `Option<String>`) and a new method `fn server_config(&self) -> Result<ServerConfig>`
on `api::Client` call `GET /api/config` via the blocking reqwest client. This
keeps all Bitwarden HTTP logic in `src/api.rs`.

`/api/config` is on the _api_ URL, not the identity URL. The client already has
`api_url()` helper for this.

### Decision: Agent check via socket existence + optional IPC ping

Doctor tries to connect to the agent socket. If the connect succeeds, it sends a
`Message::CheckLock` request (already defined in `protocol.rs`) to determine lock
state. If connect fails, it reports "not running" and skips vault details.

This uses `src/bin/rbw/sock.rs` directly — the same socket helper the CLI already
uses — so no new socket code is needed.

### Decision: Read db.json directly for entry count, last sync, and MFA token

`rbw::db::Db::load()` (blocking) gives entry count, KDF fields, and
`two_factor_token` without involving the agent. Last-sync time is approximated by
the file modification timestamp of `db.json` via `std::fs::metadata`.

Alternative considered: adding a new IPC message to return db stats. Rejected as
over-engineering; the data is in a local file and the agent is optional anyway.

### Decision: Output format is plain text with ✓ / ✗ markers

Section headers printed in plain text (no ANSI color codes for now, to remain
friendly to terminal-less use). Each check result is prefixed with `  ✓` or `  ✗`
depending on success. Failed checks do not abort subsequent checks.

```
Configuration
  ✓ Email:       user@example.com
  ✓ Server:      https://vault.example.com

Server
  ✓ Reachable (124ms)
  ✓ Type:        Vaultwarden 1.32.0
  ✓ KDF:         Argon2id (mem: 64MB, iter: 3, par: 4)

Agent
  ✓ Running

Vault
  ✓ Unlocked (42 entries)
  ✓ Last sync:   2025-07-30 10:23 UTC
  ✓ MFA token:   cached
```

## Data Flow

```
rbw doctor (CLI binary)
│
├── Read ~/.config/rbw/config.json
│     → email, base_url, identity_url
│
├── api::Client::server_config()      [GET /api/config, no auth]
│     → server name, version
│
├── api::Client::prelogin(email)      [POST /accounts/prelogin, no auth]
│     → kdf, iterations, memory, parallelism
│
├── Try unix socket connect
│   ├── Fail → "agent not running", skip vault section
│   └── OK → send CheckLock, recv response
│         → locked / unlocked
│
└── rbw::db::Db::load()               [read db.json directly]
      → entries.len(), two_factor_token
      + fs::metadata(db_file).modified() → last sync time
```

## Risks / Trade-offs

- `/api/config` is not part of the official Bitwarden API specification and could
  change or be removed in future server versions. Mitigation: all fields are
  deserialized with `#[serde(default)]` so a missing or changed response degrades
  gracefully to "unknown".
- File modification time is a proxy for last sync, not the actual sync timestamp.
  If the db is written for other reasons (e.g. a future field is added) the time
  will be misleading. Mitigation: acceptable for a diagnostic display; a future
  change could add an explicit `last_synced` field to `Db`.

## Open Questions

None.
