# Draft expected.metadata.json Goldens for Success Pipelines
<!-- markdownlint-disable MD001 MD036 MD013 MD033 table-column-style -->

This change adds hand-derived `expected.metadata.json` goldens for all 10 success-pipeline corpus entries, a GUT suite that validates them
against Instrumentation Contract v1.4 and the Seed Corpus Specification v1.5, and the repository protections the goldens depend on:
repository-wide LF line endings, a strict JSON linter in CI, and a Godot ignore marker that keeps the GUT submodule out of the project.

---

## Summary – PR #43: Draft expected.metadata.json payloads for success pipelines

**Author:** @ikostan  
**Repository:** [ikostan/godot-code-coverage-cli-tool](https://github.com/ikostan/godot-code-coverage-cli-tool)  
**Milestone:** 1 – v0.1 Seed Corpus Materialization  
**Linked issue:** #4 ([TASK] Draft expected.metadata.json payloads for success pipelines)  
**Parent Epic:** #2 ([EPIC] Seed Corpus Materialization & Golden Artifacts)  
**Label:** `task`  
**Size:** 10 commits, 19 files, +740 / −4

### What this PR does

Gives the analyzer (M2) its first deterministic targets: for every success entry, the exact per-line classification, the
`executable_lines` / `skipped_lines` partition, the `hit_record_inserted` flag and the `FunctionMetadata` array, all derived by hand from
the spec and checked against the restored `source.gd` files, never captured from tool output.

It resolves the scope question #4 required to be settled before drafting:

- **Reading (b), classification-only.** `line_mappings` carry `original_line`, `classification` and `hit_record_inserted`.
  `instrumented_lines` is intentionally omitted: post-transformation positions depend on the class-level injection strategy (#17) and are
  owned by `expected.instrumented.gd` (#28). Predicting them here would create a second hand-written source of truth.
- **`hit_record_inserted` is still predictable.** It is `enable_instrumentation && classification == "executable"`, forced by Contract
  §5 / §7 (every selected executable line gets a recorder; `skipped_lines` holds only non-instrumented lines). #17 decides *how* class-level
  lines are recorded, not *whether*.
- **Consequence:** #4 is **not** blocked by #17, including the 5 entries with a class-level executable line (`basic_statements`,
  `static_init`, `typed_annotations`, `class_level`, `autoload_style`).

### Key changes

**Goldens — `tests/corpus/<entry>/expected.metadata.json` ×10**

- One file per success entry: `basic_statements`, `control_flow`, `multiline`, `lambdas`, `static_init`, `typed_annotations`,
  `class_level`, `autoload_style`, `await_coroutines`, `disabled_instrumentation`.
- Five top-level keys in Contract §6 / §7 field order: `contract_version` (`"1.4"`), `line_mappings`, `executable_lines`,
  `skipped_lines`, `functions`.
- Derived from the **corpus default configuration** (Contract §13.3), not the Contract §3 defaults: `include_non_executable = true`, so
  `line_mappings` holds every original line, including `non_executable` ones.
- One `line_mappings` object per line, so a review diff reads line by line against `source.gd`.
- Anonymous lambdas omitted from `functions`, per the FunctionMetadata rules.
- `disabled_instrumentation` is produced under its `config.json` override (`enable_instrumentation = false`). It is identical to
  `basic_statements` except that every `hit_record_inserted` is `false` (lines 5, 8, 9, 10), which is exactly the §3.1 shape: every line
  mapped, no recorder inserted, `executable_lines ∪ skipped_lines` a complete, non-overlapping partition.
- Lines the spec does not classify explicitly (e.g. `extends`, blank lines, some `func` headers such as `class_level` 6 / 9 and
  `static_init` 8) follow the patterns the spec *does* state in `basic_statements` and `control_flow`: `extends` → structural,
  blank / comment → non_executable, `func` header → structural.

| Entry                      | Map (line 1 → n) | `executable_lines` | `skipped_lines`       | `functions`                                         |
|----------------------------|------------------|--------------------|-----------------------|-----------------------------------------------------|
| `basic_statements`         | `NSNNENSEEE`     | 5, 8, 9, 10        | 1, 2, 3, 4, 6, 7      | `_ready` 7–10                                       |
| `control_flow`             | `SNSSESESE`      | 5, 7, 9            | 1, 2, 3, 4, 6, 8      | `test` 3–9                                          |
| `multiline`                | `SNSESE`         | 4, 6               | 1, 2, 3, 5            | `build` 3–6                                         |
| `lambdas`                  | `SNSSEEE`        | 5, 6, 7            | 1, 2, 3, 4            | `run` 3–7 (lambda omitted)                          |
| `static_init`              | `SNENSENSE`      | 3, 6, 9            | 1, 2, 4, 5, 7, 8      | `_static_init` 5–6 (static); `get_counter` 8–9      |
| `typed_annotations`        | `SNENSE`         | 3, 6               | 1, 2, 4, 5            | `_ready` 5–6                                        |
| `class_level`              | `SNSENSENSE`     | 4, 7, 10           | 1, 2, 3, 5, 6, 8, 9   | `get_value` 6–7 (`Inner`); `make` 9–10              |
| `autoload_style`           | `SNENSE`         | 3, 6               | 1, 2, 4, 5            | `_ready` 5–6                                        |
| `await_coroutines`         | `SNSEE`          | 4, 5               | 1, 2, 3               | `run` 3–5                                           |
| `disabled_instrumentation` | `NSNNENSEEE`     | 5, 8, 9, 10        | 1, 2, 3, 4, 6, 7      | `_ready` 7–10 (all `hit_record_inserted = false`)   |

E = executable, N = non_executable, S = structural.

**Validation suite — `tests/unit/test_corpus_metadata.gd` (new, 13 tests, parameterized over the 10 entries)**

- Golden exists and parses; LF only, exactly one final newline; exact top-level keys; `contract_version == "1.4"`.
- One mapping per source line, in order, with exact mapping keys (enforces the corpus default `include_non_executable = true`, merged
  with the entry's `config.json`).
- Classifications equal a hand-written per-line table (`CLASS_MAP`).
- `executable_lines` and `skipped_lines` are **each checked against their own literal table**, not only inferred from `line_mappings`
  (AC #5 / #6), plus a separate check that both lists agree with `line_mappings`.
- Partition invariant: the two lists are disjoint, sorted, and their union is exactly `1..n`.
- `hit_record_inserted == enable_instrumentation && executable` for every line.
- `functions` equals the spec's own **Expected FunctionMetadata** JSON block, parsed straight from
  `docs/seed-corpus-specification-v*.md` (`disabled_instrumentation` compared with `basic_statements`' block).
- Function ranges fit the source: `start_line` is the `func` / `static func` header, `is_static` matches the header, the header is
  classified structural, the body is indented under it, and `end_line` is the last non-blank body line.
- `disabled_instrumentation` differs from `basic_statements` only in the hit flags, and `basic_statements` inserts at least one recorder,
  so the two goldens can never silently become identical.
- Line numbers must be whole JSON numbers ≥ 1. Godot parses every JSON number as a float, and `int()` would silently accept `"3"` or `6.5`;
  `_assert_line_number` now rejects both (Sourcery finding, `fb667f3`).
- Mutation-checked on Godot 4.7.1: a wrong `end_line`, a dropped executable line, a `disabled_instrumentation` copied from
  `basic_statements`, a string `original_line`, a fractional `start_line` and a string inside `executable_lines` all fail the suite.

**JSON linting in CI**

- `.github/workflows/jsonlint.yml` (new): reusable workflow, pinned `actions/checkout` / `actions/setup-python` SHAs, no third-party lint
  action and no pip install.
- `workspace/json_lint.py` (new, standard library only): lints every tracked `*.json` except `.godot/`, `addons/`, `contrib/`:
  - strict JSON: no duplicate keys, no `NaN` / `Infinity`, no trailing commas;
  - UTF-8 without BOM, LF only, no trailing whitespace, exactly one final newline;
  - layout deliberately **not** enforced, so the one-mapping-per-line goldens are not reflowed;
  - errors emitted as `::error` annotations, shown inline on the PR diff.
- Verified to flag all 10 goldens on `8677b3f` (missing final newline) and to pass all 12 tracked JSON files on the branch head.
- `workspace/run_json_lint.sh` (new): local runner, matching `run_yaml_lint.sh`.
- `lint_test_on_pull.yml`: new `json` path filter and `jsonlint` job; `gut_tests` now also needs `jsonlint`. The filter includes the linter,
  its workflow and the orchestrator itself, and `gut_workflow` now also matches the orchestrator, so a PR that only edits the pipeline wiring
  still runs JSON lint and GUT (Sourcery finding, `8e3e56a`).
- `lint_test_deploy.yml`: `jsonlint` job added; `gut_tests` needs it.

**Repository protections**

- `.gitattributes`: `tests/corpus/** text eol=lf` widened to `* text=auto eol=lf`, with images, fonts and binary Godot resources marked
  `binary`. A Windows clone with `core.autocrlf=true` had checked the goldens **and** the spec out with CRLF, which failed the newline check
  and made the spec parser find no FunctionMetadata blocks.
- `contrib/.gdignore` (new): keeps Godot from scanning the GUT submodule copy (`contrib/Gut/addons/gut`), which declared a second
  `class_name GutUtils` and broke the editor's GUT plugin.
- `594756d`: final newline added to all 10 goldens. `bc26e5c`: removed a stray `contrib/.gdignor` added by typo in `353e190`.

### Files touched (high level)

| Area   | Files                                                                                                                       |
|--------|-----------------------------------------------------------------------------------------------------------------------------|
| Corpus | `tests/corpus/<entry>/expected.metadata.json` ×10                                                                           |
| Tests  | `tests/unit/test_corpus_metadata.gd` (+ `.uid`)                                                                             |
| CI     | `.github/workflows/jsonlint.yml` (new), `.github/workflows/lint_test_on_pull.yml`, `.github/workflows/lint_test_deploy.yml` |
| Tools  | `workspace/json_lint.py`, `workspace/run_json_lint.sh`                                                                      |
| Repo   | `.gitattributes`, `contrib/.gdignore`                                                                                       |

All commits were made by @ikostan. The goldens, the validation suite, the JSON linter and its workflow wiring, and the Sourcery fixes were
drafted by @claude (Opus 5.5) and handed over as files and snippets; see *Bot & AI Contributions*.

### CI

On `fb667f3`: all checks passed — 7 successful, 1 skipped.

Locally (Godot 4.7.1 stable, GUT 9.7.0): `test_corpus_metadata.gd` 13 / 13; full suite 52 / 52; `gdformat --check` and `gdlint` clean;
`yamllint` with `.yamllint.yaml` reports no errors (one pre-existing line-length warning in `lint_test_on_pull.yml`).

### Status

Ready to merge. Addresses every acceptance criterion of #4, with the classification gaps noted under *Follow-ups*. Unblocks #5
(`expected.error.json` goldens), which #4 blocks.

### Follow-ups

- **#4 housekeeping:** post the reading (b) scope decision on #4 itself and remove the conditional #17 dependency from its *Blocked By*
  list, so AC #8 is recorded on the issue, not only here.
- **Confirm the inferred classifications** (`extends`, blank lines, `class_level` 6 / 9, `static_init` 8) on #4, or add a "lines not
  listed follow…" rule to the spec's *General classification rules*.
- **Cross-artifact check when #28 lands:** derive `instrumented_lines` from `expected.instrumented.gd` and assert recorder lines appear
  exactly where these goldens have `hit_record_inserted = true`.
- **Contract §9.1:** state that a file's final `\n` terminates its last line rather than starting an empty one; every corpus source ends in
  `\n`, and a literal `split("\n")` yields one extra element.
- **#17's title** still says "publish Contract v1.4"; v1.4 was taken by #37, so #17 will need v1.5.
- **`update_addons.sh` is not idempotent:** `cp -R contrib/Gut/addons/gut addons` creates a nested `addons/gut/gut/` when `addons/gut/`
  already exists, giving duplicate UIDs and a second `GutUtils`. Fix: `rm -rf addons/gut` before the copy.
- **Two ignore files:** the repo tracks both `.gitignore` and a dotless `gitignore`; the latter adds only `/.venv` and `/.py_venv`. Move
  those two lines into `.gitignore` and delete `gitignore`.
- **`lint_test_on_pull.yml` (pre-existing):** outputs `python_tests` and `ci` have no matching filter, and `detect-changes` uses
  `actions/checkout` by tag rather than a pinned SHA.

---

## Reviewer's Guide

This PR adds hand-derived, classification-only `expected.metadata.json` goldens for the 10 success entries, a GUT suite that checks them
against independent hand-written tables and the spec's own FunctionMetadata blocks, a strict standard-library JSON linter that runs
locally (`workspace/run_json_lint.sh`) and in both pipelines, and repository-wide LF enforcement plus a Godot ignore marker for the GUT
submodule.

### File-Level Changes

| Change                                                                              | Details                                                                                                                                                                                                                                                                                                                                                                                                                        | Files                                                                                                                                                                                     |
|-------------------------------------------------------------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Adds classification-only metadata goldens for all 10 success entries.               | <ul><li>Per-line classification and `hit_record_inserted` for every original line (corpus default `include_non_executable = true`).</li><li>`executable_lines` / `skipped_lines` partition and FunctionMetadata per the spec.</li><li>`instrumented_lines` intentionally omitted (reading (b); owned by #28 after #17).</li><li>`disabled_instrumentation` differs from `basic_statements` only in hit flags (§3.1).</li></ul> | `tests/corpus/<entry>/expected.metadata.json`                                                                                                                                             |
| Adds a GUT suite that validates the goldens independently of how they were written. | <ul><li>Literal per-entry tables for classifications, executable and skipped lines.</li><li>Partition, list/mapping agreement, hit-flag and config-merge checks.</li><li>FunctionMetadata compared with the spec's JSON blocks; ranges checked against the source's indentation.</li><li>Line numbers must be whole JSON numbers ≥ 1.</li></ul>                                                                                | `tests/unit/test_corpus_metadata.gd`<br/>`tests/unit/test_corpus_metadata.gd.uid`                                                                                                         |
| Adds strict JSON linting to both pipelines.                                         | <ul><li>Standard-library checker: strict JSON, UTF-8 without BOM, LF, no trailing whitespace, one final newline; layout not enforced.</li><li>Reusable `jsonlint.yml` with pinned actions; path-filtered job on PRs, always on `main`.</li><li>`gut_tests` gated on `jsonlint`; orchestrator edits now trigger JSON lint and GUT.</li></ul>                                                                                    | `.github/workflows/jsonlint.yml`<br/>`.github/workflows/lint_test_on_pull.yml`<br/>`.github/workflows/lint_test_deploy.yml`<br/>`workspace/json_lint.py`<br/>`workspace/run_json_lint.sh` |
| Enforces LF repository-wide and hides the GUT submodule from Godot.                 | <ul><li>`* text=auto eol=lf` with binary assets marked `binary`.</li><li>`contrib/.gdignore` prevents a second `class_name GutUtils` from the submodule copy.</li></ul>                                                                                                                                                                                                                                                        | `.gitattributes`<br/>`contrib/.gdignore`                                                                                                                                                  |

### Assessment against linked issues

| Issue                                                                  | Objective                                                                                                                            | Addressed | Explanation                                                                                                                      |
|------------------------------------------------------------------------|--------------------------------------------------------------------------------------------------------------------------------------|-----------|----------------------------------------------------------------------------------------------------------------------------------|
| [#4](https://github.com/ikostan/godot-code-coverage-cli-tool/issues/4) | `expected.metadata.json` exists in the per-entry directory of all 10 success entries, including `disabled_instrumentation`.          | ✅        | 10 files; `test_golden_exists_and_parses`.                                                                                       |
| [#4](https://github.com/ikostan/godot-code-coverage-cli-tool/issues/4) | `disabled_instrumentation` asserts the §3.1 shape under its `config.json` override and is verified distinct from `basic_statements`. | ✅        | All hit flags `false`, partition invariant; `test_disabled_golden_differs_from_basic_only_in_hit_flags`.                         |
| [#4](https://github.com/ikostan/godot-code-coverage-cli-tool/issues/4) | Every golden reflects the corpus default configuration, overridden only by the entry's `config.json`.                                | ✅        | Every line mapped (`include_non_executable = true`); config merged in the suite.                                                 |
| [#4](https://github.com/ikostan/godot-code-coverage-cli-tool/issues/4) | Every classification decision matches the spec unconditionally.                                                                      | ⚠️        | All explicit spec classifications match; lines the spec leaves unlisted follow its stated patterns and await confirmation on #4. |
| [#4](https://github.com/ikostan/godot-code-coverage-cli-tool/issues/4) | `executable_lines` is correct and complete, verified as its own check.                                                               | ✅        | Literal `EXECUTABLE` table; `test_executable_lines_match_spec`.                                                                  |
| [#4](https://github.com/ikostan/godot-code-coverage-cli-tool/issues/4) | `skipped_lines` is correct and complete, verified as its own check.                                                                  | ✅        | Literal `SKIPPED` table; `test_skipped_lines_match_spec`.                                                                        |
| [#4](https://github.com/ikostan/godot-code-coverage-cli-tool/issues/4) | Line numbers in every FunctionMetadata entry match the literal source blocks.                                                        | ✅        | Compared with the spec's own JSON blocks and checked against `source.gd` indentation.                                            |
| [#4](https://github.com/ikostan/godot-code-coverage-cli-tool/issues/4) | The `instrumented_lines` scope question is resolved and documented before the 5 class-level entries are drafted.                     | ⚠️        | Reading (b), documented in the suite header and this summary; still to be recorded on #4 with #17 removed from *Blocked By*.     |

---

## Bot & AI Contributions to PR #43

This pull request received automated assistance from bots and AI tools for drafting, verification, code review, summaries, and quality
workflows.

### @claude (Opus 5.5)

- Reviewed issue #4 against Contract v1.4, Seed Corpus Spec v1.5 and the corpus sources, and recommended the classification-only scope
  (reading (b)).
- Drafted the 10 goldens and the validation suite, and verified them on headless Godot 4.7.1 / GUT 9.7.0.
- Designed and drafted the JSON linter and its CI wiring.
- Reviewed the pushed PR, assessed the bot findings, and drafted the fixes and replies.
- Helped resolve local environment issues (line endings, GUT plugin setup) and the Qodo integration.
- All work was handed to @ikostan as files and snippets; no commits were pushed by Claude.

### @sourcery-ai

- Generated the **Summary by Sourcery** in the PR description and the **Reviewer's Guide**.
- Updated the Reviewer's Guide for the final head: three file-level groups (goldens, validation suite, JSON lint) and all three of its #4
  objectives marked ✅ (goldens for the 10 entries, the `disabled_instrumentation` partition, the explicit `instrumented_lines` scope
  decision). Three of its claims were not adopted in this summary:
  - it describes the `.gitattributes` change as configuring the golden JSON files; it is the repository-wide LF rule, added for Windows
    CRLF checkouts;
  - it calls JSON lint a required CI gate; on PRs it is path-filtered, and only `gut_tests` depends on it not failing;
  - it lists the PR as completing "Epic Task 2"; #4 is one task of Epic #2, which still has open tasks (#5, #6, #7, #28, #29).

  It also omits `contrib/.gdignore`, and its ✅ for the scope decision does not reflect that the decision is not yet recorded on #4 (see
  *Assessment against linked issues*).
- First review on `8677b3f`: no issues found.
- Second review: 4 blocking findings (Medium), "Approval pending":
  - `lint_test_on_pull.yml:119` — *Orchestrator changes skip CI*. **Fixed** in `8e3e56a` (the orchestrator now triggers JSON lint and GUT).
    Partly inaccurate: YAML lint already ran on such PRs.
  - `test_corpus_metadata.gd:119` (+ 314–315) — *Invalid line numbers pass checks*. **Fixed** in `fb667f3` (`_assert_line_number`).
  - `test_corpus_metadata.gd:23` — *Line mappings lack required coordinates* (`instrumented_lines`). **Declined**: reading (b) on #4;
    owned by #28 after #17.
  - `test_corpus_metadata.gd:53` — *Classification changes pass unnoticed* (hard-coded `CLASS_MAP`). **Declined**: AC #5 / #6 require
    independent hand-derived checks; deriving them from rules would reimplement the M2 classifier inside the test; source drift is already
    caught by `test_corpus_spec_sync.gd`.

### @qodo-code-review

- First Qodo activity on this repository. The GitHub app had repository access but never responded (also silent on #41); responses began
  after the repository was installed from the qodo.ai side (code review on, connection healthy, PR history indexing active).
- Acknowledged `/review` with 👀 and posted "Qodo is busy working".
- TODO: record the review outcome and any findings once posted.

### @coderabbitai

- Posted its review status comment (CHILL profile, Advanced plan).
- TODO: record the outcome if a review is posted. On the previous PR (#41) it reported its review limit reached.

### @deepsource-io

- **DeepSource Code Review** integration is part of the project's quality tooling set.
- No DeepSource review comment or Report Card was observed on this PR's timeline. Included for complete contributor recognition as
  requested.

### @codecov

- **Codecov** coverage reporting is part of the expected CI quality stack for this project.
- No Codecov Report comment was observed on this PR's timeline (coverage reporting may not be configured yet). Included for complete
  contributor recognition as requested.

### @dependabot

- Standard dependency-management bot integration present in the repository workflow.
- No direct commits or comments observed on this PR; included for complete contributor recognition as requested.

---

## Human Contributor

### @ikostan

- Primary author and owner of the PR and of issue #4, including the scope question and acceptance criteria the PR follows.
- Authored and committed all 10 commits, applying and adjusting the drafted goldens, tests, JSON lint and fixes.
- Set up the local Godot / GUT environment on Windows, and the Qodo installation on both GitHub and qodo.ai.
- Triggered and triaged the bot reviews, replied to and resolved the review threads.
- Self-assigned the PR, added the `task` label, linked issue #4, and added the PR to Milestone 1 and the project board.

---
<!-- markdownlint-enable MD001 MD036 MD013 MD033 table-column-style -->
