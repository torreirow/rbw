---
# rbw-okfw
title: 'Merge PR #328: fix ''rbw edit'' failure due to missing Bitwarden-Client-Version header'
status: done
type: bug
priority: high
created_at: 2026-07-31T09:01:50Z
updated_at: 2026-07-31T11:10:59Z
parent: rbw-k7r3
---

Upstream PR: https://github.com/doy/rbw/pull/328

`rbw edit` fails with: Cannot edit item. Update to the latest version of Bitwarden.

Root cause: cipher update request used a separate blocking client that did not set
the Bitwarden-Client-Version header consistently across all request paths.

Direct user-facing bug, small patch.
