extends Node2D

## Maze node, where all the maze generation logic lives.
@onready var maze: Maze = $Maze

## Maze preview, used to displaying `maze` layout as rich text.
@onready var maze_preview: RichTextLabel = $MazePreview

## TabContainer where `maze_preview` will be displayed, alongside a Settings tab. 
@onready var ui: TabContainer = $UI


## Runs once when the node is added to the scene tree.
func _ready() -> void:
	# Connect signals to the appropriate handler methods.
	_connect_signals()
	
	# Update value of `preview_maze` RichTextLabel with BBCode representation of `maze`.
	draw_maze()


## Updates value of `preview_maze` RichTextLabel with BBCode representation of `maze`.
func draw_maze() -> void:
	# Wrap the rich text representation of `maze`, to center it horizontally.
	var rich_text: String = "[center]%s[/center]" % maze.grid.to_rich_text()
	
	# Update the RichTextLabel text value.
	maze_preview.set_text(rich_text)


## Connects signals to the appropriate handler methods.
func _connect_signals() -> void:
	ui.draw_maze.connect(_on_ui_draw_maze)


## Redraw the maze when the UI indicates that it is ready to be redrawn.
func _on_ui_draw_maze() -> void:
	draw_maze()
