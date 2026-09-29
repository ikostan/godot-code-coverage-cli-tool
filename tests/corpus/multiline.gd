## res://tests/corpus/multiline.gd

extends Node


func build() -> String:
	var s = "hello " + \
		"world"
	return s
