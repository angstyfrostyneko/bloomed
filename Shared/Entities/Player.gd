extends CharacterBody3D
class_name Player

const GRAVITY = -9.8

@export var speed: float = 1.5
@export var acceleration: float = 6.0
@export var jump_impulse: float = 4.0

@onready var game_root: GameWorld = get_node('/root/GameRoot')
@onready var world: Node3D = get_node("/root/GameRoot/World")
@onready var player_input: PlayerInput = $PlayerInput
@onready var aimcast: RayCast3D = $Head/Camera3D/AimCast

const EXTRAPOLATION_TIME := 6
var network_id := -1

var player_inputs: Array[PlayerInput.InputMessage] = []
var player_input_queue: Array[PlayerInput.InputMessage] = []
var last_player_input: PlayerInput.InputMessage = null
var extrapolation_length := 0


func _ready():
	pass

func set_network_id(id: int):
	self.set_name(str(id))
	self.network_id = id

func _process(delta):
	if not is_multiplayer_authority():
		return
	
func _physics_process(delta):
	if not NetworkManager.is_host() and not is_multiplayer_authority(): # and not is_multiplayer_authority():
		return
	
	var input_message := _get_network_player_input()
	
	self.rotate_y(input_message.camera_delta.x)
	$Head.rotate_x(input_message.camera_delta.y)
	$Head.rotation.x = clamp($Head.rotation.x, deg_to_rad(PlayerInput.MIN_CAMERA_ANGLE),
		deg_to_rad(PlayerInput.MAX_CAMERA_ANGLE))
	
	var direction := transform.basis * input_message.direction
	
	velocity.x = lerp(velocity.x, direction.x * speed, acceleration * delta)
	velocity.z = lerp(velocity.z, direction.z * speed, acceleration * delta)
	velocity.y += GRAVITY * delta
	if input_message.jumping and $FloorCheck.is_colliding():
		velocity.y = jump_impulse
	set_velocity(velocity)
	move_and_slide()
	
	if NetworkManager.is_host():
		var snapshot = PlayerSnapshot.new()
		snapshot.tick = game_root.tick_clock
		snapshot.player_position = self.transform.origin
		snapshot.player_angle = self.rotation.y
		snapshot.head_angle = $Head.rotation.x
		rpc('client_get_player_snapshot', snapshot.encode())

func _get_network_player_input() -> PlayerInput.InputMessage:
	var input_message: PlayerInput.InputMessage = last_player_input
	
	if player_input_queue.size() != 0:
		# TODO: This is exploitable, client can send a lot of inputs for one frame, be careful.
		input_message = player_input_queue.pop_front()
		extrapolation_length = 0
		last_player_input = input_message
		player_inputs.append(input_message)
	else:
		if extrapolation_length >= EXTRAPOLATION_TIME or input_message == null:
			input_message = PlayerInput.InputMessage.new()
		extrapolation_length += 1
	
	return input_message

@rpc("any_peer", "unreliable_ordered")
func client_get_player_snapshot(packed_snapshot: PackedByteArray):
	print('THIS SHOULD NOT BE EXECUTED !')

func set_display_name(name):
	$NameTag.text = name
