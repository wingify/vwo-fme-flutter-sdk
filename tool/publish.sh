#!/usr/bin/env bash
#
# Publishes one of the two packages built from this single source tree:
#   - vwo_fme_flutter_sdk      (the legacy/default manifest: pubspec.yaml + README.md)
#   - wingify_fme_flutter_sdk  (the rebrand manifest: pubspec.wingify.yaml + README_wingify.md)
#
# Usage:
#   tool/publish.sh vwo       [--version X.Y.Z] [--dry-run] [-- extra flutter pub publish args]
#   tool/publish.sh wingify   [--version X.Y.Z] [--dry-run] [-- extra flutter pub publish args]
#
# Dry run (--dry-run): validates the package with `flutter pub publish --dry-run`
# (no upload). Skips the interactive version prompt; version alignment is still
# checked. Exits with flutter's status (0 = validation passed, non-zero = failed).
#
# Version check (always runs before publish):
#   - Without --version: prompts to confirm the latest CHANGELOG version, then
#     requires an exact match in pubspec.yaml, pubspec.wingify.yaml, and
#     lib/utils/constants.dart (sdkVersion).
#   - With --version X.Y.Z: skips the prompt; all four must equal X.Y.Z exactly.
#
# The script temporarily swaps pubspec.yaml / README.md for the chosen brand,
# strips `publish_to: none` so the package can be published, runs
# `flutter pub publish`, then restores the working tree.
set -euo pipefail

readonly RED='\033[0;31m'
readonly NC='\033[0m'

err() {
  printf '%b%s%b\n' "$RED" "$*" "$NC" >&2
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

  echo "Version OK: $expected (CHANGELOG, pubspec.yaml, pubspec.wingify.yaml, constants.dart)"
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
else
  SRC_PUBSPEC="pubspec.yaml"
  SRC_README="README.md"
fi

# Back up the working manifest/readme and restore them on exit.
cp pubspec.yaml .pubspec.yaml.bak
cp README.md .README.md.bak
restore() {
  mv .pubspec.yaml.bak pubspec.yaml
  mv .README.md.bak README.md
}
trap restore EXIT

# Materialize the chosen brand's manifest/readme (sourced from the backups so
# reading and writing pubspec.yaml in-place is safe), dropping `publish_to`.
if [[ "$TARGET" == "vwo" ]]; then
  grep -v '^publish_to:' .pubspec.yaml.bak > pubspec.yaml
  cp .README.md.bak README.md
else
  grep -v '^publish_to:' "$SRC_PUBSPEC" > pubspec.yaml
  cp "$SRC_README" README.md
fi

PUBLISH_CMD=(flutter pub publish)
if [[ "$DRY_RUN" -eq 1 ]]; then
  echo "Dry run: validating \"$TARGET\" package (no upload)." >&2
  PUBLISH_CMD+=(--dry-run)
fi
if [[ ${#PUBLISH_ARGS[@]} -gt 0 ]]; then
  PUBLISH_CMD+=("${PUBLISH_ARGS[@]}")
fi
"${PUBLISH_CMD[@]}"
if [[ "$DRY_RUN" -eq 1 ]]; then
  echo "Dry run passed." >&2
fi
