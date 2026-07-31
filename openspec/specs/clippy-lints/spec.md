## Purpose
Clippy lint configuration for rbw. The project enables `pedantic`, `nursery`,
and `cargo` lint groups with selective allows for intentional patterns.
All code MUST pass `cargo clippy --all-targets` before merging.

## Requirements

### Requirement: All enabled Clippy lints must pass
New code MUST NOT introduce new Clippy warnings in the `pedantic`, `nursery`,
or `cargo` lint groups.

#### Scenario: New module or function
- **WHEN** adding new code
- **THEN** run `cargo clippy --all-targets` and resolve all warnings before committing
- **THEN** never use `#[allow(clippy::...)]` at the call site to silence a lint without a comment

---

### Requirement: Globally allowed lints must not be re-suppressed locally
Lints that are already globally allowed in `Cargo.toml` SHALL NOT be suppressed
again with per-item `#[allow(...)]` attributes.

#### Scenario: Encountering a lint from the allowed list
- **WHEN** Clippy warns on `cognitive_complexity`, `similar_names`, `too_many_arguments`,
  `too_many_lines`, `type_complexity`, `multiple_crate_versions`, `large_enum_variant`,
  `must_use_candidate`, `missing_errors_doc`, `missing_panics_doc`,
  `significant_drop_tightening`, or `struct_field_names`
- **THEN** these are already globally allowed — no per-site `#[allow]` is needed

---

### Requirement: Unanticipated lint warnings must be fixed, not suppressed
If a new warning appears from a lint not in the globally-allowed list,
the code MUST be changed to satisfy the lint.

#### Scenario: New warning from an unanticipated lint
- **WHEN** a Clippy lint fires that is not in the globally-allowed list
- **THEN** fix the code rather than adding a new `#[allow(clippy::...)]`
- **THEN** if suppression is genuinely necessary, add it to `Cargo.toml` with a comment

---

### Requirement: as numeric casts are forbidden
The `as_conversions` lint is enabled as a warning. Numeric `as` casts MUST NOT
be used; use lossless conversion functions instead.

#### Scenario: Numeric conversion
- **WHEN** converting between numeric types
- **THEN** use `.try_into()`, `u32::from()`, `usize::from()`, or similar lossless conversions
- **THEN** never use `value as usize` or similar truncating casts

---

### Requirement: Bare .unwrap() calls are forbidden
The `get_unwrap` lint is enabled. `.unwrap()` calls MUST NOT appear without
an `expect("reason")` that explains why the invariant holds.

#### Scenario: Unwrapping an Option or Result
- **WHEN** an `Option` or `Result` must be unwrapped
- **THEN** use `expect("reason this is safe")` for known-safe invariants, or propagate with `?`
- **THEN** never use bare `.unwrap()` without a comment
