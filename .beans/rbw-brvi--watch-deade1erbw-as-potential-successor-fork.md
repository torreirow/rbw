---
# rbw-brvi
title: Watch deade1e/rbw as potential successor fork
status: todo
type: task
priority: low
created_at: 2026-11-04T20:12:12Z
updated_at: 2026-11-04T20:12:12Z
---

Analysis of 2026-11-04 on which fork to follow now that doy/rbw is dormant
(last upstream commit 2025-12-31, see https://github.com/doy/rbw/issues/338).
Decision: **keep our own fork and cherry-pick selectively.** Revisit deade1e
when the triggers below are met.

## deade1e/rbw (https://github.com/deade1e/rbw), the one to watch

- Only fork whose maintainer says they intend to maintain it long-term (#338,
  2026-09-28). m11y offered to port its work onto it.
- Near-rewrite: 46 files, +7687/-8805; `api.rs` split into `api/{mod,client}.rs`,
  typed `Entry<Encrypted/Decrypted>` structs.
- Branch `fix/disable_field_oracle` (deade1e#2): the agent no longer decrypts
  arbitrary strings; the protocol becomes Get/Search/Code/Add/Edit/Remove/History.
  This is the most promising security design long-term, but it breaks the
  client-agent protocol. The author says it "has some small bugs for sure".
- As of 2026-11-04: no commits since 2026-06-28; open issues and PRs unanswered;
  still has the #364 item-key corruption bug; old lockfile (missing the
  RUSTSEC patches we have); `flake.nix` is a placeholder (`hello` package).
- Switching cost: very high. Every file we touch is restructured, so MFA
  remember-device, `rbw doctor`, encryptedFor, the item-key/reprompt fixes and
  the tier-1 patches would have to be re-implemented, not rebased.

**Revisit when:** deade1e#2 is merged, the item-key fix (#364) is in, commits
resume, and it releases with up-to-date dependencies.

## Other forks considered

- **m11y** (no own fork, PR branches on doy only): careful work, e.g. #371
  (cipher write safety, lastKnownRevisionDate) and #373. Good cherry-pick source.
- **rylos/rbw** (`enhanced` branch, AUR `rbw-enhanced`): very active, has fixes for
  #364/#377/#378/encryptedFor and a Vaultwarden e2e script, but it is a
  single-author fork with no CI, adds ~14k lines (TUI, biometric and auto-unlock
  that stores the master password), and looks heavily AI-assisted. Good place
  to look for individual fixes, e.g. 897b17a (#377); don't adopt it wholesale.
- **pschmitt/rbw**: calls itself a "vibe-coded rbw fork". Ignore.

## Still worth cherry-picking

- #378 rotated refresh tokens (rbw-o4p0). Vaultwarden refresh tokens expire after
  30 days.
- #362 refresh token error message (rbw-aoei).
- m11y #371: `lastKnownRevisionDate` conflict detection (not yet done).
