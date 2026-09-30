## res://tests/corpus/lambdas.gd

extends Node


func run() -> void:
	var f = func(x: int) -> int:
		return x + 1
	var result = f.call(10)
	print(result)
