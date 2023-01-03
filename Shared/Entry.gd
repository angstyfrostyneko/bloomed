extends Node


func _ready():
	if ("--server" in OS.get_cmdline_args()) || OS.has_feature("dedicated_server"):
		NetworkManager.is_server = true
		get_tree().change_scene("res://DedicatedServer/ServerEntry.tscn")
	else:
		get_tree().change_scene("res://Client/Menu/ConnectMenu.tscn")
