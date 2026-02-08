extends Control

@export var start_button : TextureRect
var duration : float = 0.5
var tween : Tween

func _ready() -> void:
	
	tween = get_tree().create_tween().set_loops()
	
	tween.tween_property(start_button,"scale",Vector2.ONE * 1.35,duration)

	tween.tween_property(start_button,"scale",Vector2.ONE,duration)


func _on_start_button_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
			tween.stop()
			get_tree().change_scene_to_file("res://scenes/game_2_0.tscn")
