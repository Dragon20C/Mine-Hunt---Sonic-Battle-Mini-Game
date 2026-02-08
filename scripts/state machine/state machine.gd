class_name StateMachine
extends Node

@export var initial_state: State
var current_state: State
var states: Dictionary = {}

func init(root : Game) -> void:
	for child in get_children():
		if child is State:
			states[child.name.to_lower()] = child
			child.root = root
			child.state_machine = self
	
	if initial_state:
		initial_state.enter()
		current_state = initial_state

func _input(event: InputEvent) -> void:
	var new_state = current_state.process_input(event)
	if new_state:
		switch_state(new_state)

func _process(delta: float) -> void:
	var new_state = current_state.update(delta)
	if new_state:
		switch_state(new_state)

func _physics_process(delta: float) -> void:
	var new_state = current_state.physics_update(delta)
	if new_state:
		switch_state(new_state)

func switch_state(new_state: State) -> void:
	if not new_state or current_state == new_state:
		return
	
	current_state.exit()
	current_state = new_state
	current_state.enter()
