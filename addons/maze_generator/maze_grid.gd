## This resource is used to generate, store, and access layout data for a Maze.
class_name MazeGrid
extends Resource

## Used to indicate that `start_coords` should be random.
const RandomPosition := Vector2i(-1, -1)

## The desired grid size of the maze. Note that "grid size" does not include the size of the walls
## and paths that connect each cell; the actual maze will be (size * 2 + 1).
@export var size := Vector2i(8, 8)

## Grid coordinates for the desired starting position. If set to `Vector2i(-1, -1)` (the default), a
## random cell will be chosen each time the maze is generated.
@export var start_coords: Vector2i = RandomPosition

## These settings can be used to customize the appearance of the output generated from the
## `to_rich_text()` method, and are probably not useful for anything beyond demonstration purposes.
@export_group("Rich Text Colors")

## Color of the first cell generated, located at `start_coords`.
@export var start_color := Color.GREEN

## Color of the last cell generated.
@export var end_color := Color.YELLOW

## Color of each terninal (i.e. dead end) cell, other than the first and last cells generated.
@export var terminal_color := Color.RED

## Color of each character that represents a cell, or path that connects two cells, other than the
## start, end, and terminal cells.
@export var path_color := Color.GRAY

## Color of each character that represents the empty space (i.e. "walls") surrounding each cell and
## path that connects two cells.
@export var wall_color := Color.DIM_GRAY

## A map of `Vector2i` coordinates and their corresponding `MazeGridCell` objects.
var cells: Dictionary = {}


func clear() -> void:
	cells.clear()


func get_cell(direction: StringName, relative_to: Vector2i, distance: int = 1) -> MazeGridCell:
	var coords: Vector2i = Direction.get_vector(direction, relative_to, distance)

	return get_cell_at(coords)


func get_cell_at(coords: Vector2i) -> MazeGridCell:
	return cells.get(coords, null)


func get_cell_neighbors(coords: Vector2i, cardinal: bool = true) -> Array[MazeGridCell]:
	var neighbors: Array[MazeGridCell] = []
	var distance: int = 1
	
	for direction in Direction.cardinal:
		var neighbor_coords = Direction.get_vector(direction, coords, distance)
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
		cell_a.walls[Direction.get_direction(coords_b - coords_a)] = value
	
	if cell_b:
		cell_b.walls[Direction.get_direction(coords_a - coords_b)] = value


func set_cell_as_type(coords: Vector2i, type: MazeGridCell.Type) -> void:
	var cell := get_cell_at(coords)
	
	if cell:
		cell.type = type


## Convenience method, for code that is more readable than `to_text(true)`.
func to_rich_text() -> String:
	return to_text(true)


## Generate a text representation of the grid path.
## 
## Think of each grid cell as a 3x3 square of ascii characters: the northwest, north, and northeast
## walls on the first line; the west wall, center area, and east wall on the second line; and the
## southwest, south, and southeast walls on the third line.
## 
## To achieve this, we must loop over each row in the grid, then for each cell, produce three lines
## of ascii art that can be concatenated with the other cells in the row. However, the eastern walls
## of each cell match the western walls of the one before it, so to avoid doubling up the walls in
## the output, we only want the non-eastern wall data for every cell except the last. Likewise, the
## southern walls of each row match the northern walls of the one below it, so we only want to add
## the non-southern wall data for every row except the last.
## 
## Cells also have a type. Most are of the type MazeGridCell.Type.PATH, but one will be
## MazeGridCell.Type.START; one will be MazeGridCell.Type.END; and several will be
## MazeGridCell.Type.TERMINAL. These will appear on the map as their numeric enum values.
func to_text(is_rich_text: bool = false) -> String:
	var output: Array[String] = []
	
	# Loop over each row in the grid.
	for y in range(size.y):
		var is_last_y: bool = size.y - 1 == y
		var lines: Array = ["", "", ""] if is_last_y else ["", ""]
		
		# Loop over each cell in the row.
		for x in range(size.x):
			var cell := get_cell_at(Vector2i(x, y))
			var is_last_x: bool = size.x - 1 == x
			var line_0_walls: Array = ["nw", "n", "ne"] if is_last_x else ["nw", "n"]
			var line_1_walls: Array = ["w", " ", "e"] if is_last_x else ["w", " "]
			var line_2_walls: Array = ["sw", "s", "se"] if is_last_x else ["sw", "s"]
			
			lines[0] += _get_cell_text(cell, line_0_walls, is_rich_text)
			lines[1] += _get_cell_text(cell, line_1_walls, is_rich_text)
			
			if is_last_y:
				lines[2] += _get_cell_text(cell, line_2_walls, is_rich_text)
		
		# Add each of the lines representing the current row to the final output array.
		output.append_array(lines)
	
	# Join each row in the output array with a line break character.
	return "\n".join(output)


## Helper method to get a text representation of a section of a given cell, as indicated by the
## given directions array.
## 
## For example, if directions is ["nw", "n"], this method will return the appropriate ascii for
## the cell's northwest and north walls, as a single string.
func _get_cell_text(cell: MazeGridCell, directions: Array, is_rich_text: bool = false) -> String:
	var output: String = ""
	
	for direction in directions:
		var text: String = ""
		var is_null = !cell
		var is_path = !is_null and !cell.walls.has(direction)
		var is_wall = is_null or (!is_path and cell.walls[direction])
		var is_endpoint = !is_null and " " == direction
		
		if is_path:
			text = "%d" % cell.type
		elif is_wall:
			text = "•"
		else:
			text = "%d" % MazeGridCell.Type.PATH
		
		if is_rich_text:
			var color: String
			
			if is_endpoint:
				match cell.type:
					MazeGridCell.Type.START:
						color = start_color.to_html()
					MazeGridCell.Type.TERMINAL:
						color = terminal_color.to_html()
					MazeGridCell.Type.END:
						color = end_color.to_html()
			elif is_wall:
				color = wall_color.to_html()
			elif is_path:
				color = path_color.to_html()
			
			text = "[color=#%s]%s[/color]" % [color, text]
		
		output += text
	
	return output
