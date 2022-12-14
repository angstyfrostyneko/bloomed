extends GameWorld

const CLIENT_PLAYER_SCENE = preload('res://Client/Entities/ClientPlayer.tscn')

var sync_status = SYNC_STATUS.NONE

func _init():
	self.PLAYER_CHARACTER_SCENE = CLIENT_PLAYER_SCENE

func _ready():
	# warning-ignore:return_value_discarded
	NetworkManager.connect('server_closed', self, 'on_server_closed')
	
	self.first_sync()

func _physics_process(delta):
	pass

func first_sync():
	rpc_id(NetworkManager.SERVER_ID, 'request_first_sync')


func on_server_closed():
	# warning-ignore:return_value_discarded
	get_tree().change_scene('res://Client/Menu/ConnectMenu.tscn')
