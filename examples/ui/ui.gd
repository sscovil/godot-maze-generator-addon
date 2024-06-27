extends TabContainer

signal draw_maze

## References for the TabContainer tab indices.
enum Tab {
	PREVIEW,
	SETTINGS,
}

## Syntactic sugar; use X as a Dictionary key instead of the string "x".
const X: StringName = "x"

## Syntactic sugar; use Y as a Dictionary key instead of the string "y".
const Y: StringName = "y"

## Maze child node.
@export var maze: Maze

## RichTextLabel where BBCode representation of Maze is displayed.
@export var maze_preview: Node

## Used to detect changes to the Settings UI, when toggling between preview loading options.
var current_preview_option: CheckButton

## Used to detect changes in the Settings UI, when switching back to the Preview UI.
var last_grid_size: Vector2i

## Used to detect changes to the Settings UI, when toggling between preview loading options.
var last_preview_option: CheckButton

## Used to detect changes in the Settings UI, when switching back to the Preview UI.
var last_start_coords: Vector2i

## Used to make `settings_preview_options` CheckButtons behave like radio buttons.
var settings_preview_options_group := ButtonGroup.new()

## If `true`, a progress bar will be displayed when generating the maze; if `false` (default), the
## maze will be redrawn at each increment, as it is generated.
var show_progress_bar: bool = false

## ProgressBar displayed when generating a new Maze.
@onready var preview_progress_bar: ProgressBar = $Preview/ProgressBar

## Container for `maze_preview` and `preview_progress_bar`.
@onready var preview_tab: Container = $Preview

## HSlider nodes in the Settings UI, used for adjusting `maze.grid.size`.
@onready var settings_grid: Dictionary = {
	X: $Settings/List/GridX,
	Y: $Settings/List/GridY,
}

## Button in the Settings UI, used for switching back to the Preview tab.
@onready var settings_preview: Button = $Settings/List/Preview

## CheckButton group in the Settings UI, used toggle between different maze preview loading options.
@onready var settings_preview_options: Dictionary = {
	"show_nothing": $Settings/List/PreviewOptionShowNothing,
	"show_progress_bar": $Settings/List/PreviewOptionShowProgressBar,
	"show_maze": $Settings/List/PreviewOptionShowMaze,
}

## SpinBox nodes in the Settings UI, used for adjusting `maze.grid.start_coords`.
@onready var settings_start_coords: Dictionary = {
	X: $Settings/List/StartCoordsContainer/StartX,
	Y: $Settings/List/StartCoordsContainer/StartY,
}


## Run once when the node is added to the scene tree.
func _ready() -> void:
	# Generate the initial GridMaze.
	maze.generate()
	
	# Initialize values for the Settings UI.
	_initialize_settings()
	
	# Connect signals to the appropriate handler methods.
	_connect_signals()
	
	# Reparent the `maze_preview` node so it appears within the Preview tab.
	if maze_preview.is_inside_tree():
		maze_preview.reparent.call_deferred(preview_tab)
	else:
		preview_tab.add_child.call_deferred(maze_preview)


## Called for each unhandled InputEvent.
func _unhandled_key_input(event: InputEvent) -> void:
	# Ignore any input that is not a keyboard input.
	if not event is InputEventKey:
		return
	
	# Regenerate the Maze when the R key is pressed on the Preview tab.
	if is_current_tab_preview() and event.keycode == KEY_R and event.is_pressed():
		maze.generate()


## Returns `true` if the `maze.grid.size` value changed since `maze.generate()` was last called.
func has_grid_size_changed() -> bool:
	return last_grid_size != maze.grid.size


## Returns `true` if the `current_preview_option` value changed.
func has_preview_option_changed() -> bool:
	return last_preview_option != current_preview_option


## Returns `true` if any settings have changed since `maze.generate()` was last called.
func has_settings_changed() -> bool:
	return has_grid_size_changed() or has_start_coords_changed() or has_preview_option_changed()


## Returns `true` if the `maze.grid.start_coords` value changed since `maze.generate()` was last called.
func has_start_coords_changed() -> bool:
	return last_start_coords != maze.grid.start_coords


## Returns `true` if the current tab is the Preview tab.
func is_current_tab_preview() -> bool:
	return Tab.PREVIEW == current_tab


## Returns `true` if the current tab is the Settings UI.
func is_current_tab_settings() -> bool:
	return Tab.SETTINGS == current_tab


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
	
	# Used to toggle between the different preview loading options.
	settings_preview_options_group.pressed.connect(_on_settings_preview_options_group_pressed)
	
	# Used to update `maze.grid.start_coords` based on changes in the Settings UI.
	settings_start_coords[X].value_changed.connect(_on_settings_start_coords_x_value_changed)
	settings_start_coords[Y].value_changed.connect(_on_settings_start_coords_y_value_changed)
	
	# Used to regenerate `maze` if necessary, when switching to the Preview tab.
	tab_changed.connect(_on_tab_container_tab_changed)


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
	
	# Group the CheckButton preview options together, so they behave like radio buttons.
	for option: CheckButton in settings_preview_options.values():
		option.set_button_group(settings_preview_options_group)
	
	# Sync maze preview loading options with the selected preview option CheckButton.
	_update_preview_options()


## Hides `maze_preview`, and initializes and shows `preview_progress_bar`.
func _on_grid_generate_begin() -> void:
	if show_progress_bar:
		maze_preview.set_visible(false)
		preview_progress_bar.set_value(0)
		preview_progress_bar.set_visible(true)
	else:
		draw_maze.emit()


## Hides `preview_progress_bar`, and redraws and shows `maze_preview`.
func _on_grid_generate_end() -> void:
	draw_maze.emit()
	
	if show_progress_bar:
		preview_progress_bar.set_visible(false)
		maze_preview.set_visible(true)


## Updates `preview_progress_bar` incrementally, based on `generate_progress` signal data.
func _on_grid_generate_progress(progress: float) -> void:
	if show_progress_bar:
		preview_progress_bar.set_value(progress)
	else:
		draw_maze.emit()


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
	set_current_tab(Tab.PREVIEW)


## Toggle between the different preview loading options.
func _on_settings_preview_options_group_pressed(button: Button) -> void:
	_update_preview_options()


## Sync SpinBox value with `maze.grid.start_coords.x`.
func _on_settings_start_coords_x_value_changed(value: float) -> void:
	_update_settings_start_coords(X, value)


## Sync SpinBox value with `maze.grid.start_coords.y`.
func _on_settings_start_coords_y_value_changed(value: float) -> void:
	_update_settings_start_coords(Y, value)


## When switching back to the Preview tab, call `maze.generate()` if any settings have changed.
func _on_tab_container_tab_changed(tab: int) -> void:
	if tab as Tab == Tab.PREVIEW and has_settings_changed():
		# Update cached settings, to detect future changes.
		last_grid_size = maze.grid.size
		last_preview_option = current_preview_option
		last_start_coords = maze.grid.start_coords
		
		# Wait for next frame so the UI can switch to the Preview tab, then regenerate the maze.
		maze.generate_next_frame()


## When preview options radio button is toggled, update maze preview load configuration.
func _update_preview_options() -> void:
	if settings_preview_options["show_nothing"].is_pressed():
		current_preview_option = settings_preview_options["show_nothing"]
		maze.emit_progress_signals = false
		show_progress_bar = false
	
	elif settings_preview_options["show_progress_bar"].is_pressed():
		current_preview_option = settings_preview_options["show_progress_bar"]
		maze.emit_progress_signals = true
		show_progress_bar = true
	
	elif settings_preview_options["show_maze"].is_pressed():
		current_preview_option = settings_preview_options["show_maze"]
		maze.emit_progress_signals = true
		show_progress_bar = false


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
