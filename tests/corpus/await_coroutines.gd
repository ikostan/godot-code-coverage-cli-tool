## res://tests/corpus/await_coroutines.gd

extends Node


func run() -> void:
	await get_tree().process_frame
	print("resumed")
