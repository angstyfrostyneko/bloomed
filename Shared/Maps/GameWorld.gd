extends Spatial
class_name GameWorld

var PLAYER_CHARACTER_SCENE: PackedScene

var tick_clock := 0

var player_container: Node

enum SYNC_STATUS {
	NONE,
	OK,
	PAST_DESYNC,
	FUTURE_DESYNC,
	DISCONNECTED
}

# Called when the node enters the scene tree for the first time.
func _ready():
	self.load_map()
	
	# warning-ignore:return_value_discarded
	NetworkManager.connect('player_connected', self, 'spawn_player')
	# warning-ignore:return_value_discarded
	NetworkManager.connect('player_disconnected', self, 'on_player_disconnected')
	
	self.setup()

func _physics_process(delta):
	self.tick_clock += 1

func load_map():
	var map = preload('res://Shared/Maps/FirstArea.tscn').instance()
	self.add_child(map)

func setup():
	player_container = Node.new()
	player_container.set_name('Players')
	self.add_child(player_container)
	
	for pid in NetworkManager.players:
		self.spawn_player(NetworkManager.players[pid])

func spawn_player(playerData):
	var playerId = playerData[NetworkManager.PLAYER_ID_FIELD]
	for child in player_container.get_children(): # TODO: optimize this
		if child.get_name() == str(playerId):
			return
	
	print("Spawning playerId %d" % playerId)
	
	var newPlayer = PLAYER_CHARACTER_SCENE.instance()
	newPlayer.set_network_master(playerId)
	newPlayer.set_name(str(playerId))
	newPlayer.set_display_name(playerData[NetworkManager.PLAYER_NAME_FIELD])
	newPlayer.transform.origin = $World/SpawnPoint.translation
	
	player_container.add_child(newPlayer)
	

func on_player_disconnected(id):
	var player_node = player_container.get_node(str(id))
	player_node.queue_free()
