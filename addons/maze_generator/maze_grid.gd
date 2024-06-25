class_name MazeGrid
extends Maze

signal generate_begin()
signal generate_end()
signal generate_progress(progress: float)

const RandomPosition := Vector2i(-1, -1)

@export var grid_size := Vector2i(8, 8)
@export var start_coords: Vector2i = RandomPosition

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

## A map of Vector2i coordinates and their corresponding GridCell objects.
var cells: Dictionary = {}


func _on_exit() -> void:
	_clear_cells()


## Generate a maze by picking a random, unvisited neighboring cell and knocking down the walls
## between the two cells. Repeat this until we can go no further, then back track and keep trying
## to find alternative paths, until every cell has been visited.
func generate():
	var progress: float = 0.0
	var steps: int = grid_size.x * grid_size.y * 2
	var increment: float = 100.0 / steps
	
	# Emit signal that generation has begun.
	generate_begin.emit()
	# Pause until the next frame, to allow signal handlers to run.
	if await_after_signals:
		await _next_frame()
	
	_clear_cells()
	
	for x in range(grid_size.x):
		for y in range(grid_size.y):
			var coords := Vector2i(x, y)
			var cell := MazeGridCell.new(coords)
			add_child(cell)
			cells[coords] = cell
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
	
	if RandomPosition == start_coords:
		coords = get_random_coords()
	else:
		coords = start_coords.clamp(Vector2i.ZERO, grid_size)
	
	set_cell_as_type(coords, MazeGridCell.Type.START)
	
	while true:
		if coords not in visited:
			visited.append(coords)
		
		# If all cells have been visited, we are done.
		if visited.size() == size():
			set_cell_as_type(coords, MazeGridCell.Type.END)
			# Emit signal that generation has ended.
			generate_end.emit()
			# Exit the while loop.
			break
		
		var next_cell := _get_random_unvisited_neighbor(coords, visited)
		
		if next_cell:
			# Knock down the walls between next cell and the previously visited cell.
			backtracking = false
			set_adjoining_walls(coords, next_cell.coords, false)
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
				set_cell_as_type(coords, MazeGridCell.Type.TERMINAL)
				backtracking = true
			cursor -= 1
			coords = visited[cursor]


func get_cell_at(coords: Vector2i) -> MazeGridCell:
	return cells.get(coords, null)


func get_neighbors(coords: Vector2i, cardinal: bool = true) -> Array[MazeGridCell]:
	var neighbors: Array[MazeGridCell] = []
	var distance: int = 1
	
	for direction in cardinal_directions:
		var neighbor_coords = get_vector_from_direction(direction, coords, distance)
		var neighbor: MazeGridCell = get_cell_at(neighbor_coords)
		if neighbor:
			neighbors.append(neighbor)
	
	return neighbors


func get_random_cell() -> MazeGridCell:
	return cells[get_random_coords()]


func get_random_coords() -> Vector2i:
	return cells.keys().pick_random()


func set_adjoining_walls(coords_a: Vector2i, coords_b: Vector2i, value: bool) -> void:
	var cell_a := get_cell_at(coords_a)
	var cell_b := get_cell_at(coords_b)
	
	if cell_a:
		cell_a.walls[get_direction_from_vector(coords_b - coords_a)] = value
	
	if cell_b:
		cell_b.walls[get_direction_from_vector(coords_a - coords_b)] = value


func set_cell_as_type(coords: Vector2i, type: MazeGridCell.Type) -> void:
	var cell := get_cell_at(coords)
	
	if cell:
		cell.type = type


func size() -> int:
	return cells.keys().size()


func _clear_cells() -> void:
	for key in cells.keys():
		cells.erase(key)


func _get_random_unvisited_neighbor(
		coords: Vector2i,
		visited: Array[Vector2i],
) -> MazeGridCell:
	var neighbors := get_neighbors(coords, true)
	
	neighbors.shuffle()
	
	for neighbor in neighbors:
		if neighbor.coords not in visited:
			return neighbor
	
	return null


func _next_frame() -> void:
	await get_tree().process_frame
