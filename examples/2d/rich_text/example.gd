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

## Maze child node.
@onready var maze: Maze = $Maze

## RichTextLabel where BBCode representation of Maze is displayed.
@onready var preview_maze: RichTextLabel = $TabContainer/Preview/Maze

## ProgressBar displayed when generating a new Maze.
@onready var preview_progress_bar: ProgressBar = $TabContainer/Preview/ProgressBar

## HSlider nodes in the Settings UI, used for adjusting `maze.grid.size`.
@onready var settings_grid: Dictionary = {
	X: $TabContainer/Settings/List/GridX,
	Y: $TabContainer/Settings/List/GridY,
}

## Button in the Settings UI, used for switching back to the Preview tab.
@onready var settings_preview: Button = $TabContainer/Settings/List/Preview

## SpinBox nodes in the Settings UI, used for adjusting `maze.grid.start_coords`.
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
	maze.generate()
	# Enable support for signals, so we can update $TabContainer/Preview/ProgressBar.
	maze.await_after_signals = true
	# Connect signals to the appropriate handler methods.
	_connect_signals()
	# Initialize values for the Settings UI.
	_initialize_settings()
	# Update value of `preview_maze` RichTextLabel with BBCode representation of `maze`.
	draw_grid()


## Called for each unhandled InputEvent.
func _unhandled_key_input(event: InputEvent) -> void:
	# Ignore any input that is not a keyboard input.
	if not event is InputEventKey:
		return
	
	# Regenerate the Maze when the R key is pressed on the Preview tab.
	if is_current_tab_preview() and event.keycode == KEY_R and event.is_pressed():
		await maze.generate()


## Updates value of `preview_maze` RichTextLabel with BBCode representation of `maze`.
func draw_grid() -> void:
	# Wrap the rich text representation of `maze`, to center it horizontally.
	var rich_text: String = "[center]%s[/center]" % maze.grid.to_rich_text()
	# Update the RichTextLabel text value.
	preview_maze.set_text(rich_text)


## Returns `true` if the `maze.grid.size` value changed since `maze.generate()` was last called.
func has_grid_size_changed() -> bool:
	return last_grid_size != maze.grid.size


## Returns `true` if any settings have changed since `maze.generate()` was last called.
func has_settings_changed() -> bool:
	return has_grid_size_changed() or has_start_coords_changed()


## Returns `true` if the `maze.grid.start_coords` value changed since `maze.generate()` was last called.
func has_start_coords_changed() -> bool:
	return last_start_coords != maze.grid.start_coords


## Returns `true` if the current tab is the Preview tab.
func is_current_tab_preview() -> bool:
	return Tab.PREVIEW == tab_container.current_tab


## Returns `true` if the current tab is the Settings UI.
func is_current_tab_settings() -> bool:
	return Tab.SETTINGS == tab_container.current_tab


## Connects signals to the appropriate handler methods.
func _connect_signals() -> void:
	# Used to display a progress bar when generating the Maze.
	maze.generate_begin.connect(_on_grid_generate_begin)
	maze.generate_end.connect(_on_grid_generate_end)
	maze.generate_progress.connect(_on_grid_generate_progress)
	
	# Used to update `maze.grid.size` based on changes in the Settings UI.
	settings_grid[X].value_changed.connect(_on_settings_grid_x_value_changed)
	settings_grid[Y].value_changed.connect(_on_settings_grid_y_value_changed)
	
	# Used to switch back to the Preview tab with the button on the Settings UI.
	settings_preview.button_up.connect(_on_settings_preview_button_up)
	
	# Used to update `maze.grid.start_coords` based on changes in the Settings UI.
	settings_start_coords[X].value_changed.connect(_on_settings_start_coords_x_value_changed)
	settings_start_coords[Y].value_changed.connect(_on_settings_start_coords_y_value_changed)
	
	# Used to regenerate `maze` if necessary, when switching to the Preview tab.
	tab_container.tab_changed.connect(_on_tab_container_tab_changed)


## Initializes values for the Settings UI.
func _initialize_settings() -> void:
	# Used to detect changes to settings since `maze.generate()` was last called.
	last_grid_size = maze.grid.size
	last_start_coords = maze.grid.start_coords
	
	# Display numeric values in tooltips when hovering over an HSlider in the Settings UI.
	_update_settings_grid_size_tooltip(X)
	_update_settings_grid_size_tooltip(Y)
	
	# Constrain SpinBox max values based on `maze.grid.grid.size`. 
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


## Sync HSlider with `maze.grid.size.x`, HSlider tooltip, and `maze.grid.start_coords.x` max value.
func _on_settings_grid_x_value_changed(value: float) -> void:
	maze.grid.size.x = floor(value)
	_update_settings_grid_size_tooltip(X)
	_update_settings_start_coords_max_value(X)


## Sync HSlider with `maze.grid.size.y`, HSlider tooltip, and `maze.grid.start_coords.y` max value.
func _on_settings_grid_y_value_changed(value: float) -> void:
	maze.grid.size.y = floor(value)
	_update_settings_grid_size_tooltip(Y)
	_update_settings_start_coords_max_value(Y)


## Switch to the Preview tab when the Preview button is pressed on the Settings UI.
func _on_settings_preview_button_up() -> void:
	tab_container.set_current_tab(Tab.PREVIEW)


## Sync SpinBox value with `maze.grid.start_coords.x`.
func _on_settings_start_coords_x_value_changed(value: float) -> void:
	_update_settings_start_coords(X, value)


## Sync SpinBox value with `maze.grid.start_coords.y`.
func _on_settings_start_coords_y_value_changed(value: float) -> void:
	_update_settings_start_coords(Y, value)


## When switching back to the Preview tab, call `maze.generate()` if any settings have changed.
func _on_tab_container_tab_changed(tab: int) -> void:
	if tab as Tab == Tab.PREVIEW and has_settings_changed():
		last_grid_size = maze.grid.size
		maze.generate()


## Displays numeric value in tooltip when hovering over an HSlider in the Settings UI.
func _update_settings_grid_size_tooltip(axis: String) -> void:
	settings_grid[axis].set_tooltip_text("%d" % maze.grid.size[axis])


## Updates `maze.grid.start_coords`, ensuring x and y values are either both -1, or both > -1. This
## is because the minimum `maze.grid.start_coords` value is Vector2i(0, 0). Vector2i(-1, -1) is
## used to indicate that a random position should be chosen, which is why -1 is allowed as a value
## in the Settings UI. However, a value of Vector2i(-1, 3) for example, would be invalid and so it
## must not be allowed.
func _update_settings_start_coords(axis: StringName, value: float) -> void:
	var other_axis: StringName = Y if axis == X else X
	var max_value: int = maze.grid.size[axis] - 1
	
	# Ensure the value is constrained to the valid range, based on `maze.grid.size`.
	maze.grid.start_coords[axis] = clampi(floor(value), -1, max_value)
	
	# If the value being set is -1, set the other axis value to also be -1.
	if maze.grid.start_coords[axis] == -1:
		maze.grid.start_coords[other_axis] = -1
		settings_start_coords[other_axis].set_value(-1)
	
	# If the other value is -1 and the value beind set is greater, set the other axis value to 0.
	elif maze.grid.start_coords[other_axis] == -1:
		maze.grid.start_coords[other_axis] = 0
		settings_start_coords[other_axis].set_value(0)


## When `maze.grid.size` changes, update the corresponding `maze.grid.start_coords` max value.
func _update_settings_start_coords_max_value(axis: String) -> void:
	var max_value: int = maze.grid.size[axis] - 1
	
	# Update the SpinBox max value in the Settings UI.
	settings_start_coords[axis].set_max(max_value)
	
	# If `maze.grid.start_coords` value is above max, set it to `max_value` and update SpinBox value.
	if maze.grid.start_coords[axis] > max_value:
		maze.grid.start_coords[axis] = max_value
		settings_start_coords[axis].value = max_value
