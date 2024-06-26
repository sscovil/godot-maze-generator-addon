class_name MazeGridCell
extends Resource

enum Type {
	PATH,
	START,
	TERMINAL,
	END,
}

@export var coords: Vector2i

var type: Type = Type.PATH

var walls: Dictionary = {
	Direction.N: true,
	Direction.NE: true,
	Direction.E: true,
	Direction.SE: true,
	Direction.S: true,
	Direction.SW: true,
	Direction.W: true,
	Direction.NW: true,
}


func _init(_coords: Vector2i = Vector2i.ZERO) -> void:
	coords = _coords


func to_dict() -> Dictionary:
	return {
		"coords": coords,
		"type": Type,
		"walls": walls,
	}


func get_wall_count(directions: Array[StringName] = Direction.cardinal) -> int:
	var count: int = 0
	
	for direction in directions:
		if walls[direction]:
			count += 1
	
	return count
