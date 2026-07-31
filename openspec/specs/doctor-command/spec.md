# doctor-command Specification

## Purpose
Provides a single `rbw doctor` command that reports the health of the local rbw
configuration, server connectivity, and vault state so users can quickly diagnose
setup problems without manually inspecting config files or sockets.
## Requirements
### Requirement: Command is available without an unlocked vault
`rbw doctor` SHALL execute successfully and produce output even when the agent is
not running and the vault is not unlocked.

#### Scenario: Doctor runs with no agent
- **WHEN** the user runs `rbw doctor` and the rbw-agent is not running
- **THEN** the command prints all local and server checks it can perform and exits
  with code 0

### Requirement: Configuration section is reported
The output SHALL include a configuration section listing the configured email
address and the effective base URL.

#### Scenario: Email and URL present
- **WHEN** the user runs `rbw doctor` and a config file exists with an email and
  base URL
- **THEN** the output includes the email address and the resolved base URL

#### Scenario: Config missing
- **WHEN** the user runs `rbw doctor` and no config file is found
- **THEN** the output reports the configuration as missing and still runs any
  checks that do not depend on it

### Requirement: Server reachability is checked
The command SHALL attempt a network request to the API server and report whether
it is reachable.

#### Scenario: Server reachable
- **WHEN** the configured API server responds to `GET /api/config`
- **THEN** the output shows the server as reachable

#### Scenario: Server unreachable
- **WHEN** the configured API server cannot be reached within a reasonable timeout
- **THEN** the output shows the server as unreachable and continues with remaining
  local checks

### Requirement: Server identity is reported
When `GET /api/config` succeeds, the output SHALL include the server name and
version string returned by the server.

#### Scenario: Vaultwarden server
- **WHEN** the server returns `{"server": {"name": "Vaultwarden"}, "version": "1.32.0"}`
- **THEN** the output shows "Vaultwarden 1.32.0" (or equivalent formatted form)

#### Scenario: Official Bitwarden server
- **WHEN** the server returns `{"server": {"name": "Bitwarden"}, "version": "2024.1.0"}`
- **THEN** the output shows "Bitwarden 2024.1.0" (or equivalent formatted form)

#### Scenario: Server returns no version info
- **WHEN** `GET /api/config` succeeds but contains no version or server name
- **THEN** the output shows "unknown" for the missing fields and does not error

### Requirement: KDF settings are reported
When an email address is configured, the command SHALL call `POST
/accounts/prelogin` and report the key derivation function type and its
parameters.

#### Scenario: Argon2id KDF
- **WHEN** prelogin returns `kdf: Argon2id` with memory, iterations, and
  parallelism
- **THEN** the output shows "Argon2id" and all three parameters

#### Scenario: PBKDF2 KDF
- **WHEN** prelogin returns `kdf: Pbkdf2` with an iteration count
- **THEN** the output shows "PBKDF2" and the iteration count

#### Scenario: No email configured
- **WHEN** no email address is set in the config
- **THEN** the KDF section is skipped without error

### Requirement: Agent status is reported
The output SHALL indicate whether the rbw-agent is currently running.

#### Scenario: Agent running
- **WHEN** the Unix socket for the agent exists and is responsive
- **THEN** the output shows the agent as running

#### Scenario: Agent not running
- **WHEN** the agent socket does not exist or does not respond
- **THEN** the output shows the agent as not running

### Requirement: Vault state is reported when agent is running
When the agent is running, the command SHALL report whether the vault is unlocked,
the number of entries in the local database, and the approximate time of the last
sync.

#### Scenario: Vault unlocked
- **WHEN** the agent is running and the vault is unlocked
- **THEN** the output shows "unlocked" and the entry count

#### Scenario: Vault locked
- **WHEN** the agent is running and the vault is locked
- **THEN** the output shows "locked"

#### Scenario: Vault never synced
- **WHEN** no local database file exists
- **THEN** the output reports the vault as not yet synced

### Requirement: MFA remember token presence is reported
When a local database file exists, the output SHALL indicate whether an MFA
remember token is currently cached.

#### Scenario: Token cached
- **WHEN** `db.json` contains a non-null `two_factor_token`
- **THEN** the output shows that a remember token is present

#### Scenario: No token cached
- **WHEN** `db.json` contains a null or absent `two_factor_token`
- **THEN** the output shows that no remember token is cached

