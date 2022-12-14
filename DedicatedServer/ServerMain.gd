extends GameWorld

const SERVER_PLAYER_SCENE = preload('res://DedicatedServer/Entities/ServerPlayer.tscn')

func _init():
	self.PLAYER_CHARACTER_SCENE = SERVER_PLAYER_SCENE

func _ready():
	pass
	
remote func request_first_sync():
	var sender := get_tree().get_rpc_sender_id()
	rpc_id(sender, 'sync_clock', self.tick_clock)
