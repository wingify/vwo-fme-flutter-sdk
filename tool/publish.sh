#!/usr/bin/env bash
#
# Publishes one of the two packages built from this single source tree:
#   - vwo_fme_flutter_sdk      (pubspec.yaml + README.md + ios/vwo_fme_flutter_sdk.podspec)
#   - wingify_fme_flutter_sdk  (pubspec.wingify.yaml + README_wingify.md + ios/wingify_fme_flutter_sdk.podspec)
#
# Usage:
#   tool/publish.sh vwo       [--version X.Y.Z] [--dry-run] [-- extra flutter pub publish args]
#   tool/publish.sh wingify   [--version X.Y.Z] [--dry-run] [-- extra flutter pub publish args]
#
# CI (non-interactive, no upload prompt):
#   tool/publish.sh vwo --version 1.60.0 -- --force
#
# Dry run (--dry-run): `flutter pub publish --dry-run` (no upload). Skips the
# version prompt. Version alignment is still checked.
#
# Version check (always runs before publish):
#   - Without --version: prompts to confirm the latest CHANGELOG version, then
#     requires an exact match in pubspec.yaml, pubspec.wingify.yaml, and
#     lib/utils/constants.dart (sdkVersion).
#   - With --version X.Y.Z: skips the prompt; all four must equal X.Y.Z exactly.
#
# CocoaPods rejects an ios/ directory with two podspecs, so the other brand's
# podspec is moved aside (and listed in .pubignore) for the duration of the
# publish. pubspec.yaml / README.md are swapped and `publish_to: none` is
# stripped. Those edits are marked assume-unchanged so pub sees a clean git
# tree. Backups live outside the repo. Everything is restored on exit.
# tool/publish.sh itself is ignored by the clean-tree check.
set -euo pipefail

readonly RED='\033[0;31m'
readonly NC='\033[0m'
readonly RELEASE_IGNORED_PATH='tool/publish.sh'

GIT_ASSUME_UNCHANGED=()
BACKUP_DIR=""

log() {
  printf '[publish] %s\n' "$*" >&2
}

err() {
  printf '%b[publish] %s%b\n' "$RED" "$*" "$NC" >&2
}

git_assume_unchanged() {
  local path="$1"
  if git ls-files --error-unmatch "$path" &>/dev/null; then
    git update-index --assume-unchanged "$path"
    GIT_ASSUME_UNCHANGED+=("$path")
  fi
}

git_restore_assume_unchanged() {
  local path
  for path in "${GIT_ASSUME_UNCHANGED[@]}"; do
    git update-index --no-assume-unchanged "$path" 2>/dev/null || true
  done
  GIT_ASSUME_UNCHANGED=()
}

check_git_clean() {
  if ! git rev-parse --is-inside-work-tree &>/dev/null; then
    log "Not a git repository; skipping clean working tree check"
    return 0
  fi

  local dirty ignored
  dirty="$(git status --porcelain | grep -vE "(^|[[:space:]])${RELEASE_IGNORED_PATH//\//\\/}\$" || true)"
  ignored="$(git status --porcelain | grep -E "(^|[[:space:]])${RELEASE_IGNORED_PATH//\//\\/}\$" || true)"
  if [[ -n "$ignored" ]]; then
    log "Ignoring uncommitted changes to $RELEASE_IGNORED_PATH"
  fi
  if [[ -n "$dirty" ]]; then
    err "ERROR: Uncommitted changes detected. Commit or stash before publishing:"
    printf '%s\n' "$dirty" >&2
    err "Pub rejects a dirty git tree (excluding $RELEASE_IGNORED_PATH)."
    return 1
  fi
}

changelog_version() {
  sed -n 's/^## \[\([^]]*\)\].*/\1/p' CHANGELOG.md | head -1
}

changelog_latest_heading() {
  grep -m1 '^## \[' CHANGELOG.md || true
}

confirm_changelog_version() {
  local version="$1"
  local heading

  heading="$(changelog_latest_heading)"
  if [[ -z "$heading" ]]; then
    err "ERROR: Could not read a version from CHANGELOG.md (expected '## [X.Y.Z] - date')."
    return 1
  fi

  echo "" >&2
  echo "Latest CHANGELOG entry:" >&2
  echo "  $heading" >&2
  echo "" >&2
  if [[ "${DRY_RUN:-0}" -eq 1 ]]; then
    echo "This will dry-run publish package \"$TARGET\" at version $version." >&2
  else
    echo "This will publish package \"$TARGET\" at version $version." >&2
  fi
  echo "" >&2

  local answer=""
  if [[ -t 0 ]]; then
    read -r -p "Continue with this version? [y/N] " answer
  elif [[ -r /dev/tty ]] 2>/dev/null && read -r -p "Continue with this version? [y/N] " answer </dev/tty 2>/dev/null; then
    :
  else
    err "ERROR: No --version and not an interactive terminal."
    err "Pass --version $version to continue (e.g. --version $version)."
    return 1
  fi

  case "$answer" in
    [yY]|[yY][eE][sS]) return 0 ;;
    *)
      echo "Aborted."
      return 1
      ;;
  esac
}

pubspec_version() {
  sed -n 's/^version:[[:space:]]*//p' "$1" | head -1
}

constants_version() {
  sed -n 's/^const sdkVersion = "\([^"]*\)";/\1/p' lib/utils/constants.dart | head -1
}

check_versions() {
  local expected="$1"
  local changelog pubspec_vwo pubspec_wingify constants
  local failed=0

  changelog="$(changelog_version)"
  pubspec_vwo="$(pubspec_version pubspec.yaml)"
  pubspec_wingify="$(pubspec_version pubspec.wingify.yaml)"
  constants="$(constants_version)"

  if [[ -z "$changelog" ]]; then
    err "ERROR: Could not read a version from CHANGELOG.md (expected '## [X.Y.Z] - date')."
    failed=1
  elif [[ "$changelog" != "$expected" ]]; then
    err "ERROR: CHANGELOG.md has $changelog but expected $expected."
    failed=1
  fi

  if [[ -z "$pubspec_vwo" ]]; then
    err "ERROR: Could not read version from pubspec.yaml."
    failed=1
  elif [[ "$pubspec_vwo" != "$expected" ]]; then
    err "ERROR: pubspec.yaml has $pubspec_vwo but expected $expected."
    failed=1
  fi

  if [[ -z "$pubspec_wingify" ]]; then
    err "ERROR: Could not read version from pubspec.wingify.yaml."
    failed=1
  elif [[ "$pubspec_wingify" != "$expected" ]]; then
    err "ERROR: pubspec.wingify.yaml has $pubspec_wingify but expected $expected."
    failed=1
  fi

  if [[ -z "$constants" ]]; then
    err "ERROR: Could not read sdkVersion from lib/utils/constants.dart."
    failed=1
  elif [[ "$constants" != "$expected" ]]; then
    err "ERROR: lib/utils/constants.dart has $constants but expected $expected."
    failed=1
  fi

  if [[ "$failed" -ne 0 ]]; then
    err "Version mismatch. Align CHANGELOG.md, pubspec.yaml, pubspec.wingify.yaml, and lib/utils/constants.dart."
    return 1
  fi

  log "Version OK: $expected (CHANGELOG, pubspec.yaml, pubspec.wingify.yaml, constants.dart)"
}

TARGET="${1:-}"
if [[ "$TARGET" != "vwo" && "$TARGET" != "wingify" ]]; then
  echo "Usage: $0 [vwo|wingify] [--version X.Y.Z] [--dry-run] [-- extra flutter pub publish args]" >&2
  exit 1
fi
shift || true

CLI_VERSION=""
DRY_RUN=0
PUBLISH_ARGS=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --version)
      if [[ -z "${2:-}" ]]; then
        err "ERROR: --version requires a value (e.g. --version 1.50.0)."
        exit 1
      fi
      CLI_VERSION="$2"
      shift 2
      ;;
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    --)
      shift
      PUBLISH_ARGS=("$@")
      break
      ;;
    *)
      PUBLISH_ARGS+=("$1")
      shift
      ;;
  esac
done

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
log "Target package: $TARGET"

if ! check_git_clean; then
  exit 1
fi

if [[ -n "$CLI_VERSION" ]]; then
  EXPECTED="$CLI_VERSION"
else
  EXPECTED="$(changelog_version)"
  if [[ -z "$EXPECTED" ]]; then
    err "ERROR: Could not read a version from CHANGELOG.md (expected '## [X.Y.Z] - date')."
    exit 1
  fi
  if [[ "$DRY_RUN" -eq 0 ]] && ! confirm_changelog_version "$EXPECTED"; then
    exit 1
  fi
fi

if ! check_versions "$EXPECTED"; then
  exit 1
fi

if [[ "$TARGET" == "wingify" ]]; then
  SRC_PUBSPEC="pubspec.wingify.yaml"
  SRC_README="README_wingify.md"
  EXPECTED_NAME="wingify_fme_flutter_sdk"
  KEPT_PODSPEC="ios/wingify_fme_flutter_sdk.podspec"
  IOS_PODSPEC_EXCLUDE="ios/vwo_fme_flutter_sdk.podspec"
else
  SRC_PUBSPEC="pubspec.yaml"
  SRC_README="README.md"
  EXPECTED_NAME="vwo_fme_flutter_sdk"
  KEPT_PODSPEC="ios/vwo_fme_flutter_sdk.podspec"
  IOS_PODSPEC_EXCLUDE="ios/wingify_fme_flutter_sdk.podspec"
fi

# Backups stay outside the repo so pub does not pack them or see them as untracked.
BACKUP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/fme-flutter-publish.XXXXXX")"

restore() {
  if [[ -n "$BACKUP_DIR" && -d "$BACKUP_DIR" ]]; then
    if [[ -f "$BACKUP_DIR/pubspec.yaml" ]]; then
      cp "$BACKUP_DIR/pubspec.yaml" pubspec.yaml
    fi
    if [[ -f "$BACKUP_DIR/README.md" ]]; then
      cp "$BACKUP_DIR/README.md" README.md
    fi
    if [[ -f "$BACKUP_DIR/pubignore" ]]; then
      cp "$BACKUP_DIR/pubignore" .pubignore
    fi
    if [[ -n "${IOS_PODSPEC_EXCLUDE:-}" && -f "$BACKUP_DIR/excluded.podspec" && ! -e "$IOS_PODSPEC_EXCLUDE" ]]; then
      mv "$BACKUP_DIR/excluded.podspec" "$IOS_PODSPEC_EXCLUDE"
    fi
    rm -rf "$BACKUP_DIR"
    BACKUP_DIR=""
  fi
  if [[ ${#GIT_ASSUME_UNCHANGED[@]} -gt 0 ]]; then
    git_restore_assume_unchanged
  fi
}
trap restore EXIT

git_assume_unchanged pubspec.yaml
git_assume_unchanged README.md
git_assume_unchanged .pubignore
git_assume_unchanged "$RELEASE_IGNORED_PATH"
git_assume_unchanged "$IOS_PODSPEC_EXCLUDE"

cp pubspec.yaml "$BACKUP_DIR/pubspec.yaml"
cp README.md "$BACKUP_DIR/README.md"
cp .pubignore "$BACKUP_DIR/pubignore"

if ! grep -qxF "$IOS_PODSPEC_EXCLUDE" .pubignore; then
  printf '\n%s\n' "$IOS_PODSPEC_EXCLUDE" >> .pubignore
fi

if [[ -f "$IOS_PODSPEC_EXCLUDE" ]]; then
  mv "$IOS_PODSPEC_EXCLUDE" "$BACKUP_DIR/excluded.podspec"
fi

log "Publishing $EXPECTED_NAME (keeping $KEPT_PODSPEC, excluding $IOS_PODSPEC_EXCLUDE)"

if [[ "$TARGET" == "vwo" ]]; then
  grep -v '^publish_to:' "$BACKUP_DIR/pubspec.yaml" > pubspec.yaml
  cp "$BACKUP_DIR/README.md" README.md
else
  grep -v '^publish_to:' "$SRC_PUBSPEC" > pubspec.yaml
  cp "$SRC_README" README.md
fi

pubspec_name="$(sed -n 's/^name:[[:space:]]*//p' pubspec.yaml | head -1)"
if [[ "$pubspec_name" != "$EXPECTED_NAME" ]]; then
  err "ERROR: pubspec.yaml name is '$pubspec_name', expected '$EXPECTED_NAME'."
  exit 1
fi
if grep -q '^publish_to:' pubspec.yaml; then
  err "ERROR: publish_to is still set in pubspec.yaml."
  exit 1
fi
if [[ ! -f "$KEPT_PODSPEC" ]]; then
  err "ERROR: expected podspec $KEPT_PODSPEC is missing."
  exit 1
fi
if [[ -e "$IOS_PODSPEC_EXCLUDE" ]]; then
  err "ERROR: alternate podspec $IOS_PODSPEC_EXCLUDE is still in the tree."
  exit 1
fi

if git rev-parse --is-inside-work-tree &>/dev/null; then
  dirty="$(git status --porcelain | grep -vE "(^|[[:space:]])${RELEASE_IGNORED_PATH//\//\\/}\$" || true)"
  if [[ -n "$dirty" ]]; then
    err "ERROR: git tree is dirty after preparing the package:"
    printf '%s\n' "$dirty" >&2
    exit 1
  fi
fi

PUBLISH_CMD=(flutter pub publish)
if [[ "$DRY_RUN" -eq 1 ]]; then
  log "Dry run: validating \"$TARGET\" package (no upload)."
  PUBLISH_CMD+=(--dry-run)
fi
if [[ ${#PUBLISH_ARGS[@]} -gt 0 ]]; then
  PUBLISH_CMD+=("${PUBLISH_ARGS[@]}")
fi
log "Running: ${PUBLISH_CMD[*]}"
"${PUBLISH_CMD[@]}"
if [[ "$DRY_RUN" -eq 1 ]]; then
  log "Dry run passed."
fi
