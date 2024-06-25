## This base class for other Maze nodes has some basic directional functionality.
class_name Maze
extends Node2D

const N: StringName = "n"
const NE: StringName = "ne"
const E: StringName = "e"
const SE: StringName = "se"
const S: StringName = "s"
const SW: StringName = "sw"
const W: StringName = "w"
const NW: StringName = "nw"

## Used to reference the cardinal directions (north, east, south, and west).
var cardinal_directions: Array[StringName] = [N, E, S, W]

## Used to reference all directions (cardinal + northeast, southeast, southwest, and northwest).
var directions: Array[StringName] = [N, NE, E, SE, S, SW, W, NW]

## Used to determine which value should be added to a 2D maze coordinate, to find the coordinate in
## a given direction. For example, if you are at `Vector2i(0, 0)` and want to travel north three
## spaces, you would move to `Vector2i(0, 0) + direction_vector_map[N] * 3`.
var direction_vector_map: Dictionary = {
	N: Vector2i(0, -1),
	NE: Vector2i(1, -1),
	E: Vector2i(1, 0),
	SE: Vector2i(1, 1),
	S: Vector2i(0, 1),
	SW: Vector2i(-1, 1),
	W: Vector2i(-1, 0),
	NW: Vector2i(-1, -1),
}

## Used to determine which direction a 2D maze coordinate is, relative to another coordinate. For
## example, if you are at `Vector2i(0, 0)` and want to know which direction `Vector2i(0, -1)` is in,
## you could use `vector_direction_map[Vector2i(0, -1)]` to determine it is north.
var vector_direction_map: Dictionary = {
	Vector2i(0, -1): N,
	Vector2i(1, -1): NE,
	Vector2i(1, 0): E,
	Vector2i(1, 1): SE,
	Vector2i(0, 1): S,
	Vector2i(-1, 1): SW,
	Vector2i(-1, 0): W,
	Vector2i(-1, -1): NW,
}


## Find the direction of one vector, relative to another (defaults to Vector2i.ZERO). For example,
## if you are at `Vector2i(0, -1)` and want to know which direction `Vector2i(0, -3)` is in, you can
## call `get_direction_from_vector(Vector2i(0, -3), Vector2i(0, -1))` to determine it is north.
func get_direction_from_vector(vector: Vector2i, relative_to := Vector2i.ZERO) -> StringName:
	var relative_vector: Vector2i = vector - relative_to
	var normalized_vector := Vector2i(sign(relative_vector.x), sign(relative_vector.y))
	var default_value := StringName()
	
	return vector_direction_map.get(normalized_vector, default_value)


## Find the vector in a given direction and distance, relative to a known vector. For example, if
## you are at `Vector2i(0, -1)` and want to travel north two spaces, you can call
## `get_vector_from_direction(N, Vector2i(0, -1), 2` to get the vector `Vector2i(0, -3)`.
func get_vector_from_direction(
	direction: StringName,
	relative_to := Vector2i.ZERO,
	distance: int = 1
) -> Vector2i:
	var default_value := Vector2i.ZERO
	
	return relative_to + direction_vector_map.get(direction, default_value) * distance
