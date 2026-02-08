extends State
# In the condition state we decide what we do, if the selected tile is near a bomb
# we simply update that tile, if it is a bomb we transition to lost state
# but if the tile is empty e.g no bombs near it transition to flood fill state

var index : Vector2i
var return_state : State = null

func enter() -> void:
	print("Entered: %s State" % name)
	index = root.selected_cell_index
	
	var id : int = root.index_2_id(index)
	var type : Singleton.TT = root.data[id]
	
	if type == Singleton.TT.BOMB:
		return_state = state_machine.states.lost
		return
	
	if type != Singleton.TT.HIDDEN:
		return_state = state_machine.states.selection
		return
	
	var bombs_found : int = root.search_for_bombs(index)
	
	if bombs_found > 0:
		root.set_near_count(index,bombs_found)
		return_state = state_machine.states.selection
	else:
		return_state = state_machine.states.floodfill
	

func exit() -> void:
	print("Exited: %s State" % name)
	index = Vector2i.ZERO
	return_state = null

func process_input(_event: InputEvent) -> State:
	return null

func update(_delta: float) -> State:
	return return_state

func physics_update(_delta: float) -> State:
	return null
