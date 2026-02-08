extends State
# if we lose we get sent to this state, we reset the game stats and start all over

@export var explosion_sfx : AudioStreamPlayer2D
@export var explosion_tex : AnimatedSprite2D

func enter() -> void:
	print("Entered: %s State" % name)
	Singleton.stage = 1
	root.animation_player.play("Lost")
	var pos : Vector2 = root.selected_cell_index * Singleton.CellSize
	explosion_sfx.position = pos
	explosion_tex.position = pos + Vector2(8,8)
	explosion_tex.play("default")
	explosion_sfx.play()
	
	show_all_bomb_locations()

func exit() -> void:
	print("Exited: %s State" % name)

func process_input(_event: InputEvent) -> State:
	return null

func update(_delta: float) -> State:
	if not root.animation_player.is_playing():
		return state_machine.states.ready
	return null

func physics_update(_delta: float) -> State:
	return null

func show_all_bomb_locations() -> void:
	for bomb_index in root.bomb_locations:
		var id : int = root.index_2_id(bomb_index)
		var cell : TextureRect = root.cells[id]
		root.smooth_alpha(cell)
