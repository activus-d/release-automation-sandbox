#!/usr/bin/env bash
# Resolve the channel, version, and source commit for a release run.
# Writes key=value lines to $GITHUB_OUTPUT and a summary to $GITHUB_STEP_SUMMARY.
#
# Inputs (environment):
#   CHANNEL         nightly | beta | stable
#   SOURCE_VERSION  beta: exact nightly version to promote
#                   stable: exact beta version to promote
#   STABLE_DATE     stable: UTC date in YYYY-MM-DD format
set -euo pipefail

out() { echo "$1" >> "$GITHUB_OUTPUT"; }
summary() { echo "$1" >> "$GITHUB_STEP_SUMMARY"; }
fail() { echo "::error::$1"; exit 1; }

# Paperclip-style date version: 2026-11-26 becomes 2026.1126
date_base() { date -u -d "$1" +%Y.%-m%d; }

git fetch origin --tags --force --quiet

case "${CHANNEL}" in
  nightly)
    sha="$(git rev-parse origin/master)"
    version="$(date_base today).0-nightly.${GITHUB_RUN_NUMBER}"
    ;;

  beta)
    [ -n "${SOURCE_VERSION}" ] || fail "beta needs source_version: the exact nightly version to promote"
    tag="nightly/v${SOURCE_VERSION}"
    git rev-parse -q --verify "refs/tags/${tag}" >/dev/null || fail "nightly tag ${tag} does not exist"
    sha="$(git rev-list -n 1 "${tag}")"
    base="${SOURCE_VERSION%%-nightly.*}"
    n="$(git tag -l "beta/v${base}-beta.*" | wc -l | tr -d ' ')"
    version="${base}-beta.${n}"
    ;;

  stable)
    [ -n "${SOURCE_VERSION}" ] || fail "stable needs source_version: the exact beta version to promote"
    [ -n "${STABLE_DATE}" ] || fail "stable needs stable_date in YYYY-MM-DD format"
    tag="beta/v${SOURCE_VERSION}"
    git rev-parse -q --verify "refs/tags/${tag}" >/dev/null || fail "beta tag ${tag} does not exist"
    sha="$(git rev-list -n 1 "${tag}")"
    base="$(date_base "${STABLE_DATE}")"
    n="$(git tag -l "v${base}.*" | wc -l | tr -d ' ')"
    version="${base}.${n}"

    # Pin the master revision the notes are read from, so the publish and
    # canonicalize jobs read the same content even if master moves while
    # the run waits at the npm-stable gate.
    notes_ref="$(git rev-parse origin/master)"
    out "notes_ref=${notes_ref}"
    out "beta_version=${SOURCE_VERSION}"

    if git cat-file -e "${sha}:releases/v${version}.md" 2>/dev/null; then
      out "notes_mode=source_tree"
      out "notes_path=releases/v${version}.md"
    elif git cat-file -e "${notes_ref}:releases/beta/v${SOURCE_VERSION}.md" 2>/dev/null; then
      out "notes_mode=master_beta"
      out "notes_path=releases/beta/v${SOURCE_VERSION}.md"
    else
      fail "no notes for stable ${version}: merge releases/beta/v${SOURCE_VERSION}.md to master before dispatch"
    fi
    summary "- Notes pinned at master \`${notes_ref:0:7}\`"
    ;;

  *)
    fail "unknown channel: ${CHANNEL}"
    ;;
esac

out "channel=${CHANNEL}"
out "version=${version}"
out "sha=${sha}"

summary "## Release selection"
summary ""
summary "- Channel: \`${CHANNEL}\`"
summary "- Version: \`${version}\`"
summary "- Source commit: \`${sha:0:7}\`"
