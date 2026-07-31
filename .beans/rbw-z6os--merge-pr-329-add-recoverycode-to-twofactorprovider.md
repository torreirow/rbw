---
# rbw-z6os
title: 'Merge PR #329: add RecoveryCode to TwoFactorProviderType'
status: todo
type: task
priority: high
created_at: 2026-07-31T09:01:56Z
updated_at: 2026-07-31T09:01:56Z
parent: rbw-4nie
---

Upstream PR: https://github.com/doy/rbw/pull/329

Fixes login on new Vaultwarden installations that send RecoveryCode as a 2FA provider type.
Without this, login fails entirely on fresh Vaultwarden setups.

Directly related to our mfa-remember-device feature.
