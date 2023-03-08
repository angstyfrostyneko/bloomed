extends CharacterBody3D
class_name Player

const GRAVITY = -9.8

@export var speed: float = 1.25
@export var acceleration: float = 6.0
@export var jump_impulse: float = 4.0

@onready var game_root: GameWorld = get_node('/root/GameRoot')
@onready var world: Node3D = get_node("/root/GameRoot/World")
@onready var player_input: PlayerInput = $PlayerInput
@onready var aimcast: RayCast3D = $Head/Camera3D/AimCast

var network_id := -1

var player_inputs: Array[PlayerInput.InputMessage] = []
var player_input_queue: Array[PlayerInput.InputMessage] = []

func _ready():
	pass

func set_network_id(id: int):
	self.set_name(str(id))
	self.network_id = id

func _process(delta):
	if not is_multiplayer_authority():
		return

func _physics_process(delta):
	if not NetworkManager.is_host(): # and not is_multiplayer_authority():
		return
	
	var input_message: PlayerInput.InputMessage = PlayerInput.InputMessage.new()
	
	if player_input_queue.size() != 0:
		# TODO: This is exploitable, client can send a lot of inputs for one frame, be careful.
		input_message = player_input_queue.pop_front()
		player_inputs.append(input_message)
	
	self.rotate_y(input_message.camera_delta.x)
	$Head.rotate_x(input_message.camera_delta.y)
	$Head.rotation.x = clamp($Head.rotation.x, deg_to_rad(PlayerInput.MIN_CAMERA_ANGLE),
		deg_to_rad(PlayerInput.MAX_CAMERA_ANGLE))
	
	var direction := transform.basis * input_message.direction
	
	velocity.x = lerp(velocity.x, direction.x * speed, acceleration * delta)
	velocity.z = lerp(velocity.z, direction.z * speed, acceleration * delta)
	velocity.y += GRAVITY * delta
	if input_message.jumping:
		velocity.y = jump_impulse
	set_velocity(velocity)
	move_and_slide()
	
	var snapshot = PlayerSnapshot.new()
	snapshot.tick = game_root.tick_clock
	snapshot.player_position = self.transform.origin
	snapshot.player_angle = self.rotation.y
	snapshot.head_angle = $Head.rotation.x
	rpc('client_get_player_snapshot', snapshot.encode())

@rpc("any_peer", "unreliable_ordered")
func client_get_player_snapshot(packed_snapshot: PackedByteArray):
	print('THIS SHOULD NOT BE EXECUTED !')

func set_display_name(name):
	$NameTag.text = name
