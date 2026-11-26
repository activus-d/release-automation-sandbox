# Release automation sandbox

A test repository for a gated nightly, beta, and stable release workflow. It follows the public design of [Paperclip's release workflow](https://github.com/paperclipai/paperclip/blob/master/.github/workflows/release.yml), simplified. It's for testing and writing about release automation with AI agents. Nothing here is a real release.

## What it does

The workflow in `.github/workflows/release.yml` handles three channels:

| Channel | How it starts | Gate | What it produces |
| --- | --- | --- | --- |
| Nightly | Schedule at 09:00 UTC, or a manual dispatch | `npm-canary` (no reviewer) | Tag `nightly/v<version>` |
| Beta | Manual dispatch with the exact nightly version | `npm-beta` (required reviewer) | Tag `beta/v<version>`, a prerelease, and a notes draft branch |
| Stable | Manual dispatch with the exact beta version and a date | `npm-stable` (required reviewer) | Tag `v<version>` and a GitHub release that uses the pinned notes |

Every npm publish is a dry run, and the workflow posts no announcements.

## The skipped-job trap

`canonicalize_stable_notes` copies a condition with no status function. GitHub then adds an implicit `success()` that checks every upstream job. `optional_artifacts` is upstream of `publish_stable` and is skipped unless you set `build_optional_artifacts`. So on a normal stable run, the package publishes and the notes job is skipped. Check the stable notes path after every stable release.
