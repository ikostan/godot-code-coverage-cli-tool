extends Node


func test(v: int) -> int:
	if v > 0:
		return v * 2
	elif v < 0:
		return -v
	else:
		return 0
