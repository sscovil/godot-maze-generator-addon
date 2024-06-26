class_name MazeGrid
extends Resource

const RandomPosition := Vector2i(-1, -1)

@export var size := Vector2i(8, 8)
@export var start_coords: Vector2i = RandomPosition


## A map of Vector2i coordinates and their corresponding GridCell objects.
var cells: Dictionary = {}
