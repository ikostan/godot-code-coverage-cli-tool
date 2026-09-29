# Add Godot coverage corpus fixtures
<!-- markdownlint-disable MD001 MD036 MD013 MD033 table-column-style -->

This change adds a corpus of sample GDScript files for coverage 
testing, covering autoloads, coroutine awaits, control flow, 
lambdas, typed annotations, multiline expressions, static 
initialization, class scopes, and edge cases. It also updates 
scene metadata with unique IDs and removes redundant load_steps 
entries from the default environment and scene files.

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

<!-- markdownlint-enable MD001 MD036 MD013 MD033 table-column-style -->
