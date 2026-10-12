extends Node

func run() -> void:
	await get_tree().process_frame
	print("resumed")
