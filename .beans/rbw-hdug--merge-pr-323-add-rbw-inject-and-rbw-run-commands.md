---
# rbw-hdug
title: 'Merge PR #323: add ''rbw inject'' and ''rbw run'' commands'
status: todo
type: feature
priority: normal
created_at: 2026-07-31T09:02:16Z
updated_at: 2026-07-31T09:02:16Z
parent: rbw-hu03
---

Upstream PR: https://github.com/doy/rbw/pull/323

1Password-style secret injection:
- `rbw inject < template.yaml` — substitutes `{{ op://vault/item/field }}` style refs
- `rbw run -- my-script` — runs a command with secrets injected as env vars

Useful for scripts, CI pipelines, docker-compose, etc.
Evaluate scope and security surface before merging.
