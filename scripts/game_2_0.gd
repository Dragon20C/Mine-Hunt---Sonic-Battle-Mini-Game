extends Control
class_name Game

@export_group("Config")
@export var debug_present_bombs : bool = false

@export_group("Nodes")
@export var state_machine : StateMachine
@export var field : GridContainer
@export var selector : TextureRect
@export var digits : Array[Texture2D]
@export var background : TextureRect
@export var stage_counter : HBoxContainer
@export var guess_counter : HBoxContainer
@export var bomb_counter  : HBoxContainer
@export var animation_player : AnimationPlayer

@export_group("Textures")
@export var cell_texture   : AnimatedTexture
@export var marker_texture : AnimatedTexture
@export var bomb_texture   : AnimatedTexture

## Private variables ##
## Holds information about the whole field 
var data : Array[Singleton.TT]
## A cell is the visual representation of the data
var cells : Array[TextureRect]
## Holding guesses indexes
var guesses : Array[Vector2i]
## A simple variable to store the found cell index when moving between states
var selected_cell_index : Vector2i = Vector2i.ZERO
## A simple array for storing bomb locations
var bomb_locations : Array[Vector2i]
## The initial starting position for the background
var bg_origin_point : Vector2

func _ready() -> void:
	state_machine.init(self)

func index_2_id(index : Vector2i) -> int:
	return index.y * Singleton.field_size.x + index.x

func set_number(value: int, container : Control) -> void:
	value = clamp(value, 0, 999)
	
	var digit_nodes : Array = container.get_children()
	
	# Set all digits to zero
	for node : TextureRect in digit_nodes:
		node.texture = digits[0]
	
	var nodes : int = digit_nodes.size()
	var i : int = nodes - 1
	var n : int = value
	
	while i >= 0 and n > 0:
		var digit := n % 10
		digit_nodes[i].texture = digits[digit]
		n /= 10
		i -= 1

func get_cell_index(mouse_pos : Vector2) -> Vector2i:
	var bounds : Vector2i = Singleton.field_size
	var cell_size : int = Singleton.CellSize
	var cell_index : Vector2i
	cell_index.x = floori(mouse_pos.x / cell_size)
	cell_index.y = floori(mouse_pos.y / cell_size)
	
	# out of bounds check
	if cell_index.x < 0 or cell_index.x > bounds.x - 1:
		return Vector2i(-1,-1)
	
	if cell_index.y < 0 or cell_index.y > bounds.y - 1:
		return Vector2i(-1,-1)
	
	return cell_index

func smooth_alpha(cell : TextureRect,duration : float = 0.25) -> void:
	var tween : Tween = get_tree().create_tween()
	tween.tween_property(cell,"modulate:a",1.0,duration).set_ease(Tween.EASE_OUT)

func search_for_bombs(index : Vector2i) -> int:
	var field_size : Vector2i = Singleton.field_size
	var bombs_near : int = 0
	
	for y in range(-1,2):
		for x in range(-1,2):
			# ignore the center tile
			if x == 0 and y == 0:
				continue
			# grab the next index
			var next_index : Vector2i = index + Vector2i(x,y)
			# check if the next_index is out of bounds
			if next_index.x < 0 or next_index.x > field_size.x - 1:
				continue
			if next_index.y < 0 or next_index.y > field_size.y - 1:
				continue
			
			var id : int = index_2_id(next_index)
			if data[id] == Singleton.TT.BOMB:
				bombs_near += 1
		
	return bombs_near

func set_near_count(index : Vector2i, bomb_amount : int) -> void:
	var id : int = index_2_id(index)

	var state : Singleton.TT = data[id]
	if state == Singleton.TT.NEAR or state == Singleton.TT.HIDDEN:
		# delete the guess
		if guesses.has(index):
			guesses.erase(index)
			cells[id].texture = Singleton.cell_texture.duplicate()
			cells[id].texture.resource_local_to_scene = true
		
		data[id] = Singleton.TT.NEAR
		var tile : TextureRect = cells[id]

		tile.texture.set_current_frame(bomb_amount)
		smooth_alpha(tile, 0.35)
		Singleton.collected_cells += 1

func animate_background() -> void:
	if not bg_origin_point:
		bg_origin_point = background.position
	
	var rand_offset : Vector2 = Vector2(randi_range(-100, 100), randi_range(-100, 100))
	
	background.position = bg_origin_point + rand_offset
	
	var tweener : Tween = get_tree().create_tween()
	
	tweener.parallel().tween_property(background,"position",bg_origin_point,1.0).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)

	await tweener.finished
	
	queue_redraw()
