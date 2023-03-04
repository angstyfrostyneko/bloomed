extends Node


func _ready():
	NetworkManager.start_hosting(42424)
	get_tree().change_scene_to_file("res://DedicatedServer/ServerMain.tscn")
