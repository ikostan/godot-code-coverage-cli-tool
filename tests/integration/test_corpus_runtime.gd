extends GutTest

const AutoloadStyle = preload("res://tests/corpus/autoload_style.gd")
const AwaitCoroutines = preload("res://tests/corpus/await_coroutines.gd")
const Lambdas = preload("res://tests/corpus/lambdas.gd")
const TypedAnnotations = preload("res://tests/corpus/typed_annotations.gd")

var declaration_scripts = [
	preload("res://tests/corpus/basic_statements.gd"),
	preload("res://tests/corpus/disabled_instrumentation.gd"),
]
var _capture: OutputCapture


# Observe print-only fixtures without modifying their locked source files.
class OutputCapture:
	extends Logger

	var _messages: Array[String] = []
	var _mutex := Mutex.new()

	func _log_message(message: String, error: bool) -> void:
		if not error:
			_mutex.lock()
			_messages.append(message.strip_edges())
			_mutex.unlock()

	func messages() -> Array[String]:
		_mutex.lock()
		var result: Array[String] = _messages.duplicate()
		_mutex.unlock()
		return result


func after_each() -> void:
	if _capture != null:
		OS.remove_logger(_capture)
		_capture = null


func _start_capture() -> void:
	_capture = OutputCapture.new()
	OS.add_logger(_capture)


func _stop_capture() -> Array[String]:
	OS.remove_logger(_capture)
	var messages := _capture.messages()
	_capture = null
	return messages


func test_ready_statements_print_incremented_local_without_changing_members(
	script = use_parameters(declaration_scripts)
) -> void:
	var fixture = autofree(script.new())
	fixture.bare = -5
	fixture.initialized = 99
	_start_capture()
	add_child(fixture)
	var messages := _stop_capture()
	assert_eq(messages, ["2"])
	assert_eq(fixture.bare, -5)
	assert_eq(fixture.initialized, 99)


func test_lambda_invocation_prints_result_on_each_call() -> void:
	var fixture = autofree(Lambdas.new())
	_start_capture()
	fixture.run()
	fixture.run()
	var messages := _stop_capture()
	assert_eq(messages, ["11", "11"])


func test_autoload_style_ready_runs_only_after_entering_tree() -> void:
	var first = autofree(AutoloadStyle.new())
	var second = autofree(AutoloadStyle.new())
	assert_false(first.ready_called)
	assert_false(second.ready_called)
	add_child(first)
	assert_true(first.ready_called)
	assert_false(second.ready_called, "Readiness is instance-local")
	add_child(second)
	assert_true(second.ready_called)


func test_typed_onready_binds_child_and_overwrites_text_at_ready() -> void:
	var fixture = autofree(TypedAnnotations.new())
	var label := Label.new()
	label.name = "Label"
	label.text = "before ready"
	fixture.add_child(label)
	assert_null(fixture.label, "@onready must not run during construction")
	assert_eq(label.text, "before ready")
	add_child(fixture)
	assert_same(fixture.label, label)
	assert_eq(label.text, "ok")


func test_coroutine_suspends_until_next_frame_and_resumes_once() -> void:
	var fixture = add_child_autofree(AwaitCoroutines.new())
	_start_capture()
	fixture.run()
	var before_frame := _capture.messages()
	await get_tree().process_frame
	var after_frame := _capture.messages()
	await get_tree().process_frame
	var final_messages := _stop_capture()
	assert_eq(before_frame, [], "run() must suspend before printing")
	assert_eq(after_frame, ["resumed"], "run() must resume on the next frame")
	assert_eq(final_messages, ["resumed"], "Completion must not repeat on later frames")


func test_concurrent_coroutine_calls_each_resume_once() -> void:
	var fixture = add_child_autofree(AwaitCoroutines.new())
	_start_capture()
	fixture.run()
	fixture.run()
	var before_frame := _capture.messages()
	await get_tree().process_frame
	var after_frame := _capture.messages()
	await get_tree().process_frame
	var final_messages := _stop_capture()
	assert_eq(before_frame, [])
	assert_eq(after_frame, ["resumed", "resumed"])
	assert_eq(final_messages, ["resumed", "resumed"])


func test_scene_metadata_preserves_loadable_nodes_and_connections() -> void:
	var packed_scene = load("res://spatial.tscn")
	assert_is(packed_scene, PackedScene)
	if not packed_scene is PackedScene:
		return
	# Inspect off-tree so the demo's timer cannot run or quit the test process.
	var scene = autofree(packed_scene.instantiate())
	assert_is(scene, Node3D)
	assert_eq(scene.get_script().resource_path, "res://spatial.gd")
	var label = scene.get_node_or_null("Label")
	var timer = scene.get_node_or_null("Timer")
	assert_is(label, Label)
	assert_is(timer, Timer)
	if label is Label:
		assert_eq(label.text, "InterExtends(Inner((hello world)))")
	if timer is Timer:
		assert_almost_eq(timer.wait_time, 0.1, 0.000001)
		assert_true(timer.one_shot)
		assert_true(timer.autostart)
		assert_true(timer.timeout.is_connected(scene._on_Timer_timeout))


func test_environment_metadata_preserves_sky_subresource() -> void:
	var environment = load("res://default_env.tres")
	assert_is(environment, Environment)
	if environment is Environment:
		assert_is(environment.sky, Sky)
