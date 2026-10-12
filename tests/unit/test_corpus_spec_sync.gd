extends GutTest

# Guards against corpus line drift (#38). Every line map, classification,
# FunctionMetadata range and expected error line in the Seed Corpus
# Specification is only valid if each corpus source is byte-identical to
# its literal `gdscript` block in the spec. This test fails on a single byte
# of difference, in either the corpus or the spec.

const SPEC_DIR = "res://docs"
const SPEC_PREFIX = "seed-corpus-specification-v"
const CORPUS_DIR = "res://tests/corpus"

# Corpus entries checked against the spec. Each is either backed by its own
# `gdscript` block in the spec or listed in COPY_OF.
const ENTRIES = [
	"basic_statements",
	"control_flow",
	"multiline",
	"lambdas",
	"static_init",
	"typed_annotations",
	"class_level",
	"autoload_style",
	"await_coroutines",
	"disabled_instrumentation",
	"edge_cases_unsupported_syntax",
	"edge_cases_invalid_config",
]

# Entries the spec defines as a byte-for-byte copy of another entry's source
# instead of giving them a source block of their own.
const COPY_OF = {
	"disabled_instrumentation": "basic_statements",
	"edge_cases_invalid_config": "basic_statements",
}


func test_spec_file_is_unique():
	assert_eq(
		_spec_files().size(), 1, "expected exactly one %s*.md in %s" % [SPEC_PREFIX, SPEC_DIR]
	)


func test_every_corpus_source_is_byte_identical_to_its_spec_block():
	var blocks = _spec_source_blocks()
	assert_false(blocks.is_empty(), "no source blocks parsed from the spec")
	for entry in ENTRIES:
		var block_entry = COPY_OF.get(entry, entry)
		assert_has(blocks, block_entry, "spec has no source block for " + block_entry)
		if not blocks.has(block_entry):
			continue
		var path = _corpus_path(entry)
		assert_true(FileAccess.file_exists(path), path)
		if not FileAccess.file_exists(path):
			continue
		var expected: PackedByteArray = blocks[block_entry].to_utf8_buffer()
		var actual = FileAccess.get_file_as_bytes(path)
		assert_true(
			actual == expected,
			"%s drifted from the spec: %s" % [path, _first_difference(expected, actual)]
		)


func test_entries_match_spec_and_corpus_directories():
	var expected = _sorted(PackedStringArray(ENTRIES))
	assert_eq(_sorted(_spec_entry_names()), expected, "spec entries vs ENTRIES")
	assert_eq(
		_sorted(DirAccess.get_directories_at(CORPUS_DIR)), expected, "corpus directories vs ENTRIES"
	)


func _corpus_path(entry: String) -> String:
	return "%s/%s/source.gd" % [CORPUS_DIR, entry]


func _sorted(names: PackedStringArray) -> PackedStringArray:
	var copy = names.duplicate()
	copy.sort()
	return copy


# Names of every "#### N. `name.gd`" entry heading in the spec.
func _spec_entry_names() -> PackedStringArray:
	var names = PackedStringArray()
	var files = _spec_files()
	if files.size() != 1:
		return names
	var text = FileAccess.get_file_as_string("%s/%s" % [SPEC_DIR, files[0]])
	var heading = RegEx.create_from_string("(?m)^#### \\d+\\. `([a-z_]+)\\.gd`")
	for match in heading.search_all(text):
		names.append(match.get_string(1))
	return names


func _spec_files() -> PackedStringArray:
	var found = PackedStringArray()
	for file_name in DirAccess.get_files_at(SPEC_DIR):
		if file_name.begins_with(SPEC_PREFIX) and file_name.ends_with(".md"):
			found.append(file_name)
	return found


# Returns {entry name: source text} for every "#### N. `name.gd`" section
# that contains a `gdscript` block. Only the first block of a section counts.
func _spec_source_blocks() -> Dictionary:
	var blocks = {}
	var files = _spec_files()
	if files.size() != 1:
		return blocks
	var text = FileAccess.get_file_as_string("%s/%s" % [SPEC_DIR, files[0]])
	var heading = RegEx.create_from_string("^#### \\d+\\. `([a-z_]+)\\.gd`")
	var entry = ""
	var in_block = false
	var lines = PackedStringArray()
	for line in text.split("\n"):
		if in_block:
			if line == "```":
				blocks[entry] = "\n".join(lines) + "\n"
				in_block = false
				entry = ""
			else:
				lines.append(line)
			continue
		var match = heading.search(line)
		if match:
			entry = match.get_string(1)
		elif line.begins_with("#### "):
			entry = ""
		elif line == "```gdscript" and entry != "" and not blocks.has(entry):
			in_block = true
			lines = PackedStringArray()
	return blocks


func _first_difference(expected: PackedByteArray, actual: PackedByteArray) -> String:
	var expected_lines = expected.get_string_from_utf8().split("\n")
	var actual_lines = actual.get_string_from_utf8().split("\n")
	for i in max(expected_lines.size(), actual_lines.size()):
		var want = expected_lines[i] if i < expected_lines.size() else "<end of file>"
		var got = actual_lines[i] if i < actual_lines.size() else "<end of file>"
		if want != got:
			return (
				"line %d: spec has %s, file has %s"
				% [i + 1, JSON.stringify(want), JSON.stringify(got)]
			)
	return "same lines, different bytes (line endings or encoding)"
