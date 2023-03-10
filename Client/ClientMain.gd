extends GameWorld

const CLIENT_PLAYER_SCENE = preload('res://Client/Entities/ClientPlayer.tscn')

var sync_status = SYNC_STATUS.NONE

var latency : int = 0
var tick_delay : int = 0

func _init():
	self.PLAYER_CHARACTER_SCENE = CLIENT_PLAYER_SCENE
	super()

func _ready():
	super()
	# warning-ignore:return_value_discarded
	NetworkManager.connect('server_closed',Callable(self,'on_server_closed'))
	
	self.first_sync()

func _physics_process(delta):
	super(delta)
	print('Latency: ', latency)

func first_sync():
	rpc_id(NetworkManager.SERVER_ID, 'request_clock_sync')
	sync_status = SYNC_STATUS.OK

@rpc("reliable", "any_peer")
func request_clock_sync():
	print('THIS SHOULD NOT BE EXECUTED!!')

@rpc("reliable", "any_peer")
func client_sync_clock(server_tick: int):
	self.tick_clock = server_tick

signal PangReceived(server_tick)

@rpc("any_peer", "reliable")
func pong():
	var t0 = Time.get_ticks_msec()
	
	rpc_id(NetworkManager.SERVER_ID, 'server_receive_pong')
	
	var server_tick = await PangReceived
	
	latency = Time.get_ticks_msec() - t0
	
	tick_delay = int(ceil(latency / (2.0 * NetworkManager.TICK_DELTA_MS)))
	tick_clock = int(server_tick + latency / (2.0 * NetworkManager.TICK_DELTA_MS))

@rpc("any_peer", "reliable")
func pang(server_tick: int):
	emit_signal('PangReceived', server_tick)

@rpc("any_peer", "reliable")
func server_receive_pong():
	print('THIS SHOULD NOT BE EXECUTED!!')


func on_server_closed():
	# warning-ignore:return_value_discarded
	get_tree().change_scene_to_file('res://Client/Menu/ConnectMenu.tscn')



	
