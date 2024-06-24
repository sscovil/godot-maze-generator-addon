extends Node2D

enum Tab {
	PREVIEW,
	SETTINGS,
}

const X: String = "x"
const Y: String = "y"

@onready var grid: PrintableMazeGrid = $PrintableMazeGrid
@onready var preview_maze: RichTextLabel = $TabContainer/Preview/Maze
@onready var preview_progress_bar: ProgressBar = $TabContainer/Preview/ProgressBar
@onready var settings_grid: Dictionary = {
	X: $TabContainer/Settings/List/GridX,
	Y: $TabContainer/Settings/List/GridY,
}
@onready var settings_preview: Button = $TabContainer/Settings/List/Preview
@onready var settings_start_coords: Dictionary = {
	X: $TabContainer/Settings/List/StartCoordsContainer/StartX,
	Y: $TabContainer/Settings/List/StartCoordsContainer/StartY,
}
@onready var tab_container: TabContainer = $TabContainer

var last_grid_size: Vector2i
var last_start_coords: Vector2i


func _ready() -> void:
	grid.generate()
	_connect_signals()
	_initialize_settings()
	draw_grid()


func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return
	
	# Regenerate the MazeGrid when the R key is pressed on the Preview tab.
	if is_preview_current_tab() and event.keycode == KEY_R and event.is_pressed():
		await grid.generate()


func draw_grid() -> void:
	var rich_text = "[center]%s[/center]" % grid.to_rich_text()
	preview_maze.set_text(rich_text)


func has_grid_size_changed() -> bool:
	return last_grid_size != grid.grid_size


func has_settings_changed() -> bool:
	return has_grid_size_changed() or has_start_coords_changed()


func has_start_coords_changed() -> bool:
	return last_start_coords != grid.start_coords


func is_preview_current_tab() -> bool:
	return Tab.PREVIEW == tab_container.current_tab


func is_settings_current_tab() -> bool:
	return Tab.SETTINGS == tab_container.current_tab


func _connect_signals() -> void:
	grid.generate_begin.connect(_on_grid_generate_begin)
	grid.generate_end.connect(_on_grid_generate_end)
	grid.generate_progress.connect(_on_grid_generate_progress)
	
	settings_grid[X].value_changed.connect(_on_settings_grid_x_value_changed)
	settings_grid[Y].value_changed.connect(_on_settings_grid_y_value_changed)
	
	settings_preview.button_up.connect(_on_settings_preview_button_up)
	
	settings_start_coords[X].value_changed.connect(_on_settings_start_coords_x_value_changed)
	settings_start_coords[Y].value_changed.connect(_on_settings_start_coords_y_value_changed)
	
	tab_container.tab_changed.connect(_on_tab_container_tab_changed)


func _initialize_settings() -> void:
	grid.await_after_signals = true
	
	last_grid_size = grid.grid_size
	last_start_coords = grid.start_coords
	
	_update_settings_grid_size_tooltip(X)
	_update_settings_grid_size_tooltip(Y)
	
	_update_settings_start_coords_max_value(X)
	_update_settings_start_coords_max_value(Y)


func _on_grid_generate_begin() -> void:
	preview_maze.set_visible(false)
	preview_progress_bar.set_value(0)
	preview_progress_bar.set_visible(true)


func _on_grid_generate_end() -> void:
	draw_grid()
	preview_progress_bar.set_visible(false)
	preview_maze.set_visible(true)


func _on_grid_generate_progress(progress: float) -> void:
	preview_progress_bar.set_value(progress)


func _on_settings_grid_x_value_changed(value: float) -> void:
	grid.grid_size.x = floor(value)
	_update_settings_grid_size_tooltip(X)
	_update_settings_start_coords_max_value(X)


func _on_settings_grid_y_value_changed(value: float) -> void:
	grid.grid_size.y = floor(value)
	_update_settings_grid_size_tooltip(Y)
	_update_settings_start_coords_max_value(Y)


func _on_settings_preview_button_up() -> void:
	tab_container.set_current_tab(Tab.PREVIEW)


func _on_settings_start_coords_x_value_changed(value: float) -> void:
	_update_settings_start_coords(X, value)


func _on_settings_start_coords_y_value_changed(value: float) -> void:
	_update_settings_start_coords(Y, value)


func _on_tab_container_tab_changed(tab: int) -> void:
	if tab as Tab == Tab.PREVIEW and has_settings_changed():
		last_grid_size = grid.grid_size
		await grid.generate()


func _update_settings_grid_size_tooltip(axis: String) -> void:
	settings_grid[axis].set_tooltip_text("%d" % grid.grid_size[axis])


func _update_settings_start_coords(axis: String, value: float) -> void:
	var other_axis = Y if axis == X else X
	var max_value = grid.grid_size[axis] - 1
	
	grid.start_coords[axis] = clampi(floor(value), -1, max_value)
	
	if grid.start_coords[axis] == -1:
		grid.start_coords[other_axis] = -1
		settings_start_coords[other_axis].set_value(-1)
	elif grid.start_coords[other_axis] == -1:
		grid.start_coords[other_axis] = 0
		settings_start_coords[other_axis].set_value(0)


func _update_settings_start_coords_max_value(axis: String) -> void:
	var max_value = grid.grid_size[axis]
	settings_start_coords[axis].set_max(max_value)
	
	if grid.start_coords[axis] >= max_value:
		grid.start_coords[axis] = max_value - 1
		settings_start_coords[axis].value = grid.start_coords[axis]


func _update_settings_start_coords_x_max_value() -> void:
	_update_settings_start_coords_max_value(X)


func _update_settings_start_coords_y_max_value() -> void:
	_update_settings_start_coords_max_value(Y)
