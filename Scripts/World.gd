extends Spatial

onready var playerCharacterScene = preload('res://Assets/Prefabs/Player.tscn')

var main_player: int

# Called when the node enters the scene tree for the first time.
func _ready():
# warning-ignore:return_value_discarded
	NetworkManager.connect('server_closed', self, 'on_server_closed')
# warning-ignore:return_value_discarded
	NetworkManager.connect('player_connected', self, 'spawn_player')
# warning-ignore:return_value_discarded
	NetworkManager.connect('player_disconnected', self, 'on_player_disconnected')
	
	self.setup()
	
func setup():
	for pid in NetworkManager.players:
		self.spawn_player(NetworkManager.players[pid])

func spawn_player(playerData):
	var playerId = playerData[NetworkManager.PLAYER_ID_FIELD]
	for child in $Players.get_children(): # TODO: optimize this
		if child.get_name() == str(playerId):
			return
	
	print("Spawning playerId %d" % playerId)
	
	var newPlayer = self.playerCharacterScene.instance()
	newPlayer.set_network_master(playerId)
	newPlayer.set_name(str(playerId))
	
	if playerId == get_tree().get_network_unique_id():
		newPlayer.set_main()
		self.main_player = playerId
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	newPlayer.transform.origin = $SpawnPoint.translation
	$Players.add_child(newPlayer)

func on_player_disconnected(id):
	var player_node = $Players.get_node(str(id))
	player_node.queue_free()

func on_server_closed():
# warning-ignore:return_value_discarded
	get_tree().change_scene('res://Scenes/ConnectMenu.tscn')

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
