extends State
# If we won we get transitioned to this state and we increment the game difficulty here
# where we get set back into the ready state

var wait_time : float = 0.5
var entered_time : float = 0.0

func enter() -> void:
	print("Entered: %s State" % name)
	Singleton.stage += 1
	entered_time = Time.get_ticks_msec() / 1000.0
	root.animation_player.play("Victory")

func exit() -> void:
	print("Exited: %s State" % name)

func process_input(_event: InputEvent) -> State:
	return null

func update(_delta: float) -> State:
	
	if root.animation_player.is_playing():
		entered_time = Time.get_ticks_msec() / 1000.0
	
	var current_time : float = Time.get_ticks_msec() / 1000.0
	if (current_time - entered_time) > wait_time:
		return state_machine.states.ready
	
	return null
	
func physics_update(_delta: float) -> State:
	return null
