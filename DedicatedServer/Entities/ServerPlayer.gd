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

@rpc("any_peer", "reliable")
func server_gather_player_input(packed_input_message: PackedByteArray):
	print('input from: ', multiplayer.get_remote_sender_id(), ' on ', self.name)
	var input_message = PlayerInput.InputMessage.decode(packed_input_message)
	if player_inputs.size() > 0:
		if player_inputs[-1].tick == game_root.tick_clock:
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

