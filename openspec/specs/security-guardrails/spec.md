## Purpose
Security invariants that MUST be preserved across all changes to rbw.
The codebase handles cryptographic keys, passwords, and vault data —
these rules prevent accidental exposure or weakening of security properties.

## Requirements

### Requirement: Secrets are stored in Locked buffers
Sensitive byte data (master keys, decryption keys, plaintext passwords) MUST
be stored in `crate::locked::Keys` or `crate::locked::Password`, which use
`mlock` to prevent swapping to disk and `zeroize` to clear on drop.

#### Scenario: Adding a new key field to agent State
- **WHEN** adding a field to `State` that holds cryptographic key material
- **THEN** use `crate::locked::Keys` or `crate::locked::Password` — never `Vec<u8>` or `String`

#### Scenario: Temporary secret in a function
- **WHEN** a function derives or decrypts a temporary key
- **THEN** wrap it in a `Locked` type or call `zeroize::Zeroize::zeroize()` before it drops

---

### Requirement: No secrets in log output
Log messages MUST NEVER include passwords, keys, or decrypted vault content.

#### Scenario: Logging an error involving a secret
- **WHEN** logging errors from decrypt/encrypt operations
- **THEN** log the operation name and error type only — never include plaintext values
- **THEN** `log::debug!` and `log::trace!` are also subject to this rule

---

### Requirement: ptrace and core dump protection must be maintained
The agent SHALL call `crate::debugger::disable_ptrace_and_core_dumps()` on
startup before entering the event loop.

#### Scenario: Modifying agent startup
- **WHEN** changing `src/bin/rbw-agent/main.rs` startup sequence
- **THEN** ensure the ptrace/core dump protection call is still present and occurs first

---

### Requirement: OpenSSL must not be used
The `openssl-sys` crate is explicitly banned. All TLS MUST use rustls via
reqwest's `rustls-tls-native-roots` feature.

#### Scenario: Adding a new crate with TLS
- **WHEN** adding a dependency that does network I/O
- **THEN** ensure it uses rustls, not openssl — verify with `cargo deny check bans`

---

### Requirement: Clipboard writes are routed through the agent
When copying vault data to the clipboard, code SHALL route through
`crate::actions::clipboard_store()` which sends a `ClipboardStore` IPC request.

#### Scenario: New clipboard feature
- **WHEN** adding a feature that copies vault data to the clipboard
- **THEN** route through `crate::actions::clipboard_store()` in the `rbw` CLI
- **THEN** never write to the clipboard directly in the CLI process

---

### Requirement: No plaintext secrets on disk
Vault data stored in the local database MUST always be in Bitwarden
cipher-string format. The database file SHALL never contain plaintext passwords
or decrypted key material.

#### Scenario: Caching a decrypted value
- **WHEN** it is tempting to cache a decrypted password for performance
- **THEN** do not — only the in-memory agent state may hold decrypted keys, never disk
