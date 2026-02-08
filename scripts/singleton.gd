extends Node


#@onready var cell_texture   : AnimatedTexture = preload("res://objects/hint_animation.tres")
#@onready var bomb_texture   : AnimatedTexture = preload("res://objects/bomb_animation.tres")
#@onready var marker_texture : AnimatedTexture = preload("res://objects/chao_animation.tres")
## TileType
enum TT {HIDDEN,NONE,NEAR,BOMB}
## How big a cell is in pixel
const CellSize : int = 16
## The grid size x = width, y = height
var field_size : Vector2i = Vector2i(12,10)
## The difficulty stage we are current at
var stage : int = 1
## The amount of bombs we place on the field
var bombs : int = 10
## A simple counter for guesses
var bomb_guesses : int = 0
## Win condition target
var collection_target : int = 0
## currently collected cells
var collected_cells:  int = 0
## A simple boolean to check if the field is already made
var field_created : bool = false


func reset_game() -> void:
	bomb_guesses = 0
	collection_target = 0
	collected_cells = 0
	
