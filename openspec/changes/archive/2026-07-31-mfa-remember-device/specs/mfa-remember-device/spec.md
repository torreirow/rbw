## Purpose

Allows the rbw agent to skip the MFA pinentry prompt on repeated logins by
caching a server-issued "remember this device" token in the local vault
database, using it transparently until the server revokes or expires it.

## ADDED Requirements

### Requirement: Remember token is requested on every MFA login
When the user successfully authenticates with an MFA code, rbw MUST request
a remember token from the server by including `twoFactorRemember: true` in
the login request.

#### Scenario: Successful MFA login with authenticator app
- **WHEN** the user enters a valid TOTP code during `rbw login`
- **THEN** the login request includes `twoFactorRemember: true`
- **THEN** the server's `TwoFactorToken` from the response is persisted to the local database

#### Scenario: Successful MFA login with Yubikey
- **WHEN** the user completes a Yubikey challenge during `rbw login`
- **THEN** the login request includes `twoFactorRemember: true`
- **THEN** the returned `TwoFactorToken` is persisted to the local database

#### Scenario: Successful MFA login with email code
- **WHEN** the user enters a valid email OTP during `rbw login`
- **THEN** the login request includes `twoFactorRemember: true`
- **THEN** the returned `TwoFactorToken` is persisted to the local database

---

### Requirement: Stored remember token is used automatically on subsequent logins
If a remember token is present in the database, rbw MUST attempt to use it
before prompting the user for an MFA code.

#### Scenario: Login with a valid cached remember token
- **WHEN** `rbw login` is called and a `two_factor_token` exists in the database
- **THEN** the login request uses that token with `twoFactorProvider: Remember (5)`
- **THEN** the MFA pinentry prompt is NOT shown to the user
- **THEN** login completes successfully

#### Scenario: Login without a cached remember token
- **WHEN** `rbw login` is called and no `two_factor_token` is in the database
- **THEN** the normal MFA flow applies (server challenges, user is prompted via pinentry)

---

### Requirement: Expired or rejected remember token triggers transparent fallback
If the server rejects the cached remember token, rbw MUST fall back to the
normal MFA prompt without surfacing an error to the user.

#### Scenario: Cached token has expired (server returns TwoFactorRequired)
- **WHEN** the server responds with `TwoFactorRequired` after rbw sends the remember token
- **THEN** rbw clears the stale token from the database
- **THEN** rbw prompts the user for a fresh MFA code via pinentry
- **THEN** on success, the new `TwoFactorToken` is persisted to the database
- **THEN** no error is shown to the user about the expired token

---

### Requirement: Remember token is cleared on purge
The remember token MUST be removed when the local vault is purged.

#### Scenario: User runs rbw purge
- **WHEN** the user runs `rbw purge`
- **THEN** the entire local database (including `two_factor_token`) is deleted
- **THEN** the next `rbw login` requires a fresh MFA code

---

### Requirement: Existing databases without a remember token continue to work
The schema change to `Db` MUST be backward-compatible.

#### Scenario: Database file predates this feature
- **WHEN** rbw loads a database that has no `two_factor_token` field
- **THEN** the field defaults to `None` and no error occurs
- **THEN** the login flow proceeds as before (no remember token available)
