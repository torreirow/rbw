## Purpose

Delta spec for the `error-handling` capability. Adds a concrete rule for the
agent's socket send path: a broken pipe when writing a response to a client that
has already disconnected MUST NOT panic the tokio task.

## MODIFIED Requirements

### Requirement: Never silently discard errors

Extends the existing requirement with a specific case for the agent's request
handler. When `handle_request` returns `Err` and the agent tries to send that
error back to the client, the client may have already closed the socket. In that
case the send itself fails with `Broken pipe (os error 32)`. This MUST be logged
as a warning, not unwrapped, so the agent remains alive and the log is meaningful.

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
