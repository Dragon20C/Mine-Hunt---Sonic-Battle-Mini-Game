extends State
## Ready state setups the game field based on a singleton/global script


func enter() -> void:
	print("Entered: %s State" % name)
	root.selector.visible = false
	match Singleton.field_created:
		true:
			Singleton.reset_game()
			reset_field()
			place_bombs()
		false:
			create_field()
			place_bombs()
			Singleton.field_created = true
	# Update the stage counter and bomb counter
	root.set_number(Singleton.stage,root.stage_counter)
	root.set_number(Singleton.bombs,root.bomb_counter)
	root.set_number(Singleton.bomb_guesses,root.guess_counter)
	
	root.animate_background()
	root.animation_player.play("Intro")

func exit() -> void:
	print("Exited: %s State" % name)

func process_input(_event: InputEvent) -> State:
	return null

func update(_delta: float) -> State:
	if not root.animation_player.is_playing():
		return state_machine.states.selection
	
	return null

func physics_update(_delta: float) -> State:
	return null

func create_field() -> void:
	var size : Vector2i = Singleton.field_size
	
	var array_length : int = size.x * size.y
	# this is how we calculate the win condition target
	Singleton.collection_target = array_length - Singleton.bombs
	
	# resize array
	root.data.resize(array_length)
	root.cells.resize(array_length)
	
	for i in range(array_length):
		# create a cell
		var cell : TextureRect = TextureRect.new()
		# setup the cell
		cell.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
		cell.custom_minimum_size = Vector2i.ONE * Singleton.CellSize
		# create the texture for the initial game
		var texture : AnimatedTexture = root.cell_texture.duplicate(true)
		texture.resource_local_to_scene = true
		# apply the texture to the cell and make it transparent
		cell.texture = texture
		cell.modulate.a = 0
		# assign it to the cells array
		root.cells[i] = cell
		# add it to the field as a child
		root.field.add_child(cell)
		# update the data to present as hidden
		root.data[i] = Singleton.TT.HIDDEN

## reset field ## is similar to create field apart from we dont create new cells
func reset_field() -> void:
	var size : Vector2i = Singleton.field_size
	
	var array_length : int = size.x * size.y
	Singleton.collection_target = array_length - Singleton.bombs
	
	for i in range(array_length):
		var texture : AnimatedTexture = root.cell_texture.duplicate(true)
		texture.resource_local_to_scene = true
		
		root.cells[i].texture = texture
		root.cells[i].modulate.a = 0
		
		root.data[i] = Singleton.TT.HIDDEN

func place_bombs() -> void:
	
	root.bomb_locations.clear()
	
	var field_size : Vector2i = Singleton.field_size
	var current_count : int = 0
	
	while current_count < Singleton.bombs:
		var rand_grid_index : Vector2i
		rand_grid_index.x = randi_range(0,field_size.x - 1)
		rand_grid_index.y = randi_range(0,field_size.y - 1)
		
		var id : int = root.index_2_id(rand_grid_index)
		var cell : TextureRect = root.cells[id]
		var data : Array = root.data
		match data[id]:
			Singleton.TT.HIDDEN:
				data[id] = Singleton.TT.BOMB
				cell.texture = root.bomb_texture
				#cell.texture.set_current_frame(0)
				current_count += 1
				root.bomb_locations.append(rand_grid_index)
				
				if root.debug_present_bombs:
					#cell.texture = Singleton.bomb_texture
					cell.modulate.a = 1
				
			Singleton.TT.BOMB:
				continue
