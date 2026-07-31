## Why

Diagnosing rbw problems today requires manual inspection of config files, socket
paths, and raw JSON databases. There is no single command that answers "is my
setup healthy and what server am I talking to?" A dedicated `rbw doctor` command
fills that gap.

## What Changes

- New subcommand `rbw doctor` added to the CLI.
- New API method `server_config()` in `src/api.rs` that calls the public
  `GET /api/config` endpoint to retrieve server type, version, and feature flags.
- `doctor` runs entirely in the CLI binary — no agent required — so it works even
  when the agent is broken or not yet started.
- If the agent is running, `doctor` additionally reports vault lock state and entry
  count via existing IPC.

## Capabilities

### New Capabilities

- `doctor-command`: A `rbw doctor` subcommand that checks local config validity,
  server reachability, server identity (Bitwarden vs Vaultwarden + version), KDF
  settings from prelogin, agent running/stopped status, vault state (locked /
  unlocked / not synced), entry count, last sync time, and MFA remember token
  presence.

### Modified Capabilities

## Non-goals

- Not a connectivity repair tool — doctor only reports, never changes config.
- Does not discover available 2FA providers (those are only returned inside a
  login error response, not a public endpoint).
- Does not check organisation membership or server-side feature flags beyond what
  `/api/config` freely exposes.
- No `--json` output flag in this first version.

## Impact

- `src/api.rs`: new struct `ServerConfig` + method `server_config()` (no auth,
  direct `reqwest` GET).
- `src/bin/rbw/commands.rs`: new `doctor()` function.
- `src/bin/rbw/main.rs`: new `Doctor` variant in the `Opt` enum.
- No IPC protocol changes; agent interaction is optional and read-only (existing
  `CheckLock` / `Version` messages suffice).
- No new dependencies.
