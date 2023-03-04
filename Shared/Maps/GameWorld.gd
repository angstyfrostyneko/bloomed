extends Node3D
class_name GameWorld

var PLAYER_CHARACTER_SCENE: PackedScene

var tick_clock := 0

var player_container: Node
var item_container: Node

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
	NetworkManager.connect('player_connected', func(data) : self.spawn_player(data))
	# warning-ignore:return_value_discarded
	NetworkManager.connect('player_disconnected', func(id) : self.on_player_disconnected(id))
	
	self.setup()

func _physics_process(delta):
	self.tick_clock += 1

func load_map():
	"""
	Spawn items, load colliders, etc
	"""
	item_container = Node.new()
	item_container.set_name('Items')
	self.add_child(item_container)
	
	var map = preload('res://Shared/Maps/FirstArea.tscn').instantiate()
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
	
	var newPlayer = PLAYER_CHARACTER_SCENE.instantiate()
	newPlayer.set_multiplayer_authority(playerId)
	newPlayer.set_name(str(playerId))
	newPlayer.set_display_name(playerData[NetworkManager.PLAYER_NAME_FIELD])
	newPlayer.transform.origin = $World/SpawnPoint.position
	
	player_container.add_child(newPlayer)
	
func spawn_item(item: Item):
	if item.get_parent() != null:
		item.get_parent().remove_child(item)
	item_container.add_child(item)
	

func on_player_disconnected(id):
	var player_node = player_container.get_node(str(id))
	player_node.queue_free()
