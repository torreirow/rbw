## Purpose
Rules for managing Cargo dependencies in rbw. The project uses `cargo-deny`
(`deny.toml`) to enforce policies. All dependency changes MUST pass `cargo deny check`.
## Requirements
### Requirement: No duplicate dependency versions except approved skips
New dependencies MUST NOT introduce duplicate versions of existing crates.
`cargo deny` is configured with `multiple-versions = "deny"`.

#### Scenario: Adding a new dependency
- **WHEN** adding a crate to `Cargo.toml`
- **THEN** run `cargo deny check bans` to verify no new duplicate versions are introduced
- **THEN** if a duplicate is unavoidable, add a `skip` entry to `deny.toml` with a comment

#### Scenario: Current approved skips
- **WHEN** `bitflags`, `thiserror`, or `rand` appear in two versions
- **THEN** these are approved: bitflags (region-rs), thiserror (ssh-agent-lib), rand (ecosystem transition)

---

### Requirement: No wildcard version constraints
All `Cargo.toml` dependency versions MUST use explicit SemVer constraints.
`wildcards = "deny"` is set in `deny.toml`.

#### Scenario: Adding a dependency
- **WHEN** writing a dependency entry in `Cargo.toml`
- **THEN** always specify a version (e.g. `"1.0.0"`, `"^1.2"`) — never `"*"`

---

### Requirement: OpenSSL must not be used as a transitive dependency
`openssl-sys` is explicitly denied in `deny.toml`. New crates SHALL use
rustls-based TLS only.

#### Scenario: Dependency pulls in openssl-sys transitively
- **WHEN** a new crate is considered
- **THEN** check its feature flags for a `rustls` alternative before adding it
- **THEN** if the crate has no rustls path, find an alternative crate

---

### Requirement: Security advisories must be addressed or explicitly ignored

Yanked crates are denied. Known advisories MUST either be fixed or added to
the `ignore` list in `deny.toml` with a comment explaining why it is safe to ignore.
When a transitive dependency has an active RUSTSEC advisory with a patched version
available, a `Cargo.lock`-only bump via `cargo update --package <crate>` MUST be
used in preference to a full `Cargo.toml` version change, provided the direct
dependency's SemVer range already permits the patched version.

#### Scenario: cargo deny reports a new advisory
- **WHEN** `cargo deny check advisories` fails with a new advisory
- **THEN** either upgrade the affected crate or add an `ignore` entry with a justification comment

#### Scenario: Transitive dep advisory with compatible patch available
- **WHEN** `cargo deny check advisories` fails due to a transitive dependency
- **AND** the patched version is within the SemVer range of the direct dependency
- **THEN** run `cargo update --package <crate>` to bump only `Cargo.lock`
- **THEN** re-run `cargo deny check advisories` to confirm the advisory is cleared
- **THEN** commit `Cargo.lock` with a message referencing the RUSTSEC advisory IDs

#### Scenario: Transitive dep advisory without compatible patch
- **WHEN** the patched version would require a breaking SemVer change to a direct
  dependency
- **THEN** update the direct dependency in `Cargo.toml` and update `Cargo.lock`
- **THEN** confirm no duplicate-version violations are introduced

### Requirement: Build targets must be listed in deny.toml
The `[graph]` section of `deny.toml` SHALL list all supported build targets
so dependency evaluation is scoped correctly.

#### Scenario: Adding support for a new platform
- **WHEN** rbw gains support for a new OS or architecture
- **THEN** add the target triple to the `[graph] targets` list in `deny.toml`

---

### Requirement: MSRV changes must be intentional
The `rust-version` in `Cargo.toml` is `1.82.0`. Code MUST NOT use features
from a newer compiler without explicitly bumping this field.

#### Scenario: Using a stabilised language feature from a newer compiler
- **WHEN** using a feature that requires a newer Rust toolchain
- **THEN** verify the new MSRV is acceptable for all distribution targets
- **THEN** update `rust-version` in `Cargo.toml` in the same commit

