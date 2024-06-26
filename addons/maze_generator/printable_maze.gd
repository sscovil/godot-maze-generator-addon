class_name PrintableMaze
extends Maze

@export_group("Rich Text Colors")
@export var start_color := Color.GREEN
@export var end_color := Color.YELLOW
@export var terminal_color := Color.RED
@export var path_color := Color.GRAY
@export var wall_color := Color.DIM_GRAY


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
	for y in range(grid.size.y):
		var is_last_y: bool = grid.size.y - 1 == y
		var lines: Array = ["", "", ""] if is_last_y else ["", ""]
		
		# Loop over each cell in the row.
		for x in range(grid.size.x):
			var cell := get_cell_at(Vector2i(x, y))
			var is_last_x: bool = grid.size.x - 1 == x
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
		var is_path = !cell.walls.has(direction)
		var is_wall = !is_path and cell.walls[direction]
		var is_endpoint = " " == direction
		
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
