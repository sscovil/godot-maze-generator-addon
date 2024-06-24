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

var cardinal_directions: Array[StringName] = [N, E, S, W]

var directions: Array[StringName] = [N, NE, E, SE, S, SW, W, NW]

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

func get_direction_from_vector(vector: Vector2i) -> StringName:
	return vector_direction_map[vector]


func get_directions(cardinal: bool) -> Array[StringName]:
	return cardinal_directions if cardinal else directions


func get_neighbor_coords(coords: Vector2i, direction: StringName) -> Vector2i:
	return coords + get_vector_from_direction(direction)


func get_vector_from_direction(direction: StringName) -> Vector2i:
	return direction_vector_map[direction]
