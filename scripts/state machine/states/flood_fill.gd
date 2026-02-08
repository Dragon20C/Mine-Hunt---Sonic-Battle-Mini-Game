extends State
# In this state we simply flood fill the field until there is no more hidden tiles

var update_queue : Array[Vector2i]

func enter() -> void:
	print("Entered: %s State" % name)
	update_queue.clear()
	dfs(root.selected_cell_index)
	update_tiles_in_queue()

func exit() -> void:
	print("Exited: %s State" % name)

func process_input(_event: InputEvent) -> State:
	return null

func update(_delta: float) -> State:
	if Singleton.collected_cells == Singleton.collection_target:
		return state_machine.states.won
	else:
		return state_machine.states.selection

func physics_update(_delta: float) -> State:
	return null

func dfs(index : Vector2i) -> void:
	# bounds
	var field_size : Vector2i = Singleton.field_size
	if index.x < 0 or index.x >= field_size.x or index.y < 0 or index.y >= field_size.y:
		return

	var id : int = root.index_2_id(index)

	# already processed or not eligible
	if root.data[id] != Singleton.TT.HIDDEN:
		return

	var bombs : int = root.search_for_bombs(index)

	# boundary tile (number tile)
	if bombs > 0:
		if not update_queue.has(index):
			root.data[id] = Singleton.TT.NEAR
			update_queue.append(index)
		return

	# empty tile
	root.data[id] = Singleton.TT.NONE
	Singleton.collected_cells += 1
	# This is to override guesses
	if root.guesses.has(index):
		root.guesses.erase(index)
		root.cells[id].texture = root.cell_texture.duplicate(true)
		root.cells[id].texture.resource_local_to_scene = true
		
	root.smooth_alpha(root.cells[id], 0.25)

	for dy in range(-1, 2):
		for dx in range(-1, 2):
			if dx == 0 and dy == 0:
				continue
			dfs(index + Vector2i(dx, dy))

# I store cells that are near a bomb, so I need a function to update those tiles and set bomb count
func update_tiles_in_queue() -> void:
	for queue_index in update_queue:
		var queue_bombs : int = root.search_for_bombs(queue_index)
		root.set_near_count(queue_index,queue_bombs)
