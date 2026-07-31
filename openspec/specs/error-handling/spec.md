## Purpose
Error handling patterns in rbw. The project uses `anyhow` for error propagation
and `thiserror` for typed error definitions. These rules ensure consistent,
readable error messages throughout the codebase.
## Requirements
### Requirement: Use anyhow::Result for all fallible functions
All fallible functions MUST return `Result<T>` from `crate::prelude`
(which re-exports `anyhow::Result<T>`). Never use `Box<dyn Error>`.

#### Scenario: New fallible function
- **WHEN** writing a function that can fail
- **THEN** return `Result<T>` (from `crate::prelude::*`)
- **THEN** never use `unwrap()` or `expect()` except in truly unreachable paths — add a comment explaining why it is safe

---

### Requirement: Attach context to errors with .context() or .with_context()
All `?` propagations on external errors MUST attach a human-readable context string.

#### Scenario: File I/O or network call failure
- **WHEN** propagating an error from an I/O operation, API call, or parse
- **THEN** chain `.context("what we were trying to do")` before `?`
- **THEN** use `.with_context(|| format!("...{var}"))` when the message needs runtime data

#### Scenario: Error at entry point
- **WHEN** the top-level command handler propagates an error
- **THEN** use `.with_context(|| format!("rbw {subcommand_name}"))` as the final wrapper

---

### Requirement: Typed errors use thiserror
When a module needs structured, matchable error variants, they SHALL be defined
with `#[derive(thiserror::Error)]`.

#### Scenario: New error type
- **WHEN** defining a new error enum in `src/error.rs`
- **THEN** derive `#[derive(Debug, thiserror::Error)]`
- **THEN** give each variant a `#[error("...")]` message that is complete and user-readable
- **THEN** include source fields as `#[source]` or `#[from]` where appropriate

---

### Requirement: Never silently discard errors

Errors MUST be propagated, logged, or explicitly acknowledged with a comment.
Extends with a specific case for the agent's request handler: when
`handle_request` returns `Err` and the agent tries to send that error back to the
client, the client may have already closed the socket. In that case the send
itself fails with `Broken pipe (os error 32)`. This MUST be logged as a warning,
not unwrapped, so the agent remains alive and the log is meaningful.

#### Scenario: Spawned async task
- **WHEN** spawning a `tokio::spawn` task that can fail
- **THEN** either propagate the error via a channel or log it with `if let Err(e) = res { ... }`
- **THEN** never silently discard results with `let _ = future.await` unless the error is genuinely irrelevant

#### Scenario: Irrelevant error
- **WHEN** an error is truly ignorable (e.g. sending on a closed channel)
- **THEN** add a comment explaining why it is safe to ignore

#### Scenario: Client disconnects while agent is handling a request
- **WHEN** `handle_request` returns `Err` in a `tokio::spawn` task
- **AND** the client has already closed the socket before the agent sends the error
- **THEN** the `sock.send(...)` call returns `Err` (broken pipe)
- **THEN** the agent logs the send failure with `log::warn!` and exits the task cleanly
- **THEN** the agent process continues running and serves subsequent requests
- **THEN** the original handler error is NOT silently lost — it remains logged

#### Scenario: Client is still connected when agent sends an error response
- **WHEN** `handle_request` returns `Err` and the client socket is still open
- **THEN** the error response is sent normally to the client
- **THEN** behavior is unchanged from before this fix

### Requirement: Use ? consistently for error propagation
Error propagation SHALL use `?` with optional `.context()` — never manual
`match result { Ok(v) => v, Err(e) => return Err(e) }` patterns.

#### Scenario: Propagating a result
- **WHEN** a function receives a `Result` and needs to propagate failure
- **THEN** use `result?` or `result.context("...")?`
- **THEN** never manually match on `Err` just to re-return it unchanged

