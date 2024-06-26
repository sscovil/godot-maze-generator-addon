## This base class for other Maze nodes has some basic directional functionality.
class_name Maze
extends Node2D

signal generate_begin()
signal generate_end()
signal generate_progress(progress: float)

@export var grid: MazeGrid

@export_group("Generator Settings")

## If set to `true`, the `generate()` method will await the next process frame periodically, to
## allow UI updates (i.e. for a ProgressBar). The frequency of these delays can be tuned using the
## `await_increment` setting; a higher value means faster grid generation with fewer pauses for UI
## updates.
@export var await_after_signals: bool = false

## If `await_after_signals` is set to `true`, this value can be used to tune how often the
## `generate()` method pauses to allow for UI updates (i.e. for a ProgressBar). A higher value
## means faster grid generation with fewer pauses for UI updates.
@export var await_increment: int = 20


## Generate a maze by picking a random, unvisited neighboring cell and knocking down the walls
## between the two cells. Repeat this until we can go no further, then back track and keep trying
## to find alternative paths, until every cell has been visited.
func generate():
	var progress: float = 0.0
	var steps: int = grid.size.x * grid.size.y * 2
	var increment: float = 100.0 / steps
	
	# Emit signal that generation has begun.
	generate_begin.emit()
	# Pause until the next frame, to allow signal handlers to run.
	if await_after_signals:
		await _next_frame()
	
	grid.cells = {}
	
	for x in range(grid.size.x):
		for y in range(grid.size.y):
			var coords := Vector2i(x, y)
			var cell := MazeGridCell.new(coords)
			grid.cells[coords] = cell
			# Update progress and emit signal.
			progress += increment
			generate_progress.emit(progress)
			# Pause until the next frame, to allow signal handlers to run.
			if await_after_signals and ((progress / increment) as int) % await_increment == 0:
				await _next_frame()
	
	var backtracking: bool = false
	var coords: Vector2i
	var cursor: int = -1
	var visited: Array[Vector2i] = []
	
	if grid.RandomPosition == grid.start_coords:
		coords = grid.get_random_coords()
	else:
		coords = grid.start_coords.clamp(Vector2i.ZERO, grid.size)
	
	grid.set_cell_as_type(coords, MazeGridCell.Type.START)
	
	while true:
		if coords not in visited:
			visited.append(coords)
		
		# If all cells have been visited, we are done.
		if visited.size() == size():
			grid.set_cell_as_type(coords, MazeGridCell.Type.END)
			# Emit signal that generation has ended.
			generate_end.emit()
			# Exit the while loop.
			break
		
		var next_cell := _get_random_unvisited_neighbor(coords, visited)
		
		if next_cell:
			# Knock down the walls between next cell and the previously visited cell.
			backtracking = false
			grid.set_adjoining_walls(coords, next_cell.coords, false)
			coords = next_cell.coords
			cursor = visited.size() - 1
			# Update progress and emit signal.
			progress += increment
			generate_progress.emit(progress)
			# Pause until the next frame, to allow signal handlers to run.
			if await_after_signals and ((progress / increment) as int) % await_increment == 0:
				await _next_frame()
			
		else:
			# Backtrack through the maze until we can travel to an unvisited cell.
			if !backtracking:
				grid.set_cell_as_type(coords, MazeGridCell.Type.TERMINAL)
				backtracking = true
			cursor -= 1
			coords = visited[cursor]


func size() -> int:
	return grid.cells.keys().size()


func _get_random_unvisited_neighbor(coords: Vector2i, visited: Array[Vector2i]) -> MazeGridCell:
	var neighbors := grid.get_cell_neighbors(coords, true)
	
	neighbors.shuffle()
	
	for neighbor in neighbors:
		if neighbor.coords not in visited:
			return neighbor
	
	return null


func _next_frame() -> void:
	await get_tree().process_frame
