extends GameWorld

const SERVER_PLAYER_SCENE = preload('res://DedicatedServer/Entities/ServerPlayer.tscn')

func _init():
	self.PLAYER_CHARACTER_SCENE = SERVER_PLAYER_SCENE
	super()

func _ready():
	super()


@rpc("reliable", "any_peer")
func request_clock_sync():
	var sender := multiplayer.get_remote_sender_id()
	rpc_id(sender, 'client_sync_clock', self.tick_clock)

@rpc("reliable", "any_peer")
func client_sync_clock(server_tick: int):
	print('THIS SHOULD NOT BE EXECUTED!!')

func _on_ping_request_timer_timeout():
	for player_node in player_container.get_children():
		var player = player_node as ServerPlayer
		player.ping()

@rpc("any_peer", "reliable")
func server_receive_pong():
	var id = multiplayer.get_remote_sender_id()
	var player = player_container.get_node(str(id)) as ServerPlayer
	player.emit_signal('PongReceived')
	
@rpc("any_peer", "reliable")
func pong():
	print('THIS SHOULD NOT BE EXECUTED HERE!!')

@rpc("any_peer", "reliable")
func pang():
	print('THIS SHOULD NOT BE EXECUTED HERE!!')
