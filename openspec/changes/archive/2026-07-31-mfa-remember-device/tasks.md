## 1. API layer — request and response structs (src/api.rs)

- [x] 1.1 Add `#[serde(rename = "twoFactorRemember")] two_factor_remember: bool` field to `ConnectTokenReq`
- [x] 1.2 Add `#[serde(rename = "TwoFactorToken", default)] two_factor_token: Option<String>` field to `ConnectTokenRes`
- [x] 1.3 Update both `ConnectTokenReq` construction sites in `login()` (password flow and SSO flow) to set `two_factor_remember: two_factor_token.is_some()` — true when the user supplied an MFA code, false otherwise
- [x] 1.4 Update `login()` return type from `(String, String, String)` to `(String, String, String, Option<String>)` and include `connect_res.two_factor_token` as the fourth element

## 2. Database schema (src/db.rs)

- [x] 2.1 Add `#[serde(default)] pub two_factor_token: Option<String>` to the `Db` struct

## 3. Actions bridge (src/actions.rs)

- [x] 3.1 Update `login()` return type to `(String, String, KdfType, u32, Option<u32>, Option<u32>, String, Option<String>)` to thread the remember token through to the caller
- [x] 3.2 Destructure the new fourth element from the `api.login()` call and include it in the return value

## 4. Agent login flow (src/bin/rbw-agent/actions.rs)

- [x] 4.1 In `login()`: before the pinentry attempt loop, read `db.two_factor_token`; if `Some`, call `rbw::actions::login()` with `two_factor_token = Some(token)` and `two_factor_provider = Some(TwoFactorProviderType::Remember)`
- [x] 4.2 If that call succeeds, pass the result to `login_success()` (including the new remember token) and return early — no pinentry needed
- [x] 4.3 If that call returns `TwoFactorRequired`, clear `db.two_factor_token` (set to `None`) and fall through to the existing pinentry loop
- [x] 4.4 In the existing pinentry success path inside `two_factor()`: update the return type to include `Option<String>` for the new remember token from `rbw::actions::login()`
- [x] 4.5 Update `login_success()` signature to accept `mfa_remember_token: Option<String>` and save it to `db.two_factor_token` before calling `save_db()`
- [x] 4.6 Update all three `login_success()` call sites to pass the new argument (initial login path, two-factor success path, and remember-token success path)

## 5. Build check

- [x] 5.1 Run `cargo check --target x86_64-unknown-linux-musl` — zero errors
- [x] 5.2 Run `cargo clippy --all-targets --target x86_64-unknown-linux-musl` — zero new warnings
