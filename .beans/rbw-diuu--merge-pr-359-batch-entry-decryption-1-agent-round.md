---
# rbw-diuu
title: 'Merge PR #359: batch entry decryption (1 agent round-trip instead of N)'
status: todo
type: feature
priority: high
created_at: 2026-07-31T09:02:09Z
updated_at: 2026-07-31T09:02:09Z
parent: rbw-4nie
---

Upstream PR: https://github.com/doy/rbw/pull/359

Currently each vault entry decrypt is a separate IPC socket round-trip.
With 100 entries: 100 connections. With 500 entries: 500 connections.

This PR batches all decryptions into a single round-trip — significant speedup
for large vaults. Noticeable on every `rbw get`, `rbw list`, `rbw ls`.
