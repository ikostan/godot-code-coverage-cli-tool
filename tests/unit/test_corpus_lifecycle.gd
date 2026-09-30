extends GutTest

const AutoloadStyle = preload("res://tests/corpus/autoload_style.gd")
const AwaitCoroutines = preload("res://tests/corpus/await_coroutines.gd")
const Lambdas = preload("res://tests/corpus/lambdas.gd")
const TypedAnnotations = preload("res://tests/corpus/typed_annotations.gd")
const STATEMENT_SCRIPTS = [
	preload("res://tests/corpus/basic_statements.gd"),
	preload("res://tests/corpus/disabled_instrumentation.gd"),
]

var _capture: OutputCapture


# Godot 4.7's Logger observes real print calls without rewriting the locked corpus.
class OutputCapture:
	extends Logger

	var _messages: Array[String] = []
	var _mutex := Mutex.new()

	func _log_message(message: String, error: bool) -> void:
		if not error:
			_mutex.lock()
			_messages.append(message.trim_suffix("\n"))
			_mutex.unlock()

	func snapshot() -> Array[String]:
		_mutex.lock()
		var messages := _messages.duplicate()
		_mutex.unlock()
		return messages


func after_each():
	if _capture != null:
		OS.remove_logger(_capture)
		_capture = null


func test_statement_initializers_and_ready_output(script = use_parameters(STATEMENT_SCRIPTS)):
	var subject = autofree(script.new())
	assert_eq(subject.bare, 0)
	assert_eq(subject.initialized, 1)
	_start_capture()
	add_child(subject)
	var messages = _stop_capture()
	assert_eq(messages, ["2"])
	assert_eq(subject.bare, 0)
	assert_eq(subject.initialized, 1)


func test_statement_members_are_not_shared(script = use_parameters(STATEMENT_SCRIPTS)):
	var first = autofree(script.new())
	first.bare = 19
	first.initialized = -3
	var second = autofree(script.new())
	assert_eq(second.bare, 0)
	assert_eq(second.initialized, 1)


func test_autoload_ready_flag_changes_only_after_entering_tree():
	var subject = autofree(AutoloadStyle.new())
	var unattached = autofree(AutoloadStyle.new())
	assert_false(subject.ready_called)
	add_child(subject)
	assert_true(subject.ready_called)
	assert_false(unattached.ready_called)


func test_onready_resolves_existing_label_and_updates_its_text():
	var subject = autofree(TypedAnnotations.new())
	var label = Label.new()
	label.name = "Label"
	label.text = "before ready"
	subject.add_child(label)
	assert_null(subject.label)
	assert_eq(label.text, "before ready")
	add_child(subject)
	assert_same(subject.label, label)
	assert_eq(label.text, "ok")


func test_onready_uses_each_instances_own_label():
	var first = autofree(TypedAnnotations.new())
	var second = autofree(TypedAnnotations.new())
	for subject in [first, second]:
		var label = Label.new()
		label.name = "Label"
		subject.add_child(label)
		add_child(subject)
	first.label.text = "changed"
	assert_ne(first.label, second.label)
	assert_eq(second.label.text, "ok")


func test_lambda_call_prints_incremented_value_on_each_run():
	var subject = autofree(Lambdas.new())
	_start_capture()
	subject.run()
	subject.run()
	var messages = _stop_capture()
	assert_eq(messages, ["11", "11"])


func test_coroutine_suspends_then_resumes_once():
	var subject = add_child_autofree(AwaitCoroutines.new())
	_start_capture()
	subject.run()
	var before_frame = _capture.snapshot()
	# Bounded waits also fail promptly if the coroutine never resumes.
	await get_tree().process_frame
	var after_frame = _capture.snapshot()
	await get_tree().process_frame
	var after_second_frame = _stop_capture()
	assert_eq(before_frame, [])
	assert_eq(after_frame, ["resumed"])
	assert_eq(after_second_frame, ["resumed"])


func test_concurrent_coroutines_each_resume_once():
	var subject = add_child_autofree(AwaitCoroutines.new())
	_start_capture()
	subject.run()
	subject.run()
	var before_frame = _capture.snapshot()
	await get_tree().process_frame
	await get_tree().process_frame
	var messages = _stop_capture()
	assert_eq(before_frame, [])
	assert_eq(messages, ["resumed", "resumed"])


func _start_capture() -> void:
	_capture = OutputCapture.new()
	OS.add_logger(_capture)


func _stop_capture() -> Array[String]:
	OS.remove_logger(_capture)
	var messages = _capture.snapshot()
	_capture = null
	return messages
