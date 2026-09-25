**Seed Corpus Specification v1.4**
*(Final – ready for materialization)*

Both issues from v1.3 are corrected: line numbers have been re-counted against the literal source blocks, and Sub-case A now uses a construct that genuinely defeats a line-oriented stateful analyzer, with the failure mechanism named explicitly.

### Common conventions

- Line numbers are 1-based.
- All sources use Unix line endings (`\n` only).
- Default configuration (unless overridden):
  ```
  enable_instrumentation = true
  include_non_executable = true
  emit_function_metadata = true
  hit_recorder_expression = "__coverage_hit({line})"
  ```
- Success entries → Contract §13.1 artifacts.
- Expected-failure entries → Contract §13.2 artifacts.

**General classification rules**
- Declaration **with initializer** → `executable`
- Bare declaration **without initializer** → `non_executable`
- Lambda **definition line** → `structural`; lambda **body lines** → `executable`

**FunctionMetadata rules**
- Only named functions/methods appear.
- Anonymous lambdas are omitted.
- `class_scope` = nearest enclosing class name, or `""` for top-level.
- `is_static` = `true` only for functions declared `static`.
- `start_line` / `end_line` = original header line and last body line.

---

### Required Entries

#### 1. `basic_statements.gd`
**Pipeline**: Success

```gdscript
# basic_statements.gd
extends Node

var bare: int
var initialized: int = 1

func _ready() -> void:
	var x = 1
	x += 1
	print(x)
```

**Line map** (1-based):
1: comment, 2: extends, 3: blank, 4: bare, 5: initialized, 6: blank, 7: func _ready, 8: var x, 9: x += 1, 10: print(x)

**Mandatory classifications**:
- 1 → non_executable (comment)
- 2 → structural
- 3 → non_executable
- 4 → non_executable (bare declaration)
- 5 → executable
- 6 → non_executable
- 7 → structural
- 8–10 → executable

**Expected FunctionMetadata**:
```json
[
  {
    "name": "_ready",
    "start_line": 7,
    "end_line": 10,
    "class_scope": "",
    "is_static": false
  }
]
```

---

#### 2. `control_flow.gd`
**Pipeline**: Success

```gdscript
extends Node

func test(v: int) -> int:
	if v > 0:
		return v * 2
	elif v < 0:
		return -v
	else:
		return 0
```

**Line map**:
1: extends, 2: blank, 3: func test, 4: if, 5: return, 6: elif, 7: return, 8: else, 9: return

**Mandatory classifications**:
- 1 → structural
- 2 → non_executable
- 3 → structural
- 4, 6, 8 → structural
- 5, 7, 9 → executable

**Expected FunctionMetadata**:
```json
[
  {
    "name": "test",
    "start_line": 3,
    "end_line": 9,
    "class_scope": "",
    "is_static": false
  }
]
```

---

#### 3. `multiline.gd`
**Pipeline**: Success

```gdscript
extends Node

func build() -> String:
	var s = "hello " + \
		"world"
	return s
```

**Line map**: 1 extends, 2 blank, 3 func, 4 assignment start, 5 continuation, 6 return

**Mandatory classifications**:
- 5 → structural (backslash continuation)
- 4, 6 → executable

**Expected FunctionMetadata**:
```json
[
  {
    "name": "build",
    "start_line": 3,
    "end_line": 6,
    "class_scope": "",
    "is_static": false
  }
]
```

> Implicit continuation inside open brackets is deferred to the `bracket_continuation.gd` stretch entry. Only the explicit `\` form is required for the seed corpus.

---

#### 4. `lambdas.gd`
**Pipeline**: Success

```gdscript
extends Node

func run() -> void:
	var f = func(x: int) -> int:
		return x + 1
	var result = f.call(10)
	print(result)
```

**Mandatory classifications** (unconditional rule):
- Lambda definition line (`var f = func(...) -> ...:`) → structural
- Lambda body (`return x + 1`) → executable
- `var result = f.call(10)` → executable
- `print(result)` → executable

**Expected FunctionMetadata**:
```json
[
  {
    "name": "run",
    "start_line": 3,
    "end_line": 7,
    "class_scope": "",
    "is_static": false
  }
]
```
*(Anonymous lambda is intentionally omitted from `functions`.)*

---

#### 5. `static_init.gd`
**Pipeline**: Success

```gdscript
extends Node

static var counter: int = 0

static func _static_init() -> void:
	counter = 42

func get_counter() -> int:
	return counter
```

**Mandatory classifications**:
- `static var counter: int = 0` → executable (initializer present)
- `static func _static_init() -> void:` → structural
- Body of `_static_init` → executable
- Ordinary method body → executable

**Expected FunctionMetadata**:
```json
[
  {
    "name": "_static_init",
    "start_line": 5,
    "end_line": 6,
    "class_scope": "",
    "is_static": true
  },
  {
    "name": "get_counter",
    "start_line": 8,
    "end_line": 9,
    "class_scope": "",
    "is_static": false
  }
]
```

---

#### 6. `typed_annotations.gd`
**Pipeline**: Success

```gdscript
extends Node

@onready var label: Label = $Label

func _ready() -> void:
	label.text = "ok"
```

**Mandatory classifications**:
- `@onready var label: Label = $Label` → executable (the annotation only affects timing, not executability)
- `func _ready() -> void:` → structural
- `label.text = "ok"` → executable

**Expected FunctionMetadata**:
```json
[
  {
    "name": "_ready",
    "start_line": 5,
    "end_line": 6,
    "class_scope": "",
    "is_static": false
  }
]
```

---

#### 7. `class_level.gd`
**Pipeline**: Success

```gdscript
extends Node

class Inner:
	var value: int = 7

	func get_value() -> int:
		return value

func make() -> Inner:
	return Inner.new()
```

**Mandatory classifications**:
- `class Inner:` → structural
- `var value: int = 7` → executable (initializer present)
- Nested method bodies → executable
- Outer method body → executable

**Expected FunctionMetadata**:
```json
[
  {
    "name": "get_value",
    "start_line": 6,
    "end_line": 7,
    "class_scope": "Inner",
    "is_static": false
  },
  {
    "name": "make",
    "start_line": 9,
    "end_line": 10,
    "class_scope": "",
    "is_static": false
  }
]
```

---

#### 8. `autoload_style.gd`
**Pipeline**: Success

```gdscript
extends Node

var ready_called := false

func _ready() -> void:
	ready_called = true
```

**Mandatory classifications**:
- `var ready_called := false` → executable
- `_ready` header → structural
- Body → executable

**Expected FunctionMetadata**:
```json
[
  {
    "name": "_ready",
    "start_line": 5,
    "end_line": 6,
    "class_scope": "",
    "is_static": false
  }
]
```

---

#### 9. `await_coroutines.gd`
**Pipeline**: Success
**Primary obligations**: coroutine / `await` semantic preservation (§11)

```gdscript
extends Node

func run() -> void:
	await get_tree().process_frame
	print("resumed")
```

**Mandatory classifications**:
- `await get_tree().process_frame` → executable
- `print("resumed")` → executable
- Function header → structural

**Runtime exercise note**: This entry requires a live, ticking `SceneTree` (frame boundary). It is expected to be the heaviest / most environment-sensitive test in the seed suite and should be budgeted accordingly in CI. The exercise must confirm the hit on the `await` line is recorded before suspension and the subsequent line is recorded after resumption, without breaking the coroutine.

**Expected FunctionMetadata**:
```json
[
  {
    "name": "run",
    "start_line": 3,
    "end_line": 5,
    "class_scope": "",
    "is_static": false
  }
]
```

---

#### 10. `disabled_instrumentation.gd`
**Pipeline**: Success (`enable_instrumentation = false`)
**Primary obligations**: §3.1 mandatory shape + partition invariant

Source identical to `basic_statements.gd`.
Configuration override: `enable_instrumentation = false`.

**Golden assertions** (mandatory):
- `instrumented_source` == original source
- Every line appears in `line_mappings` with `hit_record_inserted = false`
- `executable_lines` ∪ `skipped_lines` is a complete, non-overlapping partition of all original lines
- `functions` is still emitted according to the FunctionMetadata rules above

---

#### 11. `edge_cases.gd` (two sub-cases)
**Pipeline**: Expected-failure
**Primary obligations**: fail-closed behaviour

**Sub-case A – unsupported construct (concrete & justified)**

```gdscript
extends Node

func broken(v: int) -> int:
	return v if true else (func():
		return 1
	).call()
```

**Failure mechanism (named)**:
The analyzer's indentation-based block tracker cannot distinguish the dedent that closes the lambda body from the dedent that closes the enclosing ternary's parenthetical continuation, because both the lambda's final statement and the `.call()` that terminates the outer expression occur in a way that leaves the indentation state machine unable to decide whether it is still inside the lambda or has returned to the ternary. A purely line-oriented stateful analyzer without a full expression parser has no reliable way to resolve this ambiguity and must therefore refuse to transform the file.

> **Note for future revision**: If bracket-continuation support (see `bracket_continuation.gd` stretch entry) is later implemented with an independent paren-depth counter, this construct's unclassifiability should be re-validated — a more sophisticated tracker might resolve it correctly, in which case this sub-case would need a replacement construct.

`expected.error.json` asserts `UNSUPPORTED_SYNTAX` at the line containing the nested lambda definition (exact line number fixed when the file is written).

**Sub-case B – invalid configuration**

Any valid source, but with an empty or unknown-placeholder `hit_recorder_expression`.
`expected.error.json` asserts:
```json
{
  "status": "INVALID_CONFIGURATION",
  "original_line": -1,
  "reason": "..."
}
```

---

### Intentional Scope Reduction

`already_loaded.gd` (pre-load vs reload behaviour) remains **intentionally deferred** from the seed corpus. It exercises higher-layer loading strategy rather than the pure instrumentor and will be added when the runtime collector / pre-load path is implemented. This is an explicit scope cut, not an oversight.

---

### Stretch / Later Entries

- `signals.gd` – signal connection / emission preservation
- `bracket_continuation.gd` – implicit multiline continuation inside `()`, `[]`, `{}`
- `match_patterns.gd` – complex `match`
- `already_loaded.gd` – pre-load vs reload (higher layer)

---

### Acceptance Criteria

- All 11 required entries pass their declared pipeline.
- Every classification decision is unconditional and baked into the golden metadata.
- Line numbers in every `FunctionMetadata` entry match the literal source blocks above.
- The bare-declaration rule is tested in `basic_statements.gd`.
- `await_coroutines.gd` is required, satisfying the §11 coroutine guarantee, and its heavier runtime cost is acknowledged.
- Sub-case A of `edge_cases.gd` uses a construct whose failure mode is a named limitation of the line-oriented indentation/block tracker.
- The `INVALID_CONFIGURATION` sub-case proves `original_line == -1`.
- All sources and goldens use Unix line endings only.

The corpus is now fully determined and free of the previously identified arithmetic and justification errors. Ready to materialize the directory structure and concrete skeleton files under `tests/corpus/`.
