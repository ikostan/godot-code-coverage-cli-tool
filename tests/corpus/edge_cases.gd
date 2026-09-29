## res://tests/corpus/edge_cases.gd

extends Node


func broken(v: int) -> int:
	return v if true else (func():
		return 1
	).call()
