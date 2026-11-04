---
# rbw-aoei
title: 'Merge PR #362: clear error when refresh token is rejected'
status: todo
type: bug
priority: normal
created_at: 2026-11-04T20:01:59Z
updated_at: 2026-11-04T20:01:59Z
parent: rbw-4nie
---

Upstream PR: https://github.com/doy/rbw/pull/362
Related: https://github.com/doy/rbw/issues/342, https://github.com/doy/rbw/issues/32

`exchange_refresh_token` / `exchange_refresh_token_async` parse the response
body unconditionally. When the identity server rejects the refresh token
(`{"error":"invalid_grant"}`, HTTP 400, e.g. after a master password change)
the user gets `failed to parse JSON: missing field access_token` instead of an
actionable message.

PR checks the status first and classifies the error via a
`classify_refresh_token_error` helper, consistent with `classify_login_error`.
+148 -5, 2 files. Check for conflicts with our `encryptedFor` changes in src/api.rs.
