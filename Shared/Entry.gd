extends Node


func _ready():
	if ("--server" in OS.get_cmdline_args()) || OS.has_feature("dedicated_server"):
		NetworkManager.is_server = true
		get_tree().change_scene_to_file("res://DedicatedServer/ServerEntry.tscn")
	else:
		get_tree().change_scene_to_file("res://Client/Menu/ConnectMenu.tscn")
