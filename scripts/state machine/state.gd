class_name State
extends Node

var root: Game
var state_machine: StateMachine

func enter() -> void:
	pass

func exit() -> void:
	pass

func process_input(_event: InputEvent) -> State:
	return null

func update(_delta: float) -> State:
	return null

func physics_update(_delta: float) -> State:
	return null
