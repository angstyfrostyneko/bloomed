extends Player

@onready var snapshot_container = SnapshotContainer.new()

var current_snapshot: PlayerSnapshot = null
var target_snapshot: PlayerSnapshot = null

func _ready():
	if is_multiplayer_authority():
		self.set_main()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _process(delta):
	super(delta)
	if not is_multiplayer_authority():
		_puppet_move()
	else:
		_puppet_move()

func _physics_process(delta):
	super(delta)
	if not is_multiplayer_authority():
		_puppet_generate_movement()
		return
	else:
		_puppet_generate_movement()
	
	var input_message = player_input.get_input_message()
	input_message.tick = game_root.tick_clock
	rpc_id(NetworkManager.SERVER_ID, 'server_gather_player_input', input_message.encode())

var last_puppet_move := 0.0

func _puppet_generate_movement():
	var new_snapshot: PlayerSnapshot = null
	while true:
		new_snapshot = snapshot_container.pull_snapshot()
		if new_snapshot == null:
			return
		if new_snapshot.tick >= game_root.tick_clock - NetworkManager.INTERP_DEAD_ZONE:
			if snapshot_container.snapshots.size() > 0:
				print(snapshot_container.snapshots[0].tick, ' ', snapshot_container.snapshots.size(), ' ', new_snapshot.tick, ' ', game_root.tick_clock - NetworkManager.INTERP_DEAD_ZONE)
			snapshot_container.push_snapshot(new_snapshot)
			return
		if new_snapshot.tick < game_root.tick_clock - NetworkManager.INTERP_INTERVAL:
			continue
		break
	if new_snapshot != null:
		print(new_snapshot.player_position, ' ', new_snapshot.tick, ' ', game_root.tick_clock, ' ', game_root.tick_clock - new_snapshot.tick)
	current_snapshot = target_snapshot
	target_snapshot = new_snapshot
	last_puppet_move = 0

func _puppet_move():
	if target_snapshot == null:
		return
	var count_time = NetworkManager.TICK_DELTA
	if last_puppet_move >= count_time:
		return
	var step = min(get_physics_process_delta_time(), NetworkManager.TICK_DELTA)
	last_puppet_move = step
	
	if current_snapshot == null:
		self.transform.origin = target_snapshot.player_position
		self.rotation.y = target_snapshot.player_angle
		$Head.rotation.x = target_snapshot.head_angle
	else:
		var progress = step / count_time
		self.transform.origin = current_snapshot.player_position.lerp(target_snapshot.player_position, progress)
		self.rotation.y = lerp_angle(current_snapshot.player_angle, target_snapshot.player_angle, progress)
		$Head.rotation.x = lerp_angle(current_snapshot.head_angle, target_snapshot.head_angle, progress)

@rpc("any_peer", "reliable")
func server_gather_player_input(packed_input_message: PackedByteArray):
	print('THIS SHOULD NOT BE EXECUTED !')

@rpc("any_peer", "unreliable_ordered")
func client_get_player_snapshot(packed_snapshot: PackedByteArray):
	#if is_multiplayer_authority():
	#	return
	var snapshot := PlayerSnapshot.decode(packed_snapshot)
	snapshot_container.push_snapshot(snapshot)
	

func set_main():
	$Head/Camera3D.make_current()
