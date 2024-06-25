extends Node2D

## Represents the tab indices for $TabContainer.
enum Tab {
	PREVIEW,
	SETTINGS,
}

## Syntactic sugar; use X as a Dictionary key instead of the string "x".
const X: StringName = "x"

## Syntactic sugar; use Y as a Dictionary key instead of the string "y".
const Y: StringName = "y"

## PrintableMazeGrid child node.
@onready var grid: PrintableMazeGrid = $PrintableMazeGrid

## RichTextLabel where BBCode representation of PrintableMazeGrid is displayed.
@onready var preview_maze: RichTextLabel = $TabContainer/Preview/Maze

## ProgressBar displayed when generating a new MazeGrid.
@onready var preview_progress_bar: ProgressBar = $TabContainer/Preview/ProgressBar

## HSlider nodes in the Settings UI, used for adjusting `grid.grid_size`.
@onready var settings_grid: Dictionary = {
	X: $TabContainer/Settings/List/GridX,
	Y: $TabContainer/Settings/List/GridY,
}

## Button in the Settings UI, used for switching back to the Preview tab.
@onready var settings_preview: Button = $TabContainer/Settings/List/Preview

## SpinBox nodes in the Settings UI, used for adjusting `grid.start_coords`.
@onready var settings_start_coords: Dictionary = {
	X: $TabContainer/Settings/List/StartCoordsContainer/StartX,
	Y: $TabContainer/Settings/List/StartCoordsContainer/StartY,
}

## TabContainer used to switch between the Preview and Settings UI tabs.
@onready var tab_container: TabContainer = $TabContainer

## Used to detect changes in the Settings UI, when switching back to the Preview UI.
var last_grid_size: Vector2i

## Used to detect changes in the Settings UI, when switching back to the Preview UI.
var last_start_coords: Vector2i


## Run once when the node is added to the scene tree.
func _ready() -> void:
	# Generate the initial GridMaze.
	grid.generate()
	# Enable support for signals, so we can update $TabContainer/Preview/ProgressBar.
	grid.await_after_signals = true
	# Connect signals to the appropriate handler methods.
	_connect_signals()
	# Initialize values for the Settings UI.
	_initialize_settings()
	# Update value of `preview_maze` RichTextLabel with BBCode representation of `grid`.
	draw_grid()


## Called for each unhandled InputEvent.
func _unhandled_key_input(event: InputEvent) -> void:
	# Ignore any input that is not a keyboard input.
	if not event is InputEventKey:
		return
	
	# Regenerate the MazeGrid when the R key is pressed on the Preview tab.
	if is_current_tab_preview() and event.keycode == KEY_R and event.is_pressed():
		await grid.generate()


## Updates value of `preview_maze` RichTextLabel with BBCode representation of `grid`.
func draw_grid() -> void:
	# Wrap the rich text representation of `grid`, to center it horizontally.
	var rich_text: String = "[center]%s[/center]" % grid.to_rich_text()
	# Update the RichTextLabel text value.
	preview_maze.set_text(rich_text)


## Returns `true` if the `grid.grid_size` value changed since `grid.generate()` was last called.
func has_grid_size_changed() -> bool:
	return last_grid_size != grid.grid_size


## Returns `true` if any settings have changed since `grid.generate()` was last called.
func has_settings_changed() -> bool:
	return has_grid_size_changed() or has_start_coords_changed()


## Returns `true` if the `grid.start_coords` value changed since `grid.generate()` was last called.
func has_start_coords_changed() -> bool:
	return last_start_coords != grid.start_coords


## Returns `true` if the current tab is the Preview tab.
func is_current_tab_preview() -> bool:
	return Tab.PREVIEW == tab_container.current_tab


## Returns `true` if the current tab is the Settings UI.
func is_current_tab_settings() -> bool:
	return Tab.SETTINGS == tab_container.current_tab


## Connects signals to the appropriate handler methods.
func _connect_signals() -> void:
	# Used to display a progress bar when generating the MazeGrid.
	grid.generate_begin.connect(_on_grid_generate_begin)
	grid.generate_end.connect(_on_grid_generate_end)
	grid.generate_progress.connect(_on_grid_generate_progress)
	
	# Used to update `grid.grid_size` based on changes in the Settings UI.
	settings_grid[X].value_changed.connect(_on_settings_grid_x_value_changed)
	settings_grid[Y].value_changed.connect(_on_settings_grid_y_value_changed)
	
	# Used to switch back to the Preview tab with the button on the Settings UI.
	settings_preview.button_up.connect(_on_settings_preview_button_up)
	
	# Used to update `grid.start_coords` based on changes in the Settings UI.
	settings_start_coords[X].value_changed.connect(_on_settings_start_coords_x_value_changed)
	settings_start_coords[Y].value_changed.connect(_on_settings_start_coords_y_value_changed)
	
	# Used to regenerate `grid` if necessary, when switching to the Preview tab.
	tab_container.tab_changed.connect(_on_tab_container_tab_changed)


## Initializes values for the Settings UI.
func _initialize_settings() -> void:
	# Used to detect changes to settings since `grid.generate()` was last called.
	last_grid_size = grid.grid_size
	last_start_coords = grid.start_coords
	
	# Display numeric values in tooltips when hovering over an HSlider in the Settings UI.
	_update_settings_grid_size_tooltip(X)
	_update_settings_grid_size_tooltip(Y)
	
	# Constrain SpinBox max values based on `grid.grid_size`. 
	_update_settings_start_coords_max_value(X)
	_update_settings_start_coords_max_value(Y)


## Hides `preview_maze`, and initializes and shows `preview_progress_bar`.
func _on_grid_generate_begin() -> void:
	preview_maze.set_visible(false)
	preview_progress_bar.set_value(0)
	preview_progress_bar.set_visible(true)


## Hides `preview_progress_bar`, and redraws and shows `preview_maze`.
func _on_grid_generate_end() -> void:
	draw_grid()
	preview_progress_bar.set_visible(false)
	preview_maze.set_visible(true)


## Updates `preview_progress_bar` incrementally, based on `generate_progress` signal data.
func _on_grid_generate_progress(progress: float) -> void:
	preview_progress_bar.set_value(progress)


## Sync HSlider value with `grid.grid_size.x`, HSlider tooltip, and `grid.start_coords.x` max value.
func _on_settings_grid_x_value_changed(value: float) -> void:
	grid.grid_size.x = floor(value)
	_update_settings_grid_size_tooltip(X)
	_update_settings_start_coords_max_value(X)


## Sync HSlider value with `grid.grid_size.y`, HSlider tooltip, and `grid.start_coords.y` max value.
func _on_settings_grid_y_value_changed(value: float) -> void:
	grid.grid_size.y = floor(value)
	_update_settings_grid_size_tooltip(Y)
	_update_settings_start_coords_max_value(Y)


## Switch to the Preview tab when the Preview button is pressed on the Settings UI.
func _on_settings_preview_button_up() -> void:
	tab_container.set_current_tab(Tab.PREVIEW)


## Sync SpinBox value with `grid.start_coords.x`.
func _on_settings_start_coords_x_value_changed(value: float) -> void:
	_update_settings_start_coords(X, value)


## Sync SpinBox value with `grid.start_coords.y`.
func _on_settings_start_coords_y_value_changed(value: float) -> void:
	_update_settings_start_coords(Y, value)


## When switching back to the Preview tab, call `grid.generate()` if any settings have changed.
func _on_tab_container_tab_changed(tab: int) -> void:
	if tab as Tab == Tab.PREVIEW and has_settings_changed():
		last_grid_size = grid.grid_size
		grid.generate()


## Displays numeric value in tooltip when hovering over an HSlider in the Settings UI.
func _update_settings_grid_size_tooltip(axis: String) -> void:
	settings_grid[axis].set_tooltip_text("%d" % grid.grid_size[axis])


## Updates `grid.start_coords`, ensuring x and y values are either both -1, or both > -1. This is
## because the minimum `grid.start_coords` value is Vector2i(0, 0); the value Vector2i(-1, -1) is
## used to indicate that a random position should be chosen, which is why -1 is allowed as a value
## in the Settings UI. However, a value of Vector2i(-1, 3) for example, would be invalid and so it
## must not be allowed.
func _update_settings_start_coords(axis: StringName, value: float) -> void:
	var other_axis: StringName = Y if axis == X else X
	var max_value: int = grid.grid_size[axis] - 1
	
	# Ensure the value is constrained to the valid range, based on `grid.grid_size`.
	grid.start_coords[axis] = clampi(floor(value), -1, max_value)
	
	# If the value being set is -1, set the other axis value to also be -1.
	if grid.start_coords[axis] == -1:
		grid.start_coords[other_axis] = -1
		settings_start_coords[other_axis].set_value(-1)
	
	# If the other value is -1 and the value beind set is greater, set the other axis value to 0.
	elif grid.start_coords[other_axis] == -1:
		grid.start_coords[other_axis] = 0
		settings_start_coords[other_axis].set_value(0)


## When `grid.grid_size` changes, update the corresponding `grid.start_coords` max value.
func _update_settings_start_coords_max_value(axis: String) -> void:
	var max_value: int = grid.grid_size[axis] - 1
	
	# Update the SpinBox max value in the Settings UI.
	settings_start_coords[axis].set_max(max_value)
	
	# If `grid.start_coords` value is above max, set it to `max_value` and update SpinBox value.
	if grid.start_coords[axis] > max_value:
		grid.start_coords[axis] = max_value
		settings_start_coords[axis].value = max_value
