## Purpose
Rust naming conventions for all identifiers in rbw. These follow Rust RFC 430
and the Rust API Guidelines, enforced by Clippy where possible.

## Requirements

### Requirement: Types use UpperCamelCase
All type-level items (structs, enums, enum variants, traits, type aliases)
MUST use `UpperCamelCase`.

#### Scenario: New struct or enum
- **WHEN** adding a new struct, enum, or trait
- **THEN** the name is `UpperCamelCase` (e.g. `CipherString`, `ApiClient`, `LockTimeout`)

#### Scenario: Enum variants
- **WHEN** defining enum variants
- **THEN** each variant is `UpperCamelCase` (e.g. `Action::CheckLock`, `Response::Ack`)

---

### Requirement: Functions, methods, variables, and modules use snake_case
All value-level bindings and module names MUST use `snake_case`.

#### Scenario: New function or method
- **WHEN** adding a function, method, or closure binding
- **THEN** the name is `snake_case` (e.g. `load_config`, `send_request`, `handle_timeout`)

#### Scenario: Local variables and parameters
- **WHEN** declaring variables or function parameters
- **THEN** they are `snake_case` (e.g. `entry_key`, `org_id`, `base_url`)

#### Scenario: Module files
- **WHEN** creating a new module file
- **THEN** the filename is `snake_case` (e.g. `ssh_agent.rs`, `cipher_string.rs`)

---

### Requirement: Constants and statics use SCREAMING_SNAKE_CASE
Top-level `const` and `static` items MUST use `SCREAMING_SNAKE_CASE`.

#### Scenario: Compile-time constant
- **WHEN** declaring a `const` at module level
- **THEN** the name is `SCREAMING_SNAKE_CASE` (e.g. `VERSION`, `ENVIRONMENT_VARIABLES`)

#### Scenario: Static variable
- **WHEN** declaring a `static` or `static LazyLock`
- **THEN** the name is `SCREAMING_SNAKE_CASE` (e.g. `ENVIRONMENT_VARIABLES_OS`)

---

### Requirement: Generic type parameters use single uppercase letters or short UpperCamelCase
Generic parameters MUST use `T`, `E`, `K`, `V` for single letters, or short
descriptive `UpperCamelCase` — never lowercase or snake_case.

#### Scenario: Generic parameter in a function or struct
- **WHEN** introducing a generic type parameter
- **THEN** use a single uppercase letter (`T`, `E`, `S`) or descriptive short name (`Key`, `Val`)
- **THEN** never use lowercase or snake_case for generics

---

### Requirement: Lifetime parameters use short lowercase names
Lifetime parameters SHALL use `'a`, `'b`, or a short descriptive name.
For serde `Deserialize`, use the conventional `'de`.

#### Scenario: Serde Deserialize lifetime
- **WHEN** implementing `Deserialize` with a lifetime
- **THEN** use `'de` per serde convention

---

### Requirement: Acronyms in names are treated as words
Multi-letter acronyms in `UpperCamelCase` names MUST be written as capitalised
words, not all-caps.

#### Scenario: Acronym in a type name
- **WHEN** a name contains an acronym (URL, ID, API, SSH, TOTP, IPC)
- **THEN** write it as `Url`, `Id`, `Api`, `Ssh`, `Totp`, `Ipc` within a CamelCase name
- **THEN** NEVER write `parseURL` or `SSHAgent` — use `parse_url` / `SshAgent`
- **NOTE** exception: `const`/`static` keep the full acronym in SCREAMING_SNAKE_CASE (e.g. `SSH_AUTH_SOCK`)
