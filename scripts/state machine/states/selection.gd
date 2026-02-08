extends State
## Selection allows the player to select tiles and when a tile is selected we move to condition

func enter() -> void:
	print("Entered: %s State" % name)
	root.selector.visible = true
	root.selector.modulate.a = 0
	root.smooth_alpha(root.selector,0.65)

func exit() -> void:
	print("Exited: %s State" % name)
	root.selector.visible = false

func process_input(_event: InputEvent) -> State:
	if _event is InputEventMouseMotion:
		var mouse_pos : Vector2 = _event.global_position
		var cell_index : Vector2i = root.get_cell_index(mouse_pos)
		
		if cell_index.x == -1 or cell_index.y == -1:
				return
		
		root.selector.position = cell_index * Singleton.CellSize
	
	elif _event is InputEventMouseButton:
		
		if _event.button_index == MOUSE_BUTTON_RIGHT and _event.is_pressed():
			var mouse_pos : Vector2 = _event.global_position
			var cell_index : Vector2i = root.get_cell_index(mouse_pos)
			
			if cell_index.x == -1 or cell_index.y == -1:
				return
			
			handle_chao_marker(cell_index)
			
		elif _event.button_index == MOUSE_BUTTON_LEFT and _event.is_pressed():
			var mouse_pos : Vector2 = _event.global_position
			var cell_index : Vector2i = root.get_cell_index(mouse_pos)
			
			if cell_index.x == -1 or cell_index.y == -1:
				return
			
			#var type : Singleton.TT = root.data[root.index_2_id(cell_index)]
			
			root.selected_cell_index = cell_index
			return state_machine.states.condition
			
	return null

func update(_delta: float) -> State:
	if Singleton.collected_cells == Singleton.collection_target:
		return state_machine.states.won
	
	return null

func physics_update(_delta: float) -> State:
	return null

func handle_chao_marker(index : Vector2i) -> void:
	
	var id : int = root.index_2_id(index)
	var type : Singleton.TT = root.data[id]
	
	if type == Singleton.TT.HIDDEN or type == Singleton.TT.BOMB:
	
		match root.guesses.has(index):
			true:
				Singleton.bomb_guesses -= 1
				var tex : AnimatedTexture
				
				if type == Singleton.TT.BOMB:
					tex = root.bomb_texture
				else:
					tex = root.cell_texture.duplicate(true)
					tex.resource_local_to_scene = true
					
				root.cells[id].texture = tex
				if root.debug_present_bombs and type == Singleton.TT.BOMB:
					root.cells[id].modulate.a = 1
				else:
					root.cells[id].modulate.a = 0
				
				root.guesses.erase(index)
			false:
				Singleton.bomb_guesses += 1
				var tex : AnimatedTexture = root.marker_texture
				root.cells[id].texture = tex
				root.smooth_alpha(root.cells[id])
				root.guesses.append(index)
		
		root.set_number(Singleton.bomb_guesses,root.guess_counter)
