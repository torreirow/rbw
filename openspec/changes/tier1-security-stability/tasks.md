## 1. Dependency security patches (Cargo.lock only)

- [x] 1.1 Run `cargo update --package bytes --package rustls-webpki` to bump
  `bytes` 1.11.0 → 1.11.1 (RUSTSEC-2026-0007) and
  `rustls-webpki` 0.103.8 → 0.103.10 (RUSTSEC-2026-0049)
- [x] 1.2 Verify `Cargo.lock` shows the new versions and no `Cargo.toml` was
  modified

## 2. Agent panic fix — broken pipe on client disconnect (PR #332)

- [x] 2.1 In `src/bin/rbw-agent/agent.rs` around line 82, replace the
  `.unwrap()` on `sock.send(Response::Error {...}).await` with a
  `log::warn!("failed to send error response to client: {send_err:#}")` so
  the spawned tokio task exits cleanly on broken pipe instead of panicking

## 3. Consistent Bitwarden-Client-Version header (PR #328 + extension)

- [x] 3.1 In `src/api.rs`, add `const BITWARDEN_CLIENT_VERSION: &str = "2024.12.0";`
  near the existing `DEVICE_TYPE` constant
- [x] 3.2 Replace `env!("CARGO_PKG_VERSION")` in the default async client's
  `Bitwarden-Client-Version` header with `BITWARDEN_CLIENT_VERSION`
- [x] 3.3 Replace the hardcoded `"2024.12.0"` string on the sync blocking
  client's `.header("Bitwarden-Client-Version", ...)` call with
  `BITWARDEN_CLIENT_VERSION`
- [x] 3.4 Add `.header("Bitwarden-Client-Version", BITWARDEN_CLIENT_VERSION)`
  to the cipher-update blocking client (the one missing the header in
  upstream PR #328)
- [x] 3.5 Add `.header("Bitwarden-Client-Version", BITWARDEN_CLIENT_VERSION)`
  to our `prelogin_blocking()` blocking client
- [x] 3.6 Add `.header("Bitwarden-Client-Version", BITWARDEN_CLIENT_VERSION)`
  to our `server_config()` blocking client

## 4. Build check

- [x] 4.1 Run `cargo check` — zero errors
- [x] 4.2 Run `cargo clippy --all-targets` — zero new warnings
