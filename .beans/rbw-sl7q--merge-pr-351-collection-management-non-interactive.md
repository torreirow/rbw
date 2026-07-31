---
# rbw-sl7q
title: 'Merge PR #351: collection management + non-interactive (headless) unlock'
status: todo
type: feature
priority: normal
created_at: 2026-07-31T09:02:22Z
updated_at: 2026-07-31T09:02:22Z
parent: rbw-hu03
---

Upstream PR: https://github.com/doy/rbw/pull/351

Two features in one PR:
1. Organization collection management commands (list, assign, etc.)
2. Non-interactive unlock — agent can run headless without pinentry prompt
   (useful for servers, cron jobs, CI environments)

Large PR, touches core auth path. Review carefully before merging.
