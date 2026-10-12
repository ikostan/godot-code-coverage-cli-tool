extends Node

static var counter: int = 0

static func _static_init() -> void:
	counter = 42

func get_counter() -> int:
	return counter
