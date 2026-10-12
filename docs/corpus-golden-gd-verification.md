# Golden `.gd` Files Inside the Godot Project: Verification
<!-- markdownlint-disable MD010 MD013 table-column-style -->

**Issue:** #38 §6 ("Golden `.gd` files inside the Godot project")
**Date:** 2026-10-11
**Environment:** Godot 4.7.1 stable (`4.7.1.stable.official.a13da4feb`, the version pinned in `gut_tests.yml`), headless, Linux; GUT 9.7.0; gdtoolkit 4.5.0 via `check.sh`.
**Corpus state:** per-entry layout from #38 (12 entries under `tests/corpus/<entry>/`).

## Question

`expected.instrumented.gd` goldens (Contract v1.4 §13.1) will live beside
`source.gd` inside the Godot project tree, and they call
`__coverage_hit(...)`, which is not defined anywhere. A `.gdignore` on the
corpus is not an option, because the GUT suites `preload` the sources. Does
a golden like this break Godot's import, the GUT suite, or `check.sh`?

## Method

A placeholder golden was added temporarily (not committed):
`tests/corpus/basic_statements/expected.instrumented.gd`, a copy of
`basic_statements/source.gd` with one recorder line inserted:

```gdscript
func _ready() -> void:
	__coverage_hit(8)
	var x = 1
```

With the placeholder present, the following were run:

| # | Check | Command |
|---|-------|---------|
| 1 | Editor import / filesystem scan, from a clean cache (`.godot/` deleted first) | `godot --headless --path . --import` |
| 2 | Full GUT suite, with the exact CI flags | `godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests -ginclude_subdirs -gexit -gexit_on_success -glog=3 -gjunit_xml_file=res://test_results.xml` |
| 3 | Lint and format | `bash check.sh` |
| 4 | Read as text vs. load as a script | A throwaway `SceneTree` script calling `FileAccess.get_file_as_string()` and then `load()` on the golden |

## Results

| # | Check | Result |
|---|-------|--------|
| 1 | Import / scan | ✅ Exit 0. No error or warning mentions the golden or `__coverage_hit`. |
| 2 | GUT suite | ✅ Exit 0, 39/39 tests passing. GUT only collects `test_*.gd` scripts, so the golden is never loaded. |
| 3 | `check.sh` | ✅ Lint and format clean. 13 files processed, none under `tests/corpus/` (excluded by `.gdcheckignore`). |
| 4 | Read as text | ✅ `FileAccess.get_file_as_string()` returns the full file (147 bytes). |
| 4 | Load as a script | ❌ `Parse Error: Function "__coverage_hit()" not found in base self.`, as expected. |

## Conclusion

Godot reports the missing recorder function only when a golden is
**loaded as a script**, not during import, filesystem scan, GUT collection,
or linting. Golden `.gd` files can live in `tests/corpus/<entry>/` as
specified. **No fallback is needed**: neither an `expected/` subdirectory
with a `.gdignore`, nor a non-`.gd` extension (which would have required a
contract amendment).

The constraint this leaves for the harness: goldens must be **read as
text** (`FileAccess`) and compared, never `load()`ed or `preload()`ed.

## `.uid` sidecars for goldens

The import in check 1 generated
`tests/corpus/basic_statements/expected.instrumented.gd.uid`. Goldens are
never loaded, so nothing refers to them by UID.

**Open decision for #6 / #28** (the tasks that write real goldens):
commit these sidecars, or ignore them. Ignoring them is recommended, to
avoid UID churn on files that are never loaded:

```gitignore
tests/corpus/**/expected.*.gd.uid
```

<!-- markdownlint-enable MD010 MD013 table-column-style -->
