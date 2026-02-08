extends Node2D


@export_group("Settings")
@export var grid_size : Vector2i = Vector2i(12,10)
@export var bomb_count : int = 10
@export var show_bomb_locations : bool = false
@export var stage : int = 1
@export var numbers : Array[Texture2D]

@export_group("Node Requirments")
@export var grid_container : GridContainer
@export var background : TextureRect
@export var selector : TextureRect
@export var stage_indicator_container : HBoxContainer
@onready var hint_tile_anim : AnimatedTexture = preload("res://objects/hint_animation.tres")
@onready var bomb_tile_anim : AnimatedTexture = preload("res://objects/bomb_animation.tres")
@onready var guess_tile_anim : AnimatedTexture = preload("res://objects/chao_animation.tres")

enum GameState {Menu,Select,Game,CheckCondition,Won,Lost,Wait}
enum TileState {HIDDEN,NONE,NEAR,BOMB}
var current_gs : GameState = GameState.Game
var tile_index : Vector2i = Vector2i.ZERO


var collected_tiles : int = 0
var target_collected_tiles : int = 0

var data : Array[TileState]
var tiles : Array[TextureRect] = []
var guesses : Array[Vector2i] = []
var update_queue : Array[Vector2i]
var tile_size : int = 16
var bg_origin_point : Vector2 = Vector2.ZERO
var wait_amount : int = 3
var wait_counter : float = 0.0
var grid_alpha : float = 0.0 # Goes to 0.098


func _ready() -> void:
	set_number(12)
	#update_stage_indicator()
	
func _input(event: InputEvent) -> void:
	
	if current_gs != GameState.Select:
		return
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
			var mouse_position : Vector2 = event.global_position
			var grid_position : Vector2i
			
			grid_position.x = floori(mouse_position.x / tile_size)
			grid_position.y = floori(mouse_position.y / tile_size)
			
			if grid_position.x > grid_size.x - 1:
				return
			elif grid_position.y > grid_size.y - 1:
				return
						
			tile_index = grid_position
			current_gs = GameState.CheckCondition
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.is_pressed():
			var mouse_position : Vector2 = event.global_position
			var grid_position : Vector2i
			
			grid_position.x = floori(mouse_position.x / tile_size)
			grid_position.y = floori(mouse_position.y / tile_size)
			
			if grid_position.x > grid_size.x - 1:
				return
			elif grid_position.y > grid_size.y - 1:
				return
			
			var id : int = convert_index(grid_position)
			
			var tile : TextureRect = tiles[id]
			var state : TileState = data[id]
			if state == TileState.HIDDEN or state == TileState.BOMB:
				
				if guesses.has(grid_position):
					guesses.erase(grid_position)
					tile.modulate.a = 0
					var anim : AnimatedTexture = hint_tile_anim.duplicate()
					anim.resource_local_to_scene = true
					tile.texture = anim
				else:
					guesses.append(grid_position)
					tile.modulate.a = 1
					tile.texture = guess_tile_anim
			#match guesses.has(grid_position):
				#true:
					#var anim : AnimatedTexture = hint_tile_anim.duplicate()
					#anim.resource_local_to_scene = true
					#tiles[id].texture = anim
					#tiles[id].modulate.a = 0
					#print(tiles[id].modulate.a)
					#guesses.erase(grid_position)
				#false:
					#tiles[id].texture = guess_tile_anim
					#animate_alpha(tiles[id])
					#guesses.append(grid_position)
						
	elif event is InputEventMouseMotion:
		var mouse_position : Vector2 = event.global_position
		var grid_position : Vector2i
			
		grid_position.x = clampi(floori(mouse_position.x / tile_size),0,grid_size.x -  1)
		grid_position.y = clampi(floori(mouse_position.y / tile_size),0,grid_size.y - 1)
		
		selector.position = grid_position * tile_size
		
func _process(_delta: float) -> void:
	handle_game_state()

func _draw() -> void:
	if current_gs != GameState.Select:
		return
	for y in range(grid_size.y):
		for x in range(grid_size.x):
			var grid_position: Vector2 = (Vector2(x, y) * tile_size)
						
			draw_rect(
				Rect2(grid_position, Vector2(tile_size, tile_size)),
				Color(1.0, 1.0, 1.0, 0.098),   # fill color
				false,                 # false = outline only (grid lines)
				1.0
			)

func handle_game_state() -> void:
	
	match current_gs:
		GameState.Menu:
			pass
		GameState.Game:
			selector.visible = false
			randomize()
			
			var total : int = grid_size.x * grid_size.y
			collected_tiles = 0
			target_collected_tiles = total - bomb_count
			
			generate_grid()
			place_bombs()
			
			animate_background()
			current_gs = GameState.Select
		GameState.Select:
			
			if selector.visible == false:
				selector.visible = true
			
		GameState.CheckCondition:
			
			var id : int = convert_index(tile_index)
			# check what options we have
			match data[id]:
				TileState.HIDDEN:
					var bombs : int = search_for_bombs(tile_index)
					
					# if no bombs are found, we have found an empty tile
					# so we flood fill it!
					if bombs == 0:
						dfs(tile_index)
						
						for queue_index in update_queue:
							var queue_bombs : int = search_for_bombs(queue_index)
							set_near_count(queue_index,queue_bombs)
						update_queue.clear()
					else:
						# if its not empty we just update the tile to show 
						# how many bombs exist near by
						set_near_count(tile_index,bombs)
					
					if collected_tiles == target_collected_tiles:
						current_gs = GameState.Won
						return
					else:
						print("Current %s, Total %s" % [collected_tiles,target_collected_tiles])
						print(collected_tiles == target_collected_tiles)
						current_gs = GameState.Select
					
				TileState.BOMB:
					selector.visible = false
					show_bombs()
					current_gs = GameState.Lost
					return
				_:
					current_gs = GameState.Select
					return
			
		GameState.Won:
			print("You won!")
			current_gs = GameState.Wait
		GameState.Lost:
			print("You lost...")
			current_gs = GameState.Wait
		GameState.Wait:
			wait_counter += get_physics_process_delta_time()
			
			if wait_counter >= wait_amount:
				wait_counter = 0.0
				current_gs = GameState.Game

func generate_grid() -> void:
	var total : int = grid_size.x * grid_size.y
	
	# clear the data and tiles if we are reseting a game
	tiles.clear()
	data.clear()
	
	tiles.resize(total)
	data.resize(total)
	
	# clear the container if children exist
	if grid_container.get_child_count() > 0:
		for child in grid_container.get_children():
			child.queue_free()
	
	for i in range(total):
		var tile : TextureRect = TextureRect.new()
		
		var anim : AnimatedTexture = hint_tile_anim.duplicate()
		anim.resource_local_to_scene = true
		
		tile.texture = anim
		tile.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
		tile.custom_minimum_size = Vector2i.ONE * tile_size
		
		grid_container.add_child(tile)
		
		tile.modulate.a = 0
		
		tiles[i] = tile
		data[i] = TileState.HIDDEN

func place_bombs() -> void:
	var current_count : int = 0
	
	while current_count < bomb_count:
		var rand_grid_index : Vector2i
		rand_grid_index.x = randi_range(0,grid_size.x - 1)
		rand_grid_index.y = randi_range(0,grid_size.y - 1)
		
		var id : int = convert_index(rand_grid_index)
		var tile : TextureRect = tiles[id]
		match data[id]:
			TileState.HIDDEN:
				data[id] = TileState.BOMB
				tile.texture.set_current_frame(0)
				current_count += 1
				
				if show_bomb_locations:
					tile.texture = bomb_tile_anim
					tile.modulate.a = 1
				
			TileState.BOMB:
				continue

func search_for_bombs(index : Vector2i) -> int:
	var bombs_near : int = 0
	
	for y in range(-1,2):
		for x in range(-1,2):
			# ignore the center tile
			if x == 0 and y == 0:
				continue
			# grab the next index
			var next_index : Vector2i = index + Vector2i(x,y)
			# check if the next_index is out of bounds
			if next_index.x < 0 or next_index.x > grid_size.x - 1:
				continue
			if next_index.y < 0 or next_index.y > grid_size.y - 1:
				continue
			
			var id : int = convert_index(next_index)
			if data[id] == TileState.BOMB:
				bombs_near += 1
		
	return bombs_near

func set_near_count(index : Vector2i, bomb_amount : int) -> void:
	var id : int = convert_index(index)

	var state : TileState = data[id]
	if state == TileState.NEAR or state == TileState.HIDDEN:

		data[id] = TileState.NEAR
		var tile : TextureRect = tiles[id]

		tile.texture.set_current_frame(bomb_amount)
		animate_alpha(tile, 0.35)
		collected_tiles += 1


func dfs(index : Vector2i) -> void:
	# bounds
	if index.x < 0 or index.x >= grid_size.x or index.y < 0 or index.y >= grid_size.y:
		return

	var id : int = convert_index(index)

	# already processed or not eligible
	if data[id] != TileState.HIDDEN:
		return

	var bombs : int = search_for_bombs(index)

	# boundary tile (number tile)
	if bombs > 0:
		if not update_queue.has(index):
			data[id] = TileState.NEAR
			update_queue.append(index)
		return

	# empty tile
	data[id] = TileState.NONE
	collected_tiles += 1
	animate_alpha(tiles[id], 0.25)

	for dy in range(-1, 2):
		for dx in range(-1, 2):
			if dx == 0 and dy == 0:
				continue
			dfs(index + Vector2i(dx, dy))



func show_bombs() -> void:
	for y in range(grid_size.y):
		for x in range(grid_size.x):
			var index : Vector2i = Vector2i(x,y)
			var id : int = convert_index(index)
			if data[id] == TileState.BOMB:
				tiles[id].texture = bomb_tile_anim
				animate_alpha(tiles[id])
				
## Converts a 2d grid index into a 1d index
func convert_index(index : Vector2i) -> int:
	return index.y * grid_size.x + index.x

func update_stage_indicator() -> void:
	
	if stage < 10:
		var children := stage_indicator_container.get_children()
		children[-1].texture = numbers[stage]
	else:
		pass

func set_number(value: int) -> void:
	value = clamp(value, 0, 999)
	
	var digits : Array = stage_indicator_container.get_children()
	# Optional: clear all digits first
	for node : TextureRect in digits:
		node.texture = numbers[0]
	var nodes : int = 3
	var i : int = nodes - 1
	var n : int = value

	while i >= 0 and n > 0:
		var digit := n % 10
		digits[i].texture = numbers[digit]
		n /= 10
		i -= 1

func animate_background() -> void:
	if not bg_origin_point:
		bg_origin_point = background.position
	
	var rand_offset : Vector2 = Vector2(randi_range(0, 50), randi_range(0, 50))
	
	background.position = bg_origin_point + rand_offset
	
	var tweener : Tween = get_tree().create_tween()
	
	tweener.parallel().tween_property(background,"position",bg_origin_point,1.0).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)

	await tweener.finished
	
	queue_redraw()

func animate_alpha(tile : TextureRect, duration : float = 1.0) -> void:
	var tweener : Tween = get_tree().create_tween()
	tweener.tween_property(tile,"modulate:a",1,duration).set_trans(Tween.TRANS_CUBIC)
