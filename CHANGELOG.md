<!--
SPDX-License-Identifier: CC-BY-SA-4.0
SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell (hyperpolymath)
-->

# Changelog

All notable changes to `network-ambulance` will be documented in this file.

This file is generated from conventional commits by the
[`changelog-reusable.yml`](https://github.com/hyperpolymath/standards/blob/main/.github/workflows/changelog-reusable.yml)
workflow (`hyperpolymath/standards#206`). Adopt the workflow in this repo's CI to keep this file in sync automatically — see
[`templates/cliff.toml`](https://github.com/hyperpolymath/standards/blob/main/templates/cliff.toml)
for the canonical config.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/);
this project aims to follow [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- feat: add AI Gatekeeper Protocol manifest
- feat(ipv6): comprehensive IPv4/IPv6 dual-stack diagnostics and monitoring
- feat(tauri+rescript): add cross-platform GUI with Tauri 2.0 + ReScript
- feat(ada): add Ada 2022 + SPARK TUI prototype
- feat(d): add JSON output mode for diagnostics and repairs
- feat(d): add routing repair module
- feat(d): add interface repair module
- feat(d): add DNS repair module and CLI repair command
- feat(d): add routing and connectivity diagnostics
- feat: initial D lang core engine implementation (prototype)

### Fixed

- fix(ci): build Hypatia escript from repo root (estate dogfood drift)
- fix(ci): Phase-2 fleet submission must not fail the security gate (#5)
- fix(ci): hypatia-scan workdir (${{ env.HOME }} resolves empty) (#4)
- fix(ci): bump erlef/setup-beam SHA for ubuntu24 runner support (#3)
- fix(ci): hypatia-scan.yml -- pass GITHUB_TOKEN, use --exit-zero (hyperpolymath/hypatia#213) (#2)
- fix: remove duplicate SCM files from root
- fix(security): update editorconfig SHA and CodeQL language
- fix: SHA-pin checkout action, add SPDX header and permissions
- fix: SHA-pin checkout action, add SPDX header and permissions
- fix: SHA-pin checkout action, add SPDX header and permissions

### Documentation

- docs: update SCM files with project information
- docs: add CONTRIBUTING.md
- docs: add checkpoint files for state tracking
- docs(ipv6): add comprehensive transition mechanism and monitoring guides
- docs(minix): add comprehensive MINIX 3.x build documentation
- docs: add D lang core architecture and Ada/SPARK TUI design
- docs: add comprehensive network problem mapping by scope
- docs: update license from AGPL to PMPL

### CI

- ci: bump actions/upload-artifact SHA to current v4 (#1)

## Pre-history

Prior commits to this file's introduction are recorded in git history but not formally classified into Keep-a-Changelog sections. To backfill, run `git cliff -o CHANGELOG.md` locally using the canonical [`cliff.toml`](https://github.com/hyperpolymath/standards/blob/main/templates/cliff.toml) — this is one-shot mechanical work.

---

<!-- This file was seeded by the 2026-05-26 estate tech-debt audit follow-up (Row-2 Phase 3); see [`hyperpolymath/standards/docs/audits/2026-05-26-estate-documentation-debt.md`](https://github.com/hyperpolymath/standards/blob/main/docs/audits/2026-05-26-estate-documentation-debt.md). -->
