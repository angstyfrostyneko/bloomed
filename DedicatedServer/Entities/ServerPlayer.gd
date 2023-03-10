extends Player
class_name ServerPlayer

var latency : int = 0
var is_pinging := false

func _ready():
	pass

func _process(delta):
	super(delta)

func _physics_process(delta):
	super(delta)
	var snapshot = PlayerSnapshot.new()
	snapshot.tick = game_root.tick_clock
	snapshot.player_position = self.transform.origin
	snapshot.player_angle = self.rotation.y
	snapshot.head_angle = $Head.rotation.x
	rpc('client_get_player_snapshot', snapshot.encode())

@rpc("any_peer", "reliable")
func server_gather_player_input(packed_input_message: PackedByteArray):
	var input_message = PlayerInput.InputMessage.decode(packed_input_message)
	print('input from: ', multiplayer.get_remote_sender_id(), ' on tick ', input_message.tick, '/', game_root.tick_clock, ' [', player_input_queue.size(), ']')
	input_message.tick = game_root.tick_clock
	if player_input_queue.size() > 0:
		if player_input_queue[-1].tick == game_root.tick_clock:
			player_input_queue[-1] = input_message
			return
	player_input_queue.append(input_message)

signal PongReceived

func ping():
	is_pinging = true
	
	var t0 = Time.get_ticks_msec()
	
	game_root.rpc_id(self.network_id, 'pong')
	
	await PongReceived
	
	latency = Time.get_ticks_msec() - t0
	
	game_root.rpc_id(self.network_id, 'pang', game_root.tick_clock)

@rpc("any_peer", "unreliable_ordered")
func client_get_player_snapshot(packed_snapshot: PackedByteArray):
	print('THIS SHOULD NOT BE EXECUTED !')
