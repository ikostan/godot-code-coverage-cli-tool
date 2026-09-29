## res://tests/corpus/typed_annotations.gd

extends Node

@onready var label: Label = $Label


func _ready() -> void:
	label.text = "ok"
