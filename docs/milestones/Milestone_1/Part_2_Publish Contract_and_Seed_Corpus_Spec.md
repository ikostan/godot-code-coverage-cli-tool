# Publish Contract v1.4 and Seed Corpus Spec v1.5
<!-- markdownlint-disable MD001 MD036 MD013 MD033 table-column-style -->

This change defines how the seed corpus is laid out on disk and how
per-entry configuration is recorded, and publishes both as an
amendment to Contract §13 (Instrumentation Contract v1.4) and the
Seed Corpus Specification (v1.5). It splits `edge_cases.gd` into two
entries, takes the corpus from 11 to 12 entries, and changes no code
and moves no files.

---

## Summary – PR #39: Publish Contract v1.4 and Seed Corpus Spec v1.5 (#37)

**Author:** @ikostan  
**Repository:** [ikostan/godot-code-coverage-cli-tool](https://github.com/ikostan/godot-code-coverage-cli-tool)  
**Milestone:** 1 – v0.1 Seed Corpus Materialization  
**Linked issue:** #37 ([TASK] Define corpus layout and per-entry config; publish §13 amendment)  
**Parent Epic:** #2 ([EPIC] Seed Corpus Materialization & Golden Artifacts)  
**Label:** `task`  
**Merged:** 2026-10-11 by @ikostan (3 commits, 3 files, +185 / −31)

### What this PR does

Settles the on-disk corpus layout that every remaining golden-artifact task in Epic #2 writes into, and publishes it as a contract and spec amendment. It resolves the three gaps between the contract, the spec, and the corpus materialized in #3:

1. **The layout couldn't hold the artifacts.** Contract §13 names artifacts with fixed names (`source.gd`, `expected.instrumented.gd`, …), which only works with one directory per entry. The flat `tests/corpus/<n>.gd` layout would have made the goldens collide.
2. **Per-entry configuration had nowhere to live.** `disabled_instrumentation.gd` and Sub-case B of `edge_cases.gd` both need non-default configuration, and §13 had no artifact for it.
3. **`edge_cases.gd` didn't fit §13.2.** It was one entry with two sub-cases but only one `expected.error.json`, and Sub-case B's source was unspecified.

### Key changes

**Instrumentation Contract v1.4** (renamed from `instrumentation-contract-v1.2.md`)

- Folded into v1.4 because #17 has not yet published v1.4.
- §13: one directory per corpus entry with fixed artifact names; directory name = the spec's source filename without `.gd`; `source.gd` keeps its `.uid` sidecar.
- §13.1 / §13.2: `config.json` added as an optional artifact.
- §13.3 (new): `config.json` rules:
  - Baseline is the Seed Corpus Spec's default configuration, **not** the Contract §3 defaults.
  - Contains only the keys the entry overrides; absent file means corpus defaults apply unchanged.
  - Allowed keys are exactly the `InstrumentationConfig` fields; unknown keys are an error.
  - Flat JSON object, LF line endings.
  - Table of corpus defaults vs. Contract §3 defaults (`include_non_executable`, `hit_recorder_expression` differ).
- `exercise.gd` marked **conditional, pending #23** in the §13 layout tree, the exercise-mechanism note, and the §13.1 table.
- §7 / §14: `contract_version` bumped to `"1.4"`; §14 now also requires a new version for golden-artifact structure changes.
- §14.1 (new) version notes: no change to classification, mapping, metadata meaning, or error semantics.

**Seed Corpus Specification v1.5** (renamed from `seed-corpus-specification-v1.4.md`)

- New *Corpus layout* section with the per-entry tree and a 12-row entry → directory → pipeline → `config.json` table.
- `config.json` rule and defaults table, worded identically to Contract §13.3.
- `disabled_instrumentation.gd` now shows its `config.json` (`"enable_instrumentation": false`).
- `edge_cases.gd` replaced by two entries:
  - `edge_cases_unsupported_syntax.gd` — Sub-case A's block byte for byte, no `config.json`, `UNSUPPORTED_SYNTAX`.
  - `edge_cases_invalid_config.gd` — byte-for-byte copy of `basic_statements.gd`, `config.json` with `"hit_recorder_expression": "__coverage_hit({column})"`, `INVALID_CONFIGURATION` with `original_line: -1`. Empty-template case recorded as an optional third entry.
- Acceptance criteria updated for 12 directories and for `config.json` placement.
- All 11 GDScript source blocks and line numbers unchanged byte for byte (verified by diffing every block against v1.4).

**Documentation**

- `Readme.md`: doc links, "locked" status line, and roadmap checklist now point at Contract v1.4 and Spec v1.5.

### Files touched (high level)

| Area     | Files                                                                                     |
|----------|-------------------------------------------------------------------------------------------|
| Contract | `docs/instrumentation-contract-v1.2.md` → `docs/instrumentation-contract-v1.4.md`         |
| Spec     | `docs/seed-corpus-specification-v1.4.md` → `docs/seed-corpus-specification-v1.5.md`       |
| Docs     | `Readme.md`                                                                               |

### Commits

| Commit    | Author   | Message                                                |
|-----------|----------|--------------------------------------------------------|
| `bf15e75` | @claude (Opus 5.5), committed as @ikostan | Publish Contract v1.4 and Seed Corpus Spec v1.5 (#37) |
| `0a6c7b6` | @ikostan | Align seed corpus table formatting                     |
| `4df8f06` | @ikostan | Clarify v1.4 corpus exercise artifacts                 |

### Review & quality tooling

- **@sourcery-ai** – Summary by Sourcery, Reviewer's Guide with assessment against #37; **approved** on `bf15e75`.
- **@coderabbitai** – Summary by CodeRabbit; one actionable review comment (`exercise.gd` required vs. optional), acknowledged the fix and recorded a repository learning; later hit the free OSS review limit.
- **@claude (Opus 5.5)** – drafted the amendment, the initial commit, and the `exercise.gd` / `contract_version` follow-up fix.
- **@deepsource-io** / **@codecov** – part of the intended quality stack (no activity observed on this PR).
- **@dependabot** – standard dependency bot (no direct activity on this PR).

### CI

- Markdown Lint: ✅ on `bf15e75` and `4df8f06`.
- GDScript Lint, GUT Unit Tests, YAML Lint: skipped by path filters (docs-only change).
- Sourcery review: ✅.

### Status

Merged. Addresses the objectives of issue #37 with one gap (see *Follow-ups*). Unblocks #38 (restructure into per-entry directories), #7, #4, #5, #6, #28 and #29.

### Follow-ups

- ⚠️ **Spec half of the CodeRabbit fix did not land.** `4df8f06` updated only the contract. `docs/seed-corpus-specification-v1.5.md` on `main` still lacks:
  - the `exercise.gd` line in the *Corpus layout* tree,
  - the "conditional until #23 decides" sentence in the *Exercise mechanism* bullet (line 56),
  - the "`exercise.gd` excluded until #23 decides" clause in the first acceptance criterion.

  The PR reply to CodeRabbit states the spec was updated, so the two documents currently disagree on `exercise.gd`.
- **Contract version sequencing.** #13 still plans Contract v1.3 and Spec v1.5; with v1.4 / v1.5 now published, #13's target versions need updating.
- **#38** must update `.gdcheckignore` (`tests/corpus/*.gd` won't match `tests/corpus/*/source.gd`).

---

## Reviewer's Guide

This PR publishes Contract v1.4 and Seed Corpus Specification v1.5,
formalizing the per-entry directory/artifact layout and per-entry
`config.json` overrides, splitting the edge-case entry in two,
updating acceptance criteria for 12 entries, and refreshing README
version references. No source content or instrumentation semantics
change.

### File-Level Changes

| Change                                                                                                                            | Details                                                                                                                                                                                                                                                                                                                                                                                                                                            | Files                                    |
|-----------------------------------------------------------------------------------------------------------------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|------------------------------------------|
| Publishes the instrumentation contract as v1.4 with a per-entry corpus artifact layout and optional per-entry configuration.      | <ul><li>Specifies a dedicated directory for each corpus entry, with fixed artifact names and `.uid` sidecars kept beside `source.gd`.</li><li>Adds optional `config.json` for success and expected-failure entries, with baseline, allowed-keys and format rules (§13.3).</li><li>Marks `exercise.gd` conditional pending #23.</li><li>Bumps `contract_version` to `"1.4"` and adds §14.1 version notes stating semantics are unchanged.</li></ul> | `docs/instrumentation-contract-v1.4.md`  |
| Publishes Seed Corpus Specification v1.5 with the matching layout, the split edge-case entries, and 12-entry acceptance criteria. | <ul><li>Adds the *Corpus layout* section and 12-row entry table.</li><li>States the corpus defaults as the `config.json` baseline, worded identically to Contract §13.3.</li><li>Replaces `edge_cases.gd` with `edge_cases_unsupported_syntax.gd` and `edge_cases_invalid_config.gd`, recording Sub-case B's source and invalid placeholder.</li><li>Keeps every GDScript source block and line number byte for byte.</li></ul>                    | `docs/seed-corpus-specification-v1.5.md` |
| Updates README references to the new document versions.                                                                           | <ul><li>Doc links, locked-status line and roadmap checklist point at Contract v1.4 and Spec v1.5.</li></ul>                                                                                                                                                                                                                                                                                                                                        | `Readme.md`                              |

### Assessment against linked issues

| Issue                                                                    | Objective                                                                                                                                | Addressed | Explanation                                                                                          |
|--------------------------------------------------------------------------|------------------------------------------------------------------------------------------------------------------------------------------|-----------|------------------------------------------------------------------------------------------------------|
| [#37](https://github.com/ikostan/godot-code-coverage-cli-tool/issues/37) | Specify the per-entry layout, including directory naming and which artifacts each entry type carries.                                    | ✅        | Contract §13 and Spec *Corpus layout*.                                                               |
| [#37](https://github.com/ikostan/godot-code-coverage-cli-tool/issues/37) | Specify the `config.json` rule: corpus defaults as baseline, overrides only, absent means defaults, unknown keys are an error.           | ✅        | Contract §13.3; same wording in the Spec.                                                            |
| [#37](https://github.com/ikostan/godot-code-coverage-cli-tool/issues/37) | State the corpus default configuration explicitly, including where it differs from Contract §3.                                          | ✅        | Defaults table in both documents.                                                                    |
| [#37](https://github.com/ikostan/godot-code-coverage-cli-tool/issues/37) | Split `edge_cases.gd` into two entries, recording Sub-case B's source and invalid `hit_recorder_expression`.                             | ✅        | `basic_statements.gd` copy; `__coverage_hit({column})`.                                              |
| [#37](https://github.com/ikostan/godot-code-coverage-cli-tool/issues/37) | Publish the contract amendment under a new version (folded into v1.4 if #17 hasn't shipped it), with notes that semantics are unchanged. | ✅        | Contract v1.4, §14.1.                                                                                |
| [#37](https://github.com/ikostan/godot-code-coverage-cli-tool/issues/37) | Publish Seed Corpus Spec v1.5 with every source block and line number otherwise unchanged.                                               | ✅        | All 11 blocks verified byte for byte.                                                                |
| [#37](https://github.com/ikostan/godot-code-coverage-cli-tool/issues/37) | Nothing in the amendment conflicts with #23's exercise-mechanism decision.                                                               | ⚠️        | Contract marks `exercise.gd` conditional; the Spec's matching edits did not land (see *Follow-ups*). |

---

## Bot & AI Contributions to PR #39

This pull request received automated assistance from bots and AI tools for drafting, code review, summaries, and quality workflows.

### @claude (Opus 5.5)

- Reviewed issue #37 against Contract v1.2, Seed Corpus Spec v1.4 and the materialized corpus before implementation.
- Authored commit `bf15e75` — "Publish Contract v1.4 and Seed Corpus Spec v1.5 (#37)" (committed under @ikostan's identity):
  - Renamed both documents to their new versions.
  - Wrote Contract §13 layout, §13.1 / §13.2 `config.json` rows, §13.3, the §14 versioning rule and §14.1 version notes.
  - Wrote the Spec's *Corpus layout* section, 12-entry table, `config.json` rule, split edge-case entries and updated acceptance criteria.
  - Updated README links and status lines.
- Verified all 11 GDScript source blocks were byte-identical to v1.4, and that the `config.json` baseline wording was identical in both documents.
- Caught and reverted markdownlint's auto-fix (repo config `fix: true`), which had converted GDScript tab indentation to spaces in the source blocks.
- In response to the CodeRabbit finding, drafted the `exercise.gd` "conditional, pending #23" edits for both documents and the §7 `contract_version = "1.4"` fix (an earlier block restore had reverted it to `"1.2"`); handed them to @ikostan as snippets, applied in `4df8f06`.

### @coderabbitai

- Generated the **Summary by CodeRabbit** in the PR description (documentation updates to Contract v1.4 and Spec v1.5, per-entry layout, 12 entries, README roadmap).
- Posted one actionable review comment on `docs/instrumentation-contract-v1.4.md` L334 (🟡 Minor, Data Integrity & Integration): resolve whether success entries require `exercise.gd`, and align both documents.
- Acknowledged the fix and added a repository learning: issue #23 owns the `exercise.gd` vs. GUT-suite choice, and corpus docs must keep `exercise.gd` conditional until then.
- Reported the free OSS review limit reached in its summary comment.

### @sourcery-ai

- Generated the **Summary by Sourcery** (new features, enhancements, documentation).
- Produced the **Reviewer's Guide** with file-level change analysis and assessment against linked issue #37 (all objectives marked ✅).
- Reviewed and **approved** the changes on `bf15e75`.

### @deepsource-io

- **DeepSource Code Review** integration is part of the project's quality tooling set.
- No DeepSource review comment or Report Card was observed on this PR's timeline. Included for complete contributor recognition as requested.

### @codecov

- **Codecov** coverage reporting is part of the expected CI quality stack for this project.
- No Codecov Report comment was observed on this PR's timeline (docs-only change; coverage reporting may not be configured yet). Included for complete contributor recognition as requested.

### @dependabot

- Standard dependency-management bot integration present in the repository workflow.
- No direct commits or comments observed on this PR; included for complete contributor recognition as requested.

---

## Human Contributor

### @ikostan

- Primary author and owner of the PR and of issue #37, including the implementation plan the PR follows.
- Authored commits:
  - `0a6c7b6` — "Align seed corpus table formatting"
  - `4df8f06` — "Clarify v1.4 corpus exercise artifacts"
- Replied to and resolved the CodeRabbit review thread.
- Self-assigned the PR, added the `task` label, linked issue #37, added the PR to Milestone 1, and merged it.

---
<!-- markdownlint-enable MD001 MD036 MD013 MD033 table-column-style -->