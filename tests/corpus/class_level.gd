## res://tests/corpus/class_level.gd

extends Node


class Inner:
	var value: int = 7

	func get_value() -> int:
		return value


func make() -> Inner:
	return Inner.new()
