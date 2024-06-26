## A collection of constants, static variables, and static methods related to map directions
## (e.g. north, east, south, west) and 2D grid coordinates, required by the MazeGenerator plugin.
class_name Direction
extends Object

const N: StringName = "n"
const NE: StringName = "ne"
const E: StringName = "e"
const SE: StringName = "se"
const S: StringName = "s"
const SW: StringName = "sw"
const W: StringName = "w"
const NW: StringName = "nw"

## Used to reference the cardinal directions (north, east, south, and west).
static var cardinal: Array[StringName] = [N, E, S, W]

## Used to reference all directions (cardinal + northeast, southeast, southwest, and northwest).
static var list: Array[StringName] = [N, NE, E, SE, S, SW, W, NW]

## Used to determine which value should be added to a 2D maze coordinate, to find the coordinate in
## a given direction. For example, if you are at Vector2i(0, 0) and want to travel north three
## spaces, you would move to `Vector2i(0, 0) + Direction.direction_vector_map[N] * 3`.
static var direction_vector_map: Dictionary = {
	Direction.N: Vector2i(0, -1),
	Direction.NE: Vector2i(1, -1),
	Direction.E: Vector2i(1, 0),
	Direction.SE: Vector2i(1, 1),
	Direction.S: Vector2i(0, 1),
	Direction.SW: Vector2i(-1, 1),
	Direction.W: Vector2i(-1, 0),
	Direction.NW: Vector2i(-1, -1),
}

## Used to determine which direction a 2D maze coordinate is, relative to another coordinate. For
## example, if you are at Vector2i(0, 0) and want to know which direction Vector2i(0, -1) is in,
## you could use `Direction.vector_direction_map[Vector2i(0, -1)]` to determine it is north.
static var vector_direction_map: Dictionary = {
	Vector2i(0, -1): Direction.N,
	Vector2i(1, -1): Direction.NE,
	Vector2i(1, 0): Direction.E,
	Vector2i(1, 1): Direction.SE,
	Vector2i(0, 1): Direction.S,
	Vector2i(-1, 1): Direction.SW,
	Vector2i(-1, 0): Direction.W,
	Vector2i(-1, -1): Direction.NW,
}


## Find the direction of one vector, relative to another (defaults to Vector2i.ZERO). For example,
## if you are at Vector2i(0, -1) and want to know which direction Vector2i(0, -3) is in, you can
## call `Direction.get_direction(Vector2i(0, -3), Vector2i(0, -1))` to determine it is north.
static func get_direction(vector: Vector2i, relative_to := Vector2i.ZERO) -> StringName:
	var relative_vector: Vector2i = vector - relative_to
	var normalized_vector := Vector2i(sign(relative_vector.x), sign(relative_vector.y))
	var default_value := StringName()
	
	return Direction.vector_direction_map.get(normalized_vector, default_value)


## Find the vector in a given direction and distance, relative to a known vector. For example, if
## you are at Vector2i(0, -1) and want to travel north two spaces, you can call
## `Direction.get_vector(Direction.N, Vector2i(0, -1), 2)` to get the vector Vector2i(0, -3).
static func get_vector(
	direction: StringName,
	relative_to := Vector2i.ZERO,
	distance: int = 1
) -> Vector2i:
	var default_value := Vector2i.ZERO
	
	return relative_to + Direction.direction_vector_map.get(direction, default_value) * distance
