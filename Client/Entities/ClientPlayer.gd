extends Player

@onready var snapshot_container = SnapshotContainer.new()

var current_snapshot: PlayerSnapshot = null
var target_snapshot: PlayerSnapshot = null

var prediction_records := {}


func _ready():
	if is_multiplayer_authority():
		self.set_main()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _process(delta):
	super(delta)
	if not is_multiplayer_authority():
		_puppet_move()
		return
	if reconciliation_interp:
		_interp_move()

func _physics_process(delta):
	if not is_multiplayer_authority():
		_puppet_generate_movement()
		return
	#else:
	#	_puppet_generate_movement()
	
	reconciliation_interp = false
	
	if reconciliation_target != null:
		_reconciliate(delta)
	
	var input_message = player_input.get_input_message()
	input_message.tick = game_root.tick_clock
	
	# client-side prediction
	player_input_queue.append(input_message)
	
	rpc_id(NetworkManager.SERVER_ID, 'server_gather_player_input', input_message.encode())
	
	super(delta)
	
	prediction_records[game_root.tick_clock] = _generate_prediction_record()

func _generate_prediction_record():
	var result = PredictionRecord.new()
	result.position = self.transform.origin
	result.camera.y = self.rotation.y
	result.camera.x = $Head.rotation.x
	result.velocity = self.velocity
	return result

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

func _interp_move():
	var count_time = NetworkManager.TICK_DELTA
	if last_puppet_move >= count_time:
		return
	var step = min(get_physics_process_delta_time(), NetworkManager.TICK_DELTA)
	last_puppet_move = step
	var progress = step / count_time
	self.transform.origin = pre_reconciliation_pos.lerp(reconciliation_pos, progress)

@rpc("any_peer", "reliable")
func server_gather_player_input(packed_input_message: PackedByteArray):
	print('THIS SHOULD NOT BE EXECUTED !')


var reconciliation_target : PlayerSnapshot = null
var rewind_amount : int = 0

var reconciliation_interp := false
var reconciliation_pos : Vector3
var pre_reconciliation_pos : Vector3

class PredictionRecord:
	var position: Vector3
	var camera: Vector2
	var velocity: Vector3

func _reconciliate(delta):
	print('Reconciliation to ', reconciliation_target.player_position, ' against ', self.prediction_records[reconciliation_target.tick].position)
	self.pre_reconciliation_pos = self.transform.origin
	self.transform.origin = reconciliation_target.player_position
	self.rotation.y = reconciliation_target.player_angle
	$Head.rotation.x = reconciliation_target.head_angle
	rewind_amount = min(rewind_amount, self.player_inputs.size())
	if rewind_amount != 0:
		self.velocity = self.prediction_records[game_root.tick_clock - rewind_amount].velocity
	while rewind_amount > 0:
		prediction_records[game_root.tick_clock - rewind_amount] = _generate_prediction_record()
		var input = self.player_inputs[-rewind_amount].copy()
		_apply_player_input(NetworkManager.TICK_DELTA, input)
		rewind_amount -= 1
	self.reconciliation_pos = self.transform.origin
	self.transform.origin = pre_reconciliation_pos
	reconciliation_target = null
	reconciliation_interp = true
	last_puppet_move = 0.0
	

@rpc("any_peer", "unreliable_ordered")
func client_get_player_snapshot(packed_snapshot: PackedByteArray):
	var snapshot := PlayerSnapshot.decode(packed_snapshot)
	if is_multiplayer_authority():
		if self.prediction_records.has(snapshot.tick):
			var delta_vec : Vector3 = self.prediction_records[snapshot.tick].position - snapshot.player_position
			var delta = delta_vec.length_squared()
			print(delta_vec)
			if delta > 0.01:
				print('Prediction error on tick ', game_root.tick_clock, ': ', delta_vec)
				reconciliation_target = snapshot
				rewind_amount = max(game_root.tick_clock - (snapshot.tick), 0) + 1
				print('REWINDING BY ', rewind_amount)
		return
	snapshot_container.push_snapshot(snapshot)
	

func set_main():
	$Head/Camera3D.make_current()
