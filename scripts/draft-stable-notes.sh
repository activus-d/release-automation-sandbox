#!/usr/bin/env bash
# Draft the stable notes for a beta. The draft is a skeleton: a person or an
# agent curates it during the soak, and the stable release reads it from master.
#
# Usage: draft-stable-notes.sh <beta-version> <source-sha>
set -euo pipefail

beta="$1"
sha="$2"
file="releases/beta/v${beta}.md"

prev="$(git tag -l 'v*' --sort=-v:refname | grep -v -- '-' | head -n 1 || true)"
if [ -n "${prev}" ]; then
  range="${prev}..${sha}"
  intro="Changes since ${prev}."
else
  range="${sha}"
  intro="First stable release of the sandbox."
fi

{
  echo "# Release Automation Sandbox vSTABLE_VERSION"
  echo ""
  echo "> Released: STABLE_DATE"
  echo ""
  echo "Promoted from \`${beta}\`. ${intro}"
  echo ""
  echo "## Changes"
  echo ""
  # Leave internal CI changes out of the notes.
  git log --no-merges --format='- %s (%h)' "${range}" \
    | grep -v -E '^- (ci|chore\(ci\)|build\(ci\))(\(|:)' || echo "- No user-facing changes."
} > "${file}"

echo "Drafted ${file}"
