## Purpose

Delta spec for the `dependency-management` capability. Clarifies that
Cargo.lock-only patches are the preferred approach for transitive dependency
advisories and that `cargo deny check advisories` must pass in CI.

## MODIFIED Requirements

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
