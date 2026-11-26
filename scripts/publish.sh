#!/usr/bin/env bash
# Publish one release channel. The npm publish is always a dry run.
# Creates the git tag, and a GitHub release for beta (prerelease) and stable.
#
# Inputs (environment):
#   CHANNEL     nightly | beta | stable
#   VERSION     resolved version
#   SHA         source commit
#   NOTES_FILE  stable only: file holding the pinned release notes
#   GH_TOKEN    token with contents: write
set -euo pipefail

case "${CHANNEL}" in
  nightly) tag="nightly/v${VERSION}"; npm_tag="nightly" ;;
  beta)    tag="beta/v${VERSION}";    npm_tag="beta" ;;
  stable)  tag="v${VERSION}";         npm_tag="latest" ;;
  *) echo "::error::unknown channel: ${CHANNEL}"; exit 1 ;;
esac

npm version "${VERSION}" --no-git-tag-version --allow-same-version >/dev/null
npm publish --dry-run --tag "${npm_tag}"

git tag "${tag}" "${SHA}"
git push origin "refs/tags/${tag}"

case "${CHANNEL}" in
  beta)
    gh release create "${tag}" --verify-tag --prerelease \
      --title "v${VERSION}" --notes "Beta ${VERSION}. Sandbox release: the npm publish ran as a dry run."
    ;;
  stable)
    gh release create "${tag}" --verify-tag --latest \
      --title "v${VERSION}" --notes-file "${NOTES_FILE}"
    ;;
esac

{
  echo "## Published ${CHANNEL} ${VERSION}"
  echo ""
  echo "- Tag: \`${tag}\`"
  echo "- npm: dry run with dist-tag \`${npm_tag}\`"
} >> "$GITHUB_STEP_SUMMARY"
