## Context

See proposal.md — Why. Three fields are missing from the current code:
`twoFactorRemember` in the request, `TwoFactorToken` in the response, and
`two_factor_token` in `Db`. `TwoFactorProviderType::Remember = 5` already
exists in the enum but is never used.

The change is confined to the agent's login path. The IPC protocol and the
CLI (`rbw`) are untouched — the remember token is entirely an internal agent
concern.

## Goals / Non-Goals

**Goals:**
- Send `twoFactorRemember: true` with every user-entered MFA code
- Capture and persist `TwoFactorToken` from the server response
- Try the cached token automatically on next login; fall back silently on failure
- Maintain full backward compatibility with existing database files

**Non-Goals:**
- Configurable remember behaviour (always-on is the right default for rbw)
- Client-side expiry tracking (the server controls token lifetime)
- Any changes to the IPC protocol or CLI surface

## Decisions

### Token storage: Db, not Config

The remember token lives alongside `access_token` and `refresh_token` in
`db.json`. Storing it in `config.json` would make `rbw purge` leave a stale
token behind — purge is the user's explicit "clear everything" action.

`Db` already uses `#[serde(default)]` semantics so adding an
`Option<String>` field is backward-compatible with no migration needed.

### Always request remember — no opt-in

The official clients show a "Remember this device" checkbox. rbw is a
single-user tool always on the same machine with the same persistent
`device_id`. An opt-out would require a config key, docs, and extra code
paths with no real benefit. Always requesting is strictly better UX for
every practical rbw user.

### Silent fallback on token rejection

When the server rejects the remember token it returns `TwoFactorRequired` —
the same error it returns when no MFA has been provided at all. The handling
is: clear the stale token, proceed to pinentry. No new error variant is
needed; no message is shown to the user.

### login() return type change: add Option<String>

`rbw::actions::login()` currently returns
`(access_token, refresh_token, kdf, …)`. Adding `Option<String>` for the
remember token is the minimal change; all call sites in `rbw-agent/actions.rs`
already destructure the tuple, so each one needs one additional binding.

**Alternative considered:** pass a mutable `Option<String>` out-parameter.
Rejected — Rust idiom strongly prefers returning values over out-params; a
wider tuple is cleaner.

## Data flow

```
rbw login (IPC Action::Login)
        │
        ▼
rbw-agent/actions.rs: login()
        │
        ├─ load db.two_factor_token
        │
        ├─[Some(token)]──────────────────────────────────────────────────┐
        │                                                                 │
        │  rbw::actions::login(                                           │
        │    two_factor_token = Some(token),                              │
        │    two_factor_provider = Some(Remember)                         │
        │  )                                                              │
        │      │                                                          │
        │      ├─[Ok]──► login_success()  ← no pinentry, done            │
        │      │                                                          │
        │      └─[TwoFactorRequired]                                      │
        │           clear db.two_factor_token                             │
        │           fall through ────────────────────────────────────────┘
        │
        └─[None / fallthrough]
             ask pinentry for MFA code (existing flow)
                  │
                  ▼
             rbw::actions::login(
               two_factor_token = Some(code),
               two_factor_provider = Some(provider),
               twoFactorRemember = true             ← NEW
             )
                  │
                  ▼
             (access_token, refresh_token, …, mfa_remember_token)  ← NEW field
                  │
                  ▼
             login_success() — saves mfa_remember_token to db       ← NEW
```

## Risks / Trade-offs

- **Token lives in plaintext in db.json** → Mitigation: db.json already
  contains `access_token` and `refresh_token` in plaintext; the security
  posture is unchanged. File permissions on `~/.local/share/rbw/` are set by
  existing directory-creation code.

- **Clippy: wider tuple return from `login()`** → `too_many_arguments` and
  `type_complexity` are globally allowed; adding one `Option<String>` to a
  tuple return does not introduce new warnings.

- **Vaultwarden / self-hosted servers** → The `twoFactorRemember` field is
  part of the standard Bitwarden identity API. Servers that do not support it
  simply ignore the field and return no `TwoFactorToken`; the `Option<String>`
  response field handles this gracefully.

## Migration Plan

No database migration required — `two_factor_token` is `Option<String>` with
serde `default`, so existing `db.json` files deserialise to `None`.

No IPC protocol version bump — the change is entirely within the agent.

Deploy: ship as a normal release. Users with existing databases will
transparently gain the remember behaviour on their next `rbw login`.
