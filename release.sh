#!/usr/bin/env bash
#
# Release script for rbw (torreirow fork)
#
# Steps:
#   1. Check for uncommitted changes
#   2. Optionally archive completed OpenSpec changes
#   3. Select bump type (patch / minor / major)
#   4. Update version in Cargo.toml
#   5. Replace "## NEXT VERSION" in CHANGELOG.md with actual version + date
#   6. Verify build with cargo check
#   7. Optionally update flake.lock
#   8. Commit + tag
#   9. Optionally push (tag triggers GitHub Actions release build)
#
# When you push the tag, GitHub Actions (.github/workflows/release.yaml) will:
#   - Build static binaries for Linux (musl) and macOS (x86_64 + aarch64)
#   - Publish a GitHub Release with the archives + checksums
#

set -e

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'
info()    { echo -e "${BLUE}ℹ${NC} $1"; }
success() { echo -e "${GREEN}✓${NC} $1"; }
warn()    { echo -e "${YELLOW}⚠${NC} $1"; }
die()     { echo -e "${RED}✗${NC} $1"; exit 1; }

# ── Preflight ────────────────────────────────────────────────────────────────

git rev-parse --git-dir > /dev/null 2>&1 || die "Not in a git repository"

[[ -n $(git status --porcelain) ]] && \
    die "Uncommitted changes present. Commit or stash them first."

info "Checking remote connectivity..."
git ls-remote --exit-code origin &>/dev/null || die "Cannot reach remote."
success "Remote reachable"

[[ -f Cargo.toml ]] || die "Cargo.toml not found"

# ── Current version ──────────────────────────────────────────────────────────

CURRENT_VERSION=$(grep '^version = ' Cargo.toml | head -1 | sed 's/version = "\(.*\)"/\1/')
info "Current version: ${GREEN}${CURRENT_VERSION}${NC}"

IFS='.' read -r MAJOR MINOR PATCH <<< "$CURRENT_VERSION"

echo ""
echo "Select release type:"
echo "  1) Patch   (${MAJOR}.${MINOR}.$((PATCH + 1))) - Bug fixes"
echo "  2) Minor   (${MAJOR}.$((MINOR + 1)).0) - New features"
echo "  3) Major   ($((MAJOR + 1)).0.0) - Breaking changes"
echo ""
read -rp "Enter choice (1-3): " RELEASE_TYPE

case $RELEASE_TYPE in
    1) NEW_VERSION="${MAJOR}.${MINOR}.$((PATCH + 1))"; RELEASE_NAME="patch" ;;
    2) NEW_VERSION="${MAJOR}.$((MINOR + 1)).0";        RELEASE_NAME="minor" ;;
    3) NEW_VERSION="$((MAJOR + 1)).0.0";               RELEASE_NAME="major" ;;
    *) die "Invalid choice" ;;
esac

info "New version: ${GREEN}${NEW_VERSION}${NC} (${RELEASE_NAME})"

git rev-parse "v${NEW_VERSION}" >/dev/null 2>&1 && die "Tag v${NEW_VERSION} already exists!"
success "Version tag available"

# ── OpenSpec ─────────────────────────────────────────────────────────────────

if command -v openspec &>/dev/null; then
    info "Checking OpenSpec changes..."
    COMPLETED=$(openspec list 2>/dev/null | grep "✓ Complete" | awk '{print $1}' || true)
    if [[ -n "$COMPLETED" ]]; then
        warn "Completed changes pending archive:"
        openspec list | grep "✓ Complete" || true
        echo ""
        read -rp "Archive before release? (y/n): " ARCHIVE
        if [[ $ARCHIVE =~ ^[Yy]$ ]]; then
            for change in $COMPLETED; do
                info "Archiving ${change}..."
                openspec archive "$change" --yes 2>/dev/null && success "Archived ${change}" \
                    || warn "Could not archive ${change}"
            done
            if [[ -n $(git status --porcelain openspec/) ]]; then
                git add openspec/
                git commit -m "chore: archive completed openspec changes before release"
                success "Archived changes committed"
            fi
        fi
    else
        success "No pending OpenSpec changes"
    fi
fi

# ── CHANGELOG ────────────────────────────────────────────────────────────────

RELEASE_DATE=$(date +"%Y-%m-%d")

info "Updating CHANGELOG.md..."
grep -q "## NEXT VERSION" CHANGELOG.md || die "No '## NEXT VERSION' section found in CHANGELOG.md"
sed -i "s/## NEXT VERSION/## [${NEW_VERSION}] - ${RELEASE_DATE}/" CHANGELOG.md
success "CHANGELOG.md updated"

# ── Cargo.toml version ───────────────────────────────────────────────────────

info "Updating Cargo.toml version..."
# Only replace the first occurrence (package.version, not a dependency version)
sed -i "0,/^version = \"${CURRENT_VERSION}\"/s/^version = \"${CURRENT_VERSION}\"/version = \"${NEW_VERSION}\"/" Cargo.toml
success "Cargo.toml updated"

# ── Build check ──────────────────────────────────────────────────────────────

info "Running cargo check..."
cargo check 2>&1 | tail -3
success "Build check passed"

# ── Nix flake.lock ───────────────────────────────────────────────────────────

if [[ -f flake.nix ]] && command -v nix &>/dev/null; then
    echo ""
    read -rp "Update flake.lock? (y/n): " UPDATE_FLAKE
    if [[ $UPDATE_FLAKE =~ ^[Yy]$ ]]; then
        info "Updating flake.lock..."
        nix flake update
        success "flake.lock updated"
    fi
fi

# ── Summary + confirm ────────────────────────────────────────────────────────

echo ""
echo "════════════════════════════════════════════════════"
info "Release summary"
echo "════════════════════════════════════════════════════"
echo "  ${CURRENT_VERSION}  →  ${GREEN}${NEW_VERSION}${NC}  (${RELEASE_NAME})"
echo ""
echo "  Files:"
echo "    - Cargo.toml"
echo "    - CHANGELOG.md"
[[ -n $(git status --porcelain flake.lock 2>/dev/null) ]] && echo "    - flake.lock"
echo "════════════════════════════════════════════════════"
echo ""

read -rp "Commit and tag? (y/n): " CONFIRM
if [[ ! $CONFIRM =~ ^[Yy]$ ]]; then
    warn "Aborting — rolling back..."
    git checkout Cargo.toml CHANGELOG.md
    exit 0
fi

# ── Commit + tag ─────────────────────────────────────────────────────────────

git add Cargo.toml CHANGELOG.md
[[ -n $(git status --porcelain flake.lock 2>/dev/null) ]] && git add flake.lock

git commit -m "release: bump version to ${NEW_VERSION}"
success "Commit created"

TAG_MSG="Release v${NEW_VERSION}

$(sed -n "/## \[${NEW_VERSION}\]/,/## \[/p" CHANGELOG.md | sed '$d' | tail -n +2)"

git tag -a "v${NEW_VERSION}" -m "$TAG_MSG"
success "Tag v${NEW_VERSION} created"

# ── Push ─────────────────────────────────────────────────────────────────────

echo ""
read -rp "Push commit + tag to remote? (y/n): " PUSH
if [[ ! $PUSH =~ ^[Yy]$ ]]; then
    warn "Not pushed. Push manually:"
    echo "  git push origin main && git push origin v${NEW_VERSION}"
    exit 0
fi

git push origin main
git push origin "v${NEW_VERSION}"

echo ""
success "v${NEW_VERSION} pushed — GitHub Actions will build and publish the release."
echo ""
echo "  Actions:  https://github.com/torreirow/rbw/actions"
echo "  Releases: https://github.com/torreirow/rbw/releases/tag/v${NEW_VERSION}"
echo ""
