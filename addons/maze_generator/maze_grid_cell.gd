class_name MazeGridCell
extends Maze

enum Type {
	PATH,
	START,
	TERMINAL,
	END,
}

@export var coords: Vector2i

var type: Type = Type.PATH

var walls: Dictionary = {
	N: true,
	NE: true,
	E: true,
	SE: true,
	S: true,
	SW: true,
	W: true,
	NW: true,
}


func _init(_coords: Vector2i = Vector2i.ZERO) -> void:
	coords = _coords


func to_dict() -> Dictionary:
	return {
		"coords": coords,
		"type": Type,
		"walls": walls,
	}


func get_wall_count(cardinal: bool = true) -> int:
	var count: int = 0
	var directions: Array[StringName] = get_directions(cardinal)
	
	for direction in directions:
		if walls[direction]:
			count += 1
	
	return count


func is_dead_end(cardinal: bool = true) -> bool:
	return 1 == get_wall_count(cardinal)
