## Base class with logic for generating a maze.
class_name Maze
extends Node2D

## Emitted when `generate()` is called, after `grid.clear()` has been called. This signal is not
## emittted if `generate()` is called while the maze is already in the process of being generated.
signal generate_begin()

## Emitted when the `generate()` method has completed.
signal generate_end()

## Emitted each time incremental progress is made when the `generate()` method is running. If the
## `emit_progress_signals` value is set to `false` (default), this signal will not be emitted.
signal generate_progress(progress: float)

## MazeGrid node
@export var grid: MazeGrid

## If set to `true`, the `generate_progress` signal will be emitted at various increments when the
## `generate()` method is called. This makes the process of generating a maze more asynchronous,
## but it also makes `generate()` take a bit longer to complete.
@export var emit_progress_signals: bool = false

## Used to prevent the `generate()` method from being called again while it is running.
var is_generating: bool = false


## Generate a maze using a depth-first search algorithm with backtracking.
func generate():
	# Prevent this method from being called again while it is running.
	if is_generating:
		return
	is_generating = true
	
	# Emit the `generate_begin` signal and await the next frame, to allow for UI updates.
	generate_begin.emit()
	await _next_frame()
	
	# Initialize the grid with empty cells.
	await _initialize_grid()
	
	# Generate the maze using depth-first search with backtracking.
	await _generate_maze()
	
	# Allow this method to be called again, and emit the `generate_end` signal.
	is_generating = false
	generate_end.emit()


## Wait for the next frame, then call `generate()`.
func generate_next_frame() -> void:
	await _next_frame()
	generate()


## Get the total number of cells in the maze.
func size() -> int:
	return grid.size.x * grid.size.y


## Connect two cells by removing the walls between them.
func _connect_cells(from: Vector2i, to: Vector2i):
	grid.set_adjoining_walls(false, from, to)


## Generate the maze using depth-first search with backtracking.
func _generate_maze():
	var visited: Array[Vector2i] = []
	var backtracking: bool = false
	var coords := _get_start_coords()
	var cursor: int = -1
	
	# Mark the first cell as `MazeGridCell.Type.START`.
	grid.set_cell_as_type(coords, MazeGridCell.Type.START)
	
	# Populate each cell by heading in a random direction and removing the wall between the
	# two cells, until we can no longer move forward. At each endpoint, mark the cell as
	# `MazeGridCell.Type.TERMINAL`. Then backtrack, trying again at each cell to move in a
	# new direction to an unvisited cell, until all cells have been visited.
	while visited.size() < size():
		# Only add each visited cell once, to avoid ending the loop early when backtracking.
		if coords not in visited:
			visited.append(coords)
		
		var next_cell := _get_random_unvisited_neighbor(coords, visited)
		
		# If there is an unvisited neighboring cell, remove the walls between the two cells.
		if next_cell:
			backtracking = false
			_connect_cells(coords, next_cell.coords)
			coords = next_cell.coords
			cursor = visited.size() - 1
			
			# Update progress and emit signal, if configured to do so.
			if emit_progress_signals:
				await _update_progress(visited.size())
		
		# If there are no unvisted neighboring cells, mark the cell as `MazeGridCell.Type.TERMINAL`
		# and start backtracking.
		else:
			if !backtracking:
				grid.set_cell_as_type(coords, MazeGridCell.Type.TERMINAL)
				backtracking = true
			cursor -= 1
			coords = visited[cursor] 
	
	# Mark the last cell as `MazeGridCell.Type.END`.
	grid.set_cell_as_type(coords, MazeGridCell.Type.END)


## Pick a random neighboring cell that has not yet been marked as visited.
func _get_random_unvisited_neighbor(coords: Vector2i, visited: Array[Vector2i]) -> MazeGridCell:
	var neighbors := grid.get_cell_neighbors(coords)
	
	neighbors.shuffle()
	
	for neighbor in neighbors:
		if neighbor.coords not in visited:
			return neighbor
	
	return null


## Get the starting coordinates for maze generation.
func _get_start_coords() -> Vector2i:
	if grid.RandomPosition == grid.start_coords:
		return grid.get_random_coords()
	
	return grid.start_coords.clamp(Vector2i.ZERO, grid.size)


## Initialize the grid with empty cells.
func _initialize_grid():
	grid.clear()
	
	# Loop through each column of the `grid`.
	for x in range(grid.size.x):
		# Loop through each row of the current column.
		for y in range(grid.size.y):
			# Instantiate a MazeGridCell and store it in `grid.cells` at the current coordinates.
			var coords := Vector2i(x, y)
			var cell := MazeGridCell.new(coords)
			grid.cells[coords] = cell
		
		# Update progress after each column is initialized and emit signal, if configured to do so.
		if emit_progress_signals:
			await _update_progress(x * grid.size.y)


## Wait for the next frame.
func _next_frame() -> void:
	await get_tree().process_frame


## Update progress and emit signal.
func _update_progress(steps: int):
	var progress := float(steps) * 100.0 / size()
	generate_progress.emit(progress)
	await _next_frame()
