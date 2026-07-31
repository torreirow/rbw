## Purpose
Formatting and structural style rules for rbw. Enforced by rustfmt (`.rustfmt.toml`)
and Clippy. All code MUST pass `cargo fmt --check` and `cargo clippy` before merging.

## Requirements

### Requirement: Max line width is 78 characters
All lines MUST fit within 78 characters as configured in `.rustfmt.toml`
(`max_width = 78`, `edition = "2021"`).

#### Scenario: Long function signature or call chain
- **WHEN** a line exceeds 78 characters
- **THEN** break it across multiple lines using rustfmt's style (trailing commas, aligned args)
- **THEN** never manually wrap lines — let `cargo fmt` handle it

---

### Requirement: Rust 2021 edition idioms
Code MUST use Rust 2021 edition features and idioms where appropriate.

#### Scenario: Imports
- **WHEN** writing use statements
- **THEN** use edition-2021 import syntax (no `extern crate`, no `macro_use`)

#### Scenario: Closures over async blocks
- **WHEN** capturing variables in async closures
- **THEN** use `move` and edition-2021 closure capture semantics

---

### Requirement: Trailing commas in multi-line constructs
Multi-line function calls, struct literals, match arms, and macro invocations
MUST use trailing commas (enforced by rustfmt).

#### Scenario: Multi-line function call
- **WHEN** a function call is broken across lines
- **THEN** the last argument has a trailing comma

---

### Requirement: Imports are explicit and fully qualified at the use-site
All traits used from external crates SHALL be imported via `use`.
Glob imports (`use foo::*`) are only allowed in `prelude.rs` and test modules.

#### Scenario: Using a trait method
- **WHEN** calling a trait method (e.g. `Context::context`, `Write::write`)
- **THEN** import the trait with `use anyhow::Context as _` or `use std::io::Write as _`
- **THEN** never rely on implicit trait imports

#### Scenario: Prelude
- **WHEN** adding to `src/prelude.rs`
- **THEN** only add items used in almost every file (currently `Result`, `Error`)

---

### Requirement: No unnecessary pub visibility
Items MUST only be `pub` if they are part of a public API surface or required
by another module. Internal helpers use module-private or `pub(crate)`.

#### Scenario: Internal helper function
- **WHEN** writing a function only used within its own module
- **THEN** omit `pub`

#### Scenario: Cross-module items
- **WHEN** a function or type is needed by a sibling module but not the external API
- **THEN** use `pub(crate)` rather than `pub`

---

### Requirement: No commented-out code in committed files
Dead code MUST be removed, not commented out.

#### Scenario: Removing a function
- **WHEN** a function is no longer needed
- **THEN** delete it entirely — do not leave `// fn old_thing() { ... }`

---

### Requirement: Temporary code markers must reference a tracking issue
Any `// TODO` or `// XXX` comment SHALL reference a GitHub issue or include
an explanation of the known limitation inline.

#### Scenario: Known limitation or workaround
- **WHEN** leaving a `// TODO` or `// XXX` comment
- **THEN** either link to a GitHub issue or include an explanation of the limitation
