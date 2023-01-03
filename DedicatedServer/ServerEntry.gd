extends Node


func _ready():
	NetworkManager.start_hosting(42424)
