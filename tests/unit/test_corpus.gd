extends GutTest

const ControlFlow = preload("res://tests/corpus/control_flow.gd")
const ClassLevel = preload("res://tests/corpus/class_level.gd")
const EdgeCases = preload("res://tests/corpus/edge_cases.gd")
const Multiline = preload("res://tests/corpus/multiline.gd")
const StaticInit = preload("res://tests/corpus/static_init.gd")

var declaration_scripts = [
	preload("res://tests/corpus/basic_statements.gd"),
	preload("res://tests/corpus/disabled_instrumentation.gd"),
]
var branch_cases = [
	[-10, 10],
	[-1, 1],
	[0, 0],
	[1, 2],
	[10, 20],
	# Exercise 64-bit values without overflowing multiplication or negation.
	[2147483648, 4294967296],
	[-2147483649, 2147483649],
]
var identity_values = [-9223372036854775807 - 1, -1, 0, 1, 9223372036854775807]
var _saved_counter: int


func before_each() -> void:
	_saved_counter = StaticInit.counter


func after_each() -> void:
	StaticInit.counter = _saved_counter


func test_declarations_have_distinct_default_and_initialized_values(
	script = use_parameters(declaration_scripts)
) -> void:
	var fixture = autofree(script.new())
	assert_eq(fixture.bare, 0)
	assert_eq(fixture.initialized, 1)


func test_declarations_are_independent_between_instances(
	script = use_parameters(declaration_scripts)
) -> void:
	var first = autofree(script.new())
	first.bare = -5
	first.initialized = 99
	var second = autofree(script.new())
	assert_eq(second.bare, 0)
	assert_eq(second.initialized, 1)
	assert_eq(first.bare, -5)
	assert_eq(first.initialized, 99)


func test_control_flow_branches_and_zero_boundary(case = use_parameters(branch_cases)) -> void:
	var fixture = autofree(ControlFlow.new())
	assert_eq(fixture.test(case[0]), case[1])


func test_multiline_concatenation_preserves_space_and_is_repeatable() -> void:
	var fixture = autofree(Multiline.new())
	assert_eq(fixture.build(), "hello world")
	assert_eq(fixture.build(), "hello world")


func test_inner_class_factory_returns_initialized_inner() -> void:
	var fixture = autofree(ClassLevel.new())
	var inner = fixture.make()
	assert_true(inner is ClassLevel.Inner)
	assert_eq(inner.get_value(), 7)


func test_inner_class_factory_returns_independent_instances() -> void:
	var fixture = autofree(ClassLevel.new())
	var first = fixture.make()
	first.value = -3
	var second = fixture.make()
	assert_ne(first, second)
	assert_eq(first.get_value(), -3)
	assert_eq(second.get_value(), 7)


func test_static_initializer_runs_before_instance_creation() -> void:
	assert_eq(StaticInit.counter, 42)
	var fixture = autofree(StaticInit.new())
	assert_eq(fixture.get_counter(), 42)


func test_static_counter_is_shared_and_not_reset_by_new_instances() -> void:
	var first = autofree(StaticInit.new())
	StaticInit.counter = -7
	var second = autofree(StaticInit.new())
	assert_eq(first.get_counter(), -7)
	assert_eq(second.get_counter(), -7)


func test_nested_lambda_ternary_returns_input(value = use_parameters(identity_values)) -> void:
	# This is valid GDScript; the specification rejects it only for instrumentation.
	var fixture = autofree(EdgeCases.new())
	assert_eq(fixture.broken(value), value)
