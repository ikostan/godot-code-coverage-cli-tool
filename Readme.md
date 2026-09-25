# Godot Code Coverage CLI Tool

> Originally forked from [jamie-pate/godot-code-coverage](https://github.com/jamie-pate/godot-code-coverage). This project is being rearchitected from a runtime GDScript coverage addon into a **pure-source CLI instrumentor** for Godot 4.x. See [Status](#status) below.

## What this is becoming

The legacy tool worked by instrumenting scripts at runtime: a `Coverage` singleton hooked into the live `SceneTree`, monitored node instantiation, and reloaded scripts in place to inject hit-tracking code. That approach required a running Godot process, GUT/GdUnit4 test-runner hooks, and tight coupling to scene-tree state.

This project is moving to a different model: a **pure function** that takes GDScript source text in, and returns instrumented source text (or an explicit error) out — with zero dependency on `SceneTree`, autoloads, test runners, or any runtime coverage state. It can be run standalone from the command line against any `.gd` file, independent of whether a Godot project is even running.

The full behavioral contract for this instrumentor is specified in:

- **[`docs/instrumentation-contract-v1.2.md`](docs/instrumentation-contract-v1.2.md)** — the frozen interface: input/output shapes, per-line classification rules (`executable` / `non_executable` / `structural`), determinism guarantees, and the fail-closed principle (the instrumentor refuses to transform code it can't prove is safe, rather than guessing).
- **[`docs/seed-corpus-specification-v1.4.md`](docs/seed-corpus-specification-v1.4.md)** — the golden-test corpus used to validate the instrumentor against the contract, covering classification edge cases (lambdas, static init, `await`, bracket/backslash continuations, class-level code) and fail-closed behavior.

## Status

**Work in progress — the pure-source instrumentor is not yet implemented.** The contract and seed corpus above are locked and implementation-ready; the classifier/transformer itself is the current focus of work.

The old runtime-coupled implementation (`Coverage` singleton, `SceneTree` monitoring, GUT hook scripts, JSON coverage merging) has been removed as part of this migration. If you're looking for that version, see the [original upstream project](https://github.com/jamie-pate/godot-code-coverage) or an earlier commit in this repo's history.

A handful of demo/example GDScript files remain at the project root (`autoload1.gd`, `autoload2.gd`, `other.gd`, `spatial.gd`, etc.) — these are **not usage examples for a working tool**. They're retained temporarily as raw source material for expanding the seed corpus (they contain real examples of lambdas, `match` patterns, signal wiring, and multiline continuations referenced as stretch-corpus candidates in the seed corpus spec) and will be relocated or removed once that corpus work is done.

## Contributing / following along

Since the instrumentor itself is still being built, the most useful things to read right now are the two contract documents linked above — they define exactly what correct behavior looks like before any implementation code lands, per the project's fail-closed design philosophy.

## License

See [LICENSE](LICENSE).
