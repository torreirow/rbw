## 1. API layer — server config endpoint (src/api.rs)

- [x] 1.1 Add `ServerConfig` struct with `#[serde(default)] server_name: Option<String>`,
  `server_url: Option<String>`, `version: Option<String>` (deserialize from
  `{"server": {"name": ..., "url": ...}, "version": ...}`)
- [x] 1.2 Add `pub fn server_config(&self) -> Result<ServerConfig>` method on
  `Client` that calls `GET {api_url}/config` via the blocking reqwest client and
  deserializes the response into `ServerConfig`

## 2. New subcommand in CLI (src/bin/rbw/main.rs)

- [x] 2.1 Add `Doctor` variant to the `Opt` enum with
  `#[command(about = "Check configuration and server connectivity")]`
- [x] 2.2 Add `Self::Doctor => "doctor".to_string()` to `subcommand_name()`
- [x] 2.3 Wire `Opt::Doctor => commands::doctor()` in the `main()` match block

## 3. Doctor command implementation (src/bin/rbw/commands.rs)

- [x] 3.1 Add `pub fn doctor() -> anyhow::Result<()>` — skeleton that prints the
  four section headers: `Configuration`, `Server`, `Agent`, `Vault`
- [x] 3.2 Configuration section: load `rbw::config::Config::load()` (or report
  missing), print email and resolved base URL with `✓`/`✗` prefix
- [x] 3.3 Server section: instantiate `rbw::api::Client` from config URLs,
  call `client.server_config()`; print reachable + server name/version, or
  print unreachable if the call errors (do not propagate the error)
- [x] 3.4 KDF section (part of Server output): if email is configured, call
  `client.prelogin(email)` and print KDF algorithm and parameters; skip silently
  if no email
- [x] 3.5 Agent section: attempt to connect to the agent socket via
  `crate::sock::connect()`; if successful send `Message::CheckLock` and print
  running + lock state; otherwise print not running
- [x] 3.6 Vault section: call `rbw::db::Db::load(server, email)` (using the
  config's server identifier and email); print entry count; print last-sync time
  from `std::fs::metadata(db_file).modified()`; print MFA token presence from
  `db.two_factor_token`; if the db file does not exist, print "not yet synced"

## 4. Build check

- [x] 4.1 Run `cargo check` — zero errors
- [x] 4.2 Run `cargo clippy --all-targets` — zero new warnings
