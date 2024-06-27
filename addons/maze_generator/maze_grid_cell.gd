class_name MazeGridCell
extends Resource

## Used to indicate the type of cell. START indicates the first cell that was generated in a Maze;
## END indicates the last cell; TERMINAL indicates a dead end; and PATH is used for all others.
enum Type {
	PATH,
	START,
	TERMINAL,
	END,
}

## Vector2i coordinates of the Maze, which is always a 2D construct (even in 3D games).
@export var coords: Vector2i

## Used to indicate the type of cell. See the description of the Type enum above for details.
var type: Type = Type.PATH

## By default, each cell is surrounded by virtual "walls". As a Maze is generated, cells are
## traversed at random, and the walls between the cells are removed (i.e. set to `false`).
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


## Runs once when `MazeGridCell.new()` is called.
func _init(_coords: Vector2i = Vector2i.ZERO) -> void:
	coords = _coords


## Returns the cell data as a Dictionary.
func to_dict() -> Dictionary:
	return {
		"coords": coords,
		"type": Type,
		"walls": walls,
	}


## Returns the number of virtual "walls" surrounding the cell. By default, it will only return the
## number of walls to the north, east, south, and west (i.e. the cardinal directions), but this
## behavior can be changed by supplying an array of directions as an optional  argument. Use the
## Direction constants (ex: [Direction.NW, Direction.SE]), or the `Direction.list` array, when
## supplying an argument to this method.
func get_wall_count(directions: Array[StringName] = Direction.cardinal) -> int:
	var count: int = 0
	
	for direction in directions:
		if walls[direction]:
			count += 1
	
	return count
