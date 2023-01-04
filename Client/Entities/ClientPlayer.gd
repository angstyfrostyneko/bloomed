extends Player

onready var snapshot_container = SnapshotContainer.new()
onready var game_root: GameWorld = get_node('/root/GameRoot')

var current_snapshot: PlayerSnapshot = null
var target_snapshot: PlayerSnapshot = null

func _ready():
	if int(self.name) == get_tree().get_network_unique_id():
		self.set_main()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event):
	if not is_network_master():
		return
	if event is InputEventMouseMotion:
		_handle_camera_rotation(event)

func _handle_camera_rotation(event):
	rotate_y(deg2rad(-event.relative.x * camera_sensitivity))
	$Head.rotate_x(deg2rad(-event.relative.y * camera_sensitivity))
	$Head.rotation.x = clamp($Head.rotation.x, deg2rad(MIN_CAMERA_ANGLE), deg2rad(MAX_CAMERA_ANGLE))

func _physics_process(delta):
	if not is_network_master():
		puppet_generate_movement()
		return
	var movement = _get_movement_direction(delta)
	
	velocity.x = lerp(velocity.x,movement.x * speed,acceleration * delta)
	velocity.z = lerp(velocity.z,movement.z * speed,acceleration * delta)
	velocity.y += GRAVITY * delta
	velocity = move_and_slide(velocity)
	
	var snapshot = PlayerSnapshot.new()
	snapshot.tick = game_root.tick_clock
	snapshot.player_position = self.transform.origin
	snapshot.player_angle = self.rotation.y
	snapshot.head_angle = $Head.rotation.x
	rpc_id(NetworkManager.SERVER_ID, 'server_get_player_snapshot', snapshot.encode())



func _process(delta):
	if not is_network_master():
		puppet_move()

var last_puppet_move := 0.0

func puppet_move():
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
		self.transform.origin = current_snapshot.player_position.linear_interpolate(target_snapshot.player_position, progress)
		self.rotation.y = lerp_angle(current_snapshot.player_angle, target_snapshot.player_angle, progress)
		$Head.rotation.x = lerp_angle(current_snapshot.head_angle, target_snapshot.head_angle, progress)

func puppet_generate_movement():
	var new_snapshot: PlayerSnapshot = null
	while true:
		new_snapshot = snapshot_container.pull_snapshot()
		if new_snapshot == null:
			return
		if new_snapshot.tick < game_root.tick_clock - NetworkManager.INTERP_INTERVAL:
			continue
		break
	current_snapshot = target_snapshot
	target_snapshot = new_snapshot
	last_puppet_move = 0
	

func _get_movement_direction(delta):
	var direction = Vector3.DOWN
	
	if Input.is_action_pressed("forward"):
		direction -= transform.basis.z
	if Input.is_action_pressed("backward"):
		direction += transform.basis.z
	if Input.is_action_pressed("left"):
		direction -= transform.basis.x
	if Input.is_action_pressed("right"):
		direction += transform.basis.x
	if Input.is_action_just_pressed("jump") and $FloorCheck.is_colliding():
		velocity.y = jump_impulse
	if Input.is_action_just_pressed("crouch"):
		crouching = !crouching
		running = false
		#rpc("remote_crouch", crouching)
	if Input.is_action_just_pressed("run"):
		running = !running
		crouching = false
		#rpc("remote_run", running)
	if running:
		stamina -= delta
	if !running and stamina < MAX_STAMINA:
		stamina += delta
	elif stamina > MAX_STAMINA:
		stamina = MAX_STAMINA
	if stamina <= 0:
		running = false
		#rpc("remote_run", false)
	return direction

remote func client_get_player_snapshot(snapshot_data):
	if is_network_master():
		return
	var snapshot = PlayerSnapshot.new().decode(snapshot_data)
	self.snapshot_container.push_snapshot(snapshot)

func _on_health_changed(value):
	var healthUI = $HUD/Health
	if health > 50:
		healthUI.bbcode_text = "[color=#FFFFFF]%s[/color]" % str(health)
	else:
		healthUI.bbcode_text = "[color=#FF0000]%s[/color]" % str(health)

func set_main():
	$Head/Camera.make_current()
