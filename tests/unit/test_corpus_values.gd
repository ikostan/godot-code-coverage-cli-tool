extends GutTest

const ControlFlow = preload("res://tests/corpus/control_flow.gd")
const ClassLevel = preload("res://tests/corpus/class_level.gd")
const EdgeCases = preload("res://tests/corpus/edge_cases.gd")
const Multiline = preload("res://tests/corpus/multiline.gd")
const StaticInit = preload("res://tests/corpus/static_init.gd")


func test_control_flow_branches_and_boundaries(
	case = use_parameters(
		[
			[0, 0],
			[1, 2],
			[-1, 1],
			[7, 14],
			[-7, 7],
			[2147483648, 4294967296],
			[-2147483648, 2147483648],
		]
	)
):
	var subject = autofree(ControlFlow.new())
	assert_eq(subject.test(case[0]), case[1])


func test_control_flow_does_not_retain_previous_branch_state():
	var subject = autofree(ControlFlow.new())
	assert_eq(subject.test(3), 6)
	assert_eq(subject.test(-4), 4)
	assert_eq(subject.test(0), 0)
	assert_eq(subject.test(3), 6)


func test_multiline_expression_preserves_space_and_is_repeatable():
	var subject = autofree(Multiline.new())
	assert_eq(subject.build(), "hello world")
	assert_eq(subject.build(), "hello world")


func test_inner_class_factory_initializes_value():
	var subject = autofree(ClassLevel.new())
	var inner = subject.make()
	assert_true(inner is ClassLevel.Inner)
	assert_eq(inner.get_value(), 7)


func test_inner_class_factory_returns_independent_instances():
	var subject = autofree(ClassLevel.new())
	var first = subject.make()
	var second = subject.make()
	assert_ne(first, second)
	first.value = -12
	assert_eq(first.get_value(), -12)
	assert_eq(second.get_value(), 7)
	assert_eq(subject.make().get_value(), 7)


func test_static_initializer_runs_on_script_load():
	assert_eq(StaticInit.counter, 42)
	var first = autofree(StaticInit.new())
	var second = autofree(StaticInit.new())
	assert_eq(first.get_counter(), 42)
	assert_eq(second.get_counter(), 42)


func test_new_instance_does_not_reset_shared_static_state():
	var original = StaticInit.counter
	var first = autofree(StaticInit.new())
	StaticInit.counter = -7
	var second = autofree(StaticInit.new())
	var first_value = first.get_counter()
	var second_value = second.get_counter()
	# Restore shared state before asserting so test ordering cannot affect results.
	StaticInit.counter = original
	assert_eq(first_value, -7)
	assert_eq(second_value, -7)


func test_nested_lambda_ternary_returns_input(value = use_parameters([0, 1, -1, 42, -42])):
	# This is unsupported by the planned instrumentor, but is valid GDScript.
	# Zero and negative inputs distinguish the selected branch from the lambda's 1.
	var subject = autofree(EdgeCases.new())
	assert_eq(subject.broken(value), value)
