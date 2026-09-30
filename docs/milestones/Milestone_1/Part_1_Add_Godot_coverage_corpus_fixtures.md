# Add Godot coverage corpus fixtures
<!-- markdownlint-disable MD001 MD036 MD013 MD033 table-column-style -->

This change adds a corpus of sample GDScript files for coverage 
testing, covering autoloads, coroutine awaits, control flow, 
lambdas, typed annotations, multiline expressions, static 
initialization, class scopes, and edge cases. It also updates 
scene metadata with unique IDs and removes redundant load_steps 
entries from the default environment and scene files.

---

## Summary – PR #15: Add Godot coverage corpus fixtures

**Author:** @ikostan  
**Repository:** [ikostan/godot-code-coverage-cli-tool](https://github.com/ikostan/godot-code-coverage-cli-tool)  
**Milestone:** 1 – v0.1 Seed Corpus Materialization  
**Linked issue:** #3 ([TASK] Create tests/corpus/ directory and 11 locked .gd source files)  
**Label:** `task`

### What this PR does

Adds a locked, UID-backed GDScript **coverage corpus** of representative fixtures for the Godot code-coverage CLI tool, plus runtime/unit tests that validate fixture behavior and resource metadata. Also establishes reusable CI workflows for linting, headless GUT tests, YAML/Markdown validation, and release drafting.

### Key changes

**New features / corpus**

- Added `tests/corpus/` with representative GDScript fixtures covering:
  - Autoload-style readiness
  - Coroutine `await`s
  - Control flow
  - Lambdas
  - Typed annotations / `@onready`
  - Multiline expressions
  - Static initialization
  - Class scopes / inner classes
  - Edge cases and disabled-instrumentation cases
- Added per-resource `.uid` sidecars
- Normalized scene/environment metadata (`spatial.tscn`, `default_env.tres`): unique IDs, removed redundant `load_steps`

**Tests**

- GUT unit & integration coverage for:
  - Fixture runtime semantics and values
  - Lifecycle / tree-entry / ready callbacks
  - Coroutine suspension, resumption, concurrency
  - Instance independence, static state, inner-class construction
  - Scene connections, environment subresources, UID uniqueness/resolution
- New test files include:
  - `tests/integration/test_corpus_runtime.gd`
  - `tests/unit/test_corpus.gd`
  - `tests/unit/test_corpus_lifecycle.gd`
  - `tests/unit/test_corpus_resources.gd`
  - `tests/unit/test_corpus_values.gd`

**CI / tooling**

- Reusable workflows:
  - `gdlint.yml`, `gut_tests.yml`, `yamllint.yml`, `lint_readme.yml`, `release_drafter.yml`
  - Orchestration: `lint_test_on_pull.yml`, `lint_test_deploy.yml`
- Config: `.yamllint.yaml`, `.markdownlint-cli2.yaml`, `.gdcheckignore`
- Path-aware PR checks, concurrency cancellation, headless Godot/GUT with JUnit artifacts
- GUT submodule updated to v9.7.0 (Godot 4.7 Logger compatibility)

**Documentation**

- Milestone doc: `docs/milestones/Milestone_1/Part_1_Add_Godot_coverage_corpus_fixtures.md`
- Updates to seed-corpus specification, instrumentation contract, README, and issue templates

### Files touched (high level)

| Area   | Files                                                                  |
|--------|------------------------------------------------------------------------|
| Corpus | `tests/corpus/*.gd` (+ UIDs), `spatial.tscn`, `default_env.tres`       |
| Tests  | `tests/unit/*`, `tests/integration/test_corpus_runtime.gd`             |
| CI     | `.github/workflows/*`, `.yamllint.yaml`, `.markdownlint-cli2.yaml`     |
| Docs   | Milestone 1 Part 1, seed-corpus spec, instrumentation contract, README |

### Review & quality tooling

- **@sourcery-ai** – PR summary + Reviewer’s Guide; initial approval (later withdrawn after extra pushes / rate limits)
- **@coderabbitai** – PR summary + reviews + GUT test-generation commits
- **@deepsource-io** / **@codecov** – part of the intended quality stack (no dedicated comments observed on this PR timeline)
- **@dependabot** – standard dependency bot (no direct activity on this PR)

### Status

Addresses the objectives of issue #3 (corpus directory, 11 locked sources matching Seed Corpus Specification v1.4, Unix line endings). Ready for continued review after CI and bot feedback iteration.

---

## Reviewer's Guide

This PR adds a broad, UID-backed GDScript coverage corpus with 
runtime and resource-integrity tests, while also establishing 
reusable lint/test CI workflows and path-aware pull-request 
validation.

### File-Level Changes

| Change                                                                                                                                                         | Details                                                                                                                                                                                                                                                                                                                                                                                 | Files                                                                                                                                                                                                                                                                                                         |
|----------------------------------------------------------------------------------------------------------------------------------------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Expanded the Godot fixture corpus with focused scripts and stable resource UIDs covering syntax, initialization, lifecycle, coroutine, and edge-case behavior. | <ul><li>Added fixtures for autoload-style readiness, awaits, declarations, control flow, lambdas, typed onready properties, multiline expressions, static initialization, inner classes, and unsupported instrumentation cases.</li><li>Added per-resource UID sidecars and updated scene/environment metadata by normalizing UIDs and removing redundant load-step metadata.</li></ul> | `tests/corpus/*.gd`<br/>`tests/corpus/*.gd.uid`<br/>`default_env.tres`<br/>`spatial.tscn`                                                                                                                                                                                                                     |
| Added GUT tests that exercise fixture runtime semantics, values, lifecycle behavior, and resource integrity.                                                   | <ul><li>Captured logger output to verify ready callbacks, lambda results, and coroutine resumption timing.</li><li>Covered branch boundaries, instance independence, static state, inner-class construction, annotations, scene connections, environment subresources, and UID uniqueness/resolution.</li></ul>                                                                         | `tests/integration/test_corpus_runtime.gd`<br/>`tests/unit/test_corpus.gd`<br/>`tests/unit/test_corpus_lifecycle.gd`<br/>`tests/unit/test_corpus_resources.gd`<br/>`tests/unit/test_corpus_values.gd`                                                                                                         |
| Introduced reusable CI workflows and a change-aware pull-request pipeline for linting, Godot tests, YAML/Markdown validation, and release drafting.            | <ul><li>Added GDScript formatting/lint checks using gdtoolkit.</li><li>Added headless Godot/GUT execution with import warm-up and JUnit artifact upload.</li><li>Added path-based job selection, concurrency cancellation, reusable workflow orchestration, and YAML/Markdown linting.</li><li>Added release-drafter execution and validation of the generated release tag.</li></ul>   | `.github/workflows/gdlint.yml`<br/>`.github/workflows/gut_tests.yml`<br/>`.github/workflows/lint_readme.yml`<br/>`.github/workflows/lint_test_deploy.yml`<br/>`.github/workflows/lint_test_on_pull.yml`<br/>`.github/workflows/release_drafter.yml`<br/>`.github/workflows/yamllint.yml`<br/>`.yamllint.yaml` |

### Assessment against linked issues

| Issue                                                            | Objective                                                                                                             | Addressed | Explanation |
|------------------------------------------------------------------|-----------------------------------------------------------------------------------------------------------------------|-----------|-------------|
| https://github.com/ikostan/godot-code-coverage-cli-tool/issues/3 | Create the tests/corpus/ directory and add the 11 required locked GDScript source files with the specified filenames. | ✅        |             |
| https://github.com/ikostan/godot-code-coverage-cli-tool/issues/3 | Ensure the contents of all 11 corpus files match Seed Corpus Specification v1.4.                                      | ✅        |             |
| https://github.com/ikostan/godot-code-coverage-cli-tool/issues/3 | Ensure every corpus source file uses strict Unix line endings.                                                        | ✅        |             |

---

## Bot & AI Contributions to PR #15

This pull request received automated assistance from bots and AI tools for code review, test generation, summaries, and quality workflows.

### @coderabbitai

- Generated the **Summary by CodeRabbit** in the PR description (expanded tests for script initialization, control flow, coroutines, lambdas, scene/environment loading, plus CI lint/test workflows).
- Performed multiple AI code reviews (CHILL profile, Advanced plan), including actionable feedback on corpus fixture line maps and disabled-instrumentation content alignment.
- Authored commits:
  - `d4ad25f` — “Add GUT unit and integration tests for corpus behavior and scene metadata”
  - `40ee63c` — “Add GUT unit tests for corpus behavior, lifecycle, and resource integrity”
- Started coding-agent unit-test generation tasks and provided finishing-touch / review-stack guidance.

### @sourcery-ai

- Generated the **Summary by Sourcery** covering new features, enhancements, tests, and chores.
- Produced the detailed **Reviewer’s Guide** with file-level change analysis and assessment against linked issue #3.
- Reviewed and **previously approved** the changes; later withdrew approval after additional pushes exceeded the auto-review limit (rate-limit messaging followed).

### @deepsource-io

- **DeepSource Code Review** integration is part of the project’s quality tooling set.
- No DeepSource review comment or Report Card was observed on this specific PR timeline (may not have run or may not be fully wired for this repository yet). Included for complete contributor recognition as requested.

### @codecov

- **Codecov** coverage reporting is part of the expected CI quality stack for this project.
- No Codecov Report comment was observed on this specific PR timeline (coverage reporting may not yet be configured or may not have posted on this PR). Included for complete contributor recognition as requested.

### @dependabot

- Standard dependency-management bot integration present in the repository workflow.
- No direct commits or comments observed on this specific PR; included for complete contributor recognition as requested.

---

## Human Contributor

### @ikostan

- Primary author and owner of the PR.
- Authored the majority of commits, including:
  - Core corpus fixtures (“Add Godot coverage corpus fixtures”)
  - Header normalization and cleanup
  - Corpus test UID files
  - Reusable CI workflows (gdlint, GUT, yamllint, markdownlint, release drafter, PR/push orchestration)
  - Workflow fixes (path filters, permissions, headless GUT invocation, markdownlint config)
  - Documentation updates (milestone notes, seed-corpus specification, instrumentation contract, README)
  - GUT submodule update for Godot 4.7 Logger compatibility
- Self-assigned the PR, added the `task` label, linked issue #3, and added the PR to Milestone 1 and the project board.
- Actively iterated on feedback from the above bots/AI tools (including requesting Sourcery re-reviews).

---
<!-- markdownlint-enable MD001 MD036 MD013 MD033 table-column-style -->
