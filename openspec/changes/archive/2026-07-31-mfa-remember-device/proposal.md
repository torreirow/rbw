## Why

Every `rbw login` requires the user to enter their MFA code, even though the
Bitwarden API supports a "remember this device" mechanism that skips MFA for
~30 days on a trusted device. Because rbw always runs on the same machine with
the same persistent `device_id`, this friction is entirely avoidable.

## What Changes

- `ConnectTokenReq` gains a `twoFactorRemember` field, set to `true` whenever
  the user enters an MFA code.
- `ConnectTokenRes` captures the `TwoFactorToken` the server returns after a
  successful MFA login.
- `Db` gains a `two_factor_token` field to persist the remember token across
  agent restarts.
- The login flow in `rbw-agent` tries the stored remember token first
  (provider `Remember = 5`); if the server rejects it, it falls back
  transparently to asking for an MFA code via pinentry.
- On `rbw purge` the token is cleared together with the rest of the database
  (no special handling needed).

## Capabilities

### New Capabilities

- `mfa-remember-device`: The agent caches a server-issued "remember this
  device" token after each MFA login and uses it on subsequent logins to skip
  the MFA prompt. The token is persisted in the local vault database and
  cleared on `rbw purge`.

### Modified Capabilities

*(none — no existing spec-level requirement changes)*

## Non-goals

- Making the remember behaviour configurable. rbw is a single-user tool that
  always runs on the same machine; always remembering is the right default.
- Client-side expiry tracking. The server controls token lifetime; rbw simply
  retries with MFA when the server rejects a stale token.
- Supporting providers other than Authenticator, Yubikey, and Email — this
  change does not add new provider support.

## Impact

- `src/api.rs` — `ConnectTokenReq`, `ConnectTokenRes`, `login()` return type
- `src/db.rs` — `Db` struct (backward-compatible, serde default)
- `src/actions.rs` — `login()` signature threads the remember token through
- `src/bin/rbw-agent/actions.rs` — login flow: try remember token → fallback
  to pinentry → persist new token
- IPC protocol (`src/protocol.rs`) is **not** touched; the remember token is
  an internal agent concern, invisible to the CLI.
