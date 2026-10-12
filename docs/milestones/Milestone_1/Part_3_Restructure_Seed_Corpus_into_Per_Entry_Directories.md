# Restructure Seed Corpus into Per-Entry Directories
<!-- markdownlint-disable MD001 MD036 MD013 MD033 table-column-style -->

This change moves the seed corpus from its flat layout (`tests/corpus/<name>.gd`) into the per-entry layout defined by #37
(`tests/corpus/<entry>/source.gd`), fixes the line drift introduced in #3 so every source matches its Seed Corpus Specification block byte for
byte, and adds the repository protections the golden artifacts depend on: an automated spec-drift check, enforced LF line endings, a
directory-level lint exclusion, and a recorded verification that golden`.gd` files can live inside the Godot project.

---

## Summary – PR #41: Restructure Seed Corpus into Per-Entry Directories

**Author:** @ikostan  
**Repository:** [ikostan/godot-code-coverage-cli-tool](https://github.com/ikostan/godot-code-coverage-cli-tool)  
**Milestone:** 1 – v0.1 Seed Corpus Materialization  
**Linked issue:** #38 ([TASK] Restructure the seed corpus into per-entry directories.)  
**Parent Epic:** #2 ([EPIC] Seed Corpus Materialization & Golden Artifacts)  
**Labels:** `enhancement`, `task`  
**Size:** 5 commits, 38 files, +474 / −56

### What this PR does

Implements #38 in two reviewable steps, as the issue requires:

1. **Restore the content in place.** The sources materialized in #3 did not match the spec: 8 files had gained a `## res://tests/corpus/<name>.gd` header plus a blank line, and every file had extra blank lines between top-level blocks. Every line map, classification, `FunctionMetadata` range and expected error line in the spec was off for the files as they existed (e.g. `func _ready` in `basic_statements.gd` was on line 8; the spec says 7).
2. **Move the files as pure renames.** With the content already fixed, every source and `.uid` sidecar moves into its per-entry directory without changing a byte.

It also carries the PR #39 milestone summary (Part 2), which was written after #39 merged.

### Key changes

**Commit 1 — restore sources to match the spec (`a29de33`)**

- Regenerated all 11 sources from their literal `gdscript` blocks in Seed Corpus Specification v1.5 (blocks unchanged from v1.4).
  - Deletions only: 8 `## res://…` headers and 21 extra blank lines; nothing added.
  - `disabled_instrumentation.gd` is byte-identical to `basic_statements.gd`; `edge_cases.gd` matches Sub-case A.
  - `.uid` sidecars untouched.
- New `tests/unit/test_corpus_spec_sync.gd`:
  - Parses every `#### N. \`name.gd\`` section of the spec and compares the file's bytes with its `gdscript` block.
  - Entries the spec defines as copies (`disabled_instrumentation`, later `edge_cases_invalid_config`) are compared with `basic_statements`'s block.
  - Fails on a single differing byte and names the first differing line; verified to fail on all 11 pre-restore files.
- `lint_test_on_pull.yml`: `docs/seed-corpus-specification-*.md` added to the `gdscript` path filter, so a spec-only PR still runs the GUT suite and the drift check.

**Commit 2 — move into per-entry directories (`48531a1`)**

- `git mv tests/corpus/<name>.gd` → `tests/corpus/<name>/source.gd`, and the `.uid` sidecar the same way, for all 11 entries; `edge_cases` → `edge_cases_unsupported_syntax`. All 22 moves are **R100** in `git diff -M`; UIDs unchanged.
- New `edge_cases_invalid_config/`: `source.gd` is a byte-for-byte copy of `basic_statements`; its `.uid` was **not** copied but generated fresh by a headless Godot 4.7.1 import (`uid://2griybh5fc78`). All 12 UIDs are unique.
- `config.json` per #37:
  - `disabled_instrumentation/` → `{"enable_instrumentation": false}`
  - `edge_cases_invalid_config/` → `{"hit_recorder_expression": "__coverage_hit({column})"}`
- Tests (paths and entry lists only, behavior unchanged):
  - `test_corpus.gd`, `test_corpus_lifecycle.gd`, `test_corpus_values.gd`, `test_corpus_runtime.gd` → `res://tests/corpus/<entry>/source.gd`.
  - `test_corpus_resources.gd`: new path pattern, `edge_cases` → `edge_cases_unsupported_syntax`, adds `edge_cases_invalid_config` so its fresh UID is checked for validity and uniqueness.
  - `test_corpus_spec_sync.gd`: all 12 entries, plus a test asserting spec entry headings == corpus directories == entry list.
- `.gdcheckignore`: `tests/corpus/*.gd` → `tests/corpus`. Both forms were verified to exclude every corpus file (`find`'s `*` matches `/`); the directory form also covers future non-`.gd` goldens.
- `.gitattributes` (new): `tests/corpus/** text eol=lf`.
  - `git add --renormalize .` changed no file; all 26 corpus files are LF in index and worktree.
  - Simulated Windows clone with `core.autocrlf=true`: 0 / 26 corpus files checked out with CRLF (vs. 5 / 5 for `.gd` files outside the rule).

**Golden `.gd` verification (`a6e73df`)**

- New `docs/corpus-golden-gd-verification.md` recording #38 §6:
  - A placeholder `expected.instrumented.gd` calling the undefined `__coverage_hit()` does **not** affect a clean headless import, the full GUT suite (39/39 with CI flags), or `check.sh`.
  - Godot reports the missing function only when the golden is `load()`ed. **No fallback is needed**; the harness must read goldens as text.
  - Godot generates `.uid` sidecars for goldens; commit-or-ignore left as an open decision for #6 / #28 (ignore recommended).

**Documentation**

- `docs/milestones/Milestone_1/Part_2_Publish Contract_and_Seed_Corpus_Spec.md`: PR #39 summary (added, then renamed).
- `docs/corpus-golden-gd-verification.md`: golden `.gd` verification record.

### Files touched (high level)

| Area   | Files                                                                                                   |
|--------|---------------------------------------------------------------------------------------------------------|
| Corpus | `tests/corpus/<entry>/source.gd` (+ `.uid`) ×12, `tests/corpus/*/config.json` ×2                        |
| Tests  | `tests/unit/test_corpus_spec_sync.gd` (new), 4 corpus test files, `tests/unit/test_corpus_resources.gd` |
| CI     | `.github/workflows/lint_test_on_pull.yml`                                                               |
| Repo   | `.gitattributes` (new), `.gdcheckignore`                                                                |
| Docs   | `docs/corpus-golden-gd-verification.md`, Milestone 1 Part 2                                             |

### Review & quality tooling

- **@sourcery-ai** – Summary by Sourcery and Reviewer's Guide with flow diagram and assessment against #38; review run skipped (weekly review budget reached).
- **@coderabbitai** – no review posted; free OSS review limit reached.
- **@claude (Opus 5.5)** – implemented both #38 commits and the golden-verification record, and verified everything on headless Godot 4.7.1.
- **@deepsource-io** / **@codecov** – part of the intended quality stack (no activity observed on this PR).
- **@dependabot** – standard dependency bot (no direct activity on this PR).

### CI

On `a6e73df`:

- GDScript Lint and Format Check: ✅
- GUT Unit Tests: ✅
- Markdown Lint: ✅
- YAML Lint: ✅
- Sourcery review: skipped (rate limit).

### Status

Open. Addresses every acceptance criterion of #38. Unblocks #7 (corpus README), #4, #5, #6, #28 and #29, which write their artifacts into the new directories.

### Follow-ups

- **Golden `.uid` sidecars:** decide in #6 / #28 whether to commit or ignore them (recommended: `tests/corpus/**/expected.*.gd.uid` in `.gitignore`).
- ⚠️ **Spec `exercise.gd` gap from PR #39 is still open:** `docs/seed-corpus-specification-v1.5.md` still lacks the "conditional, pending #23" edits that Contract v1.4 has.
- **Part 2 file name contains a space** (`Part_2_Publish Contract_and_…`), unlike Part 1; consider renaming to underscores.
- #38's description says 9 files had a header; there were 8 (`control_flow.gd` never had one). No impact on the fix.

---

## Reviewer's Guide

This PR restores the 11 seed corpus sources to byte-for-byte agreement with the Seed Corpus Specification, moves them into per-entry
directories as pure renames, adds the 12th entry and both `config.json`fixtures, updates every corpus test to the new paths, and adds the
repository protections the golden artifacts rely on.

### File-Level Changes

| Change                                                                                                     | Details                                                                                                                                                                                                                                                                 | Files                                                                                                                                                                                                 |
|------------------------------------------------------------------------------------------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Restores corpus sources to match their spec blocks and adds an automated drift check.                      | <ul><li>Removes 8 path headers and 21 extra blank lines; no other byte changes.</li><li>Adds a GUT test comparing each source with its spec block byte for byte, naming the first differing line.</li><li>Adds the spec to the PR pipeline's GUT path filter.</li></ul> | `tests/corpus/*.gd`<br/>`tests/unit/test_corpus_spec_sync.gd`<br/>`.github/workflows/lint_test_on_pull.yml`                                                                                           |
| Moves the corpus into per-entry directories and adds the split edge-case entry and configuration fixtures. | <ul><li>22 pure renames (sources and `.uid` sidecars); UIDs unchanged.</li><li>New `edge_cases_invalid_config/` with a copied source and a freshly generated UID.</li><li>`config.json` for `disabled_instrumentation/` and `edge_cases_invalid_config/`.</li></ul>     | `tests/corpus/<entry>/source.gd`<br/>`tests/corpus/<entry>/source.gd.uid`<br/>`tests/corpus/*/config.json`                                                                                            |
| Updates corpus tests to the new layout.                                                                    | <ul><li>Path-only changes in four test files.</li><li>Resource test covers all 12 entries' UIDs.</li><li>Drift test asserts spec entries, corpus directories and entry list agree.</li></ul>                                                                            | `tests/integration/test_corpus_runtime.gd`<br/>`tests/unit/test_corpus.gd`<br/>`tests/unit/test_corpus_lifecycle.gd`<br/>`tests/unit/test_corpus_resources.gd`<br/>`tests/unit/test_corpus_values.gd` |
| Adds line-ending and lint protections and records the golden `.gd` verification.                           | <ul><li>LF enforced for `tests/corpus/**`.</li><li>Whole corpus directory excluded from gdlint / gdformat.</li><li>Placeholder-golden experiment and results documented.</li></ul>                                                                                      | `.gitattributes`<br/>`.gdcheckignore`<br/>`docs/corpus-golden-gd-verification.md`                                                                                                                     |

### Assessment against linked issues

| Issue                                                                    | Objective                                                                                                                      | Addressed | Explanation                                                                                      |
|--------------------------------------------------------------------------|--------------------------------------------------------------------------------------------------------------------------------|-----------|--------------------------------------------------------------------------------------------------|
| [#38](https://github.com/ikostan/godot-code-coverage-cli-tool/issues/38) | Every corpus source is byte-identical to its spec block (in its own commit), and an automated check enforcing this runs in CI. | ✅        | `a29de33`; `test_corpus_spec_sync.gd` runs in GUT, triggered by spec changes too.                |
| [#38](https://github.com/ikostan/godot-code-coverage-cli-tool/issues/38) | Every source lives at `tests/corpus/<entry>/source.gd` with its `.uid`, moved as pure renames.                                 | ✅        | `48531a1`: 22 × R100.                                                                            |
| [#38](https://github.com/ikostan/godot-code-coverage-cli-tool/issues/38) | `edge_cases` split into two entries; the new one is a `basic_statements` copy with a fresh, unique UID.                        | ✅        | `uid://2griybh5fc78`; 12 unique UIDs.                                                            |
| [#38](https://github.com/ikostan/godot-code-coverage-cli-tool/issues/38) | `config.json` for `disabled_instrumentation/` and `edge_cases_invalid_config/` with the values from #37.                       | ✅        | Both match Spec v1.5.                                                                            |
| [#38](https://github.com/ikostan/godot-code-coverage-cli-tool/issues/38) | All four corpus test files use the new paths; `test_corpus_resources.gd` covers all 12 entries; full GUT suite passes.         | ✅        | 39/39 locally and in CI.                                                                         |
| [#38](https://github.com/ikostan/godot-code-coverage-cli-tool/issues/38) | `check.sh` processes no file under `tests/corpus/`, confirmed after the move.                                                  | ✅        | 13 files processed, none in the corpus.                                                          |
| [#38](https://github.com/ikostan/godot-code-coverage-cli-tool/issues/38) | `.gitattributes` enforces LF for `tests/corpus/**`; renormalization changes no corpus file.                                    | ✅        | Also verified with a simulated `autocrlf=true` clone.                                            |
| [#38](https://github.com/ikostan/godot-code-coverage-cli-tool/issues/38) | Effect of golden `.gd` files on import, GUT and `check.sh` verified; fallback chosen if needed.                                | ✅        | `docs/corpus-golden-gd-verification.md`; no fallback needed. Sourcery's ❌ predates this commit. |

---

## Bot & AI Contributions to PR #41

This pull request received automated assistance from bots and AI tools for implementation, verification, summaries, and quality workflows.

### @claude (Opus 5.5)

- Implemented #38 as two commits: restoring the corpus sources to match the spec (with an automated drift check), then moving them into per-entry directories as pure renames.
- Added the `edge_cases_invalid_config` entry, both `config.json` files, the test path updates, and the `.gitattributes` / `.gdcheckignore` changes.
- Cleaned up commit message trailers on the PR branch at @ikostan's request.

### @sourcery-ai

- Generated the **Summary by Sourcery** in the PR description (new features, bug fixes, enhancements, CI, documentation, tests).
- Produced the **Reviewer's Guide** with a per-entry synchronization flow diagram, file-level change analysis, and assessment against #38; flagged the golden `.gd` verification as missing from the diff, which `a6e73df` then added.
- Review run skipped: the weekly review budget (250,000 diff characters) was reached.

### @coderabbitai

- Posted its review status comment; no review was performed because the free OSS review limit was reached (CHILL profile, Advanced plan).

---

## Human Contributor

### @ikostan

- Primary author and owner of the PR and of issue #38, including the implementation plan the PR follows.
- Directed the work, reviewed each step, and approved pushing to the PR branch.
- Self-assigned the PR, added the `enhancement` and `task` labels, linked issue #38, and added the PR to Milestone 1.

---
<!-- markdownlint-enable MD001 MD036 MD013 MD033 table-column-style -->
