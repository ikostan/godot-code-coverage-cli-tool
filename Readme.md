# Godot Code Coverage CLI Tool

![Godot 4.x](https://img.shields.io/badge/Godot-4.x-blue?style=flat-square&logo=godotengine)
![Status: WIP](https://img.shields.io/badge/Status-WIP-orange?style=flat-square)
![License](https://img.shields.io/badge/License-MIT-green?style=flat-square)

> Originally forked from [jamie-pate/godot-code-coverage](https://github.com/jamie-pate/godot-code-coverage). This project is being rearchitected from a runtime GDScript coverage addon into a **pure-source CLI instrumentor** for Godot 4.x. See [Status & Roadmap](#status--roadmap) below.

## What this is becoming

The legacy tool worked by instrumenting scripts at runtime: a `Coverage` singleton hooked into the live `SceneTree`, monitored node instantiation, and reloaded scripts in place to inject hit-tracking code. That approach required a running Godot process, GUT/GdUnit4 test-runner hooks, and tight coupling to scene-tree state.

This project is moving to a different model: a **pure function** that takes GDScript source text in, and returns instrumented source text (or an explicit error) out — with zero dependency on `SceneTree`, autoloads, test runners, or any runtime coverage state. It can be run standalone from the command line against any `.gd` file, independent of whether a Godot project is even running. Ultimately, this enables seamless CI/CD integration (e.g., GitHub Actions, Codecov) to generate standard LCOV/HTML reports for pull request checks.

### Core Design Principles
- **Pure Function Architecture**: Zero runtime dependencies for the static instrumentation phase[cite: 1].
- **Fail-Closed**: The instrumentor refuses to transform code it cannot definitively prove is safe, rather than guessing or producing plausible but incorrect coverage[cite: 1].
- **LCOV-Canonical**: Built from the ground up to output standard data shapes.
- **Original-Line Coordinates**: All coverage reporting maps strictly back to the original source line numbers[cite: 1].

The full behavioral contract for this instrumentor is specified in:

- **[`docs/instrumentation-contract-v1.2.md`](docs/instrumentation-contract-v1.2.md)** — the frozen interface: input/output shapes, per-line classification rules (`executable` / `non_executable` / `structural`), determinism guarantees, and the fail-closed principle[cite: 1].
- **[`docs/seed-corpus-specification-v1.4.md`](docs/seed-corpus-specification-v1.4.md)** — the golden-test corpus used to validate the instrumentor against the contract, serving as the strict acceptance test suite for Phase 1[cite: 2].

## Future Usage (Mockup)

*Note: The exact CLI command surface is illustrative and not yet finalized.*

Once implemented, the CLI will allow for headless execution directly from your terminal or CI pipeline:

```bash
# Example: Instrumenting a single file
godot --headless -s addons/coverage/cli.gd instrument src/player.gd

# Example: Generating an LCOV report for the test suite
godot --headless -s addons/coverage/cli.gd run-tests --export-lcov=coverage.info

```

## Status & Roadmap

**Work in progress — the pure-source instrumentor is not yet implemented.**

The Instrumentation Contract v1.2 and Seed Corpus Specification v1.4 are locked and implementation-ready.

* [x] Define pure-source instrumentation contract v1.2
* [x] Lock seed corpus specification v1.4
* [ ] Materialize seed corpus under `tests/corpus/`
* [ ] Implement Source Analyzer / Line Classifier
* [ ] Implement Instrumentation Transformer
* [ ] Implement Runtime Hit Collector + Coverage Data Model
* [ ] Implement LCOV Writer
* [ ] Implement CLI Orchestrator
* [ ] Add test-runner adapters (GUT / GdUnit4)

**Current focus:** materializing the seed corpus and implementing the pure Analyzer + Transformer against it.

A handful of legacy demo `.gd` files remain at the project root. **These are not usage examples.** They are retained temporarily as raw syntax material for expanding the seed corpus and will be removed once Phase 1 is complete.

## Contributing / following along

Since the instrumentor itself is still being built, the most useful things to read right now are the two contract documents linked above — they define exactly what correct behavior looks like before any implementation code lands, per the project's fail-closed design philosophy.

## License

See [LICENSE](https://www.google.com/search?q=./LICENSE&utm_source=gemini).
