extends GutTest

const CORPUS_NAMES = [
	"autoload_style",
	"await_coroutines",
	"basic_statements",
	"class_level",
	"control_flow",
	"disabled_instrumentation",
	"edge_cases",
	"lambdas",
	"multiline",
	"static_init",
	"typed_annotations",
]


func test_corpus_uids_are_valid_unique_and_resolve_to_their_scripts():
	var seen: Array[int] = []
	for corpus_name in CORPUS_NAMES:
		var path = "res://tests/corpus/%s.gd" % corpus_name
		var uid_path = path + ".uid"
		assert_true(FileAccess.file_exists(uid_path), uid_path)
		if not FileAccess.file_exists(uid_path):
			continue
		var uid_text = FileAccess.get_file_as_string(uid_path).strip_edges()
		var uid = ResourceUID.text_to_id(uid_text)
		assert_ne(uid, ResourceUID.INVALID_ID, uid_path)
		assert_eq(ResourceUID.id_to_text(uid), uid_text, uid_path)
		assert_does_not_have(seen, uid, "UID collision for " + path)
		seen.append(uid)
		assert_eq(ResourceLoader.get_resource_uid(path), uid, path)


func test_environment_loads_and_retains_sky_without_load_steps():
	var environment = load("res://default_env.tres")
	assert_true(environment is Environment)
	if environment is Environment:
		assert_eq(environment.background_mode, Environment.BG_SKY)
		assert_true(environment.sky is Sky)


func test_scene_instantiates_with_resources_and_signal_connection_intact():
	var packed = load("res://spatial.tscn")
	assert_true(packed is PackedScene)
	if not packed is PackedScene:
		return
	# Keep the demo out of the tree: its timer invokes unrelated legacy coverage code.
	var scene = autofree(packed.instantiate())
	assert_true(scene is Node3D)
	assert_eq(scene.get_script().resource_path, "res://spatial.gd")
	assert_eq(scene.get_child_count(), 2)
	var label = scene.get_node_or_null("Label")
	var timer = scene.get_node_or_null("Timer")
	assert_true(label is Label)
	assert_true(timer is Timer)
	if label is Label:
		assert_eq(label.text, "InterExtends(Inner((hello world)))")
	if timer is Timer:
		assert_almost_eq(timer.wait_time, 0.1, 0.00001)
		assert_true(timer.one_shot)
		assert_true(timer.autostart)
		assert_true(timer.timeout.is_connected(Callable(scene, "_on_Timer_timeout")))
