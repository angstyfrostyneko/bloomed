extends Node
class_name PlayerInput

@export var camera_sensitivity: float = 0.05

const MIN_CAMERA_ANGLE = -90
const MAX_CAMERA_ANGLE = 90

func _ready():
	pass
	
func _process(delta):
	pass

func _input(event):
	if not is_multiplayer_authority():
		return
	if event is InputEventMouseMotion:
		_handle_camera_rotation(event)

func get_input_message():
	var result = InputMessage.new()
	result.direction = get_movement_direction()
	result.camera_delta = get_camera_rotation()
	result.jumping = is_jumping()
	return result

var camera_yaw_delta := 0.0
var camera_pitch_delta := 0.0

func get_camera_rotation():
	var yaw_delta = self.camera_yaw_delta
	var pitch_delta = self.camera_pitch_delta
	
	self.camera_yaw_delta = 0
	self.camera_pitch_delta = 0
	
	return Vector2(yaw_delta, pitch_delta)

func get_movement_direction():
	var direction = Vector3.ZERO
	
	if Input.is_action_pressed("forward"):
		direction += Vector3.FORWARD
	if Input.is_action_pressed("backward"):
		direction += Vector3.BACK
	if Input.is_action_pressed("left"):
		direction += Vector3.LEFT
	if Input.is_action_pressed("right"):
		direction += Vector3.RIGHT
	
	direction = direction.normalized()
		
	return direction

func is_jumping():
	return Input.is_action_just_pressed("jump")

func _handle_camera_rotation(event):
	self.camera_yaw_delta += deg_to_rad(-event.relative.x * camera_sensitivity)
	self.camera_pitch_delta += deg_to_rad(-event.relative.y * camera_sensitivity)

class InputMessage extends TimestampedData:
	var direction : Vector3
	var camera_delta : Vector2
	var jumping : bool
	
	func encode():
		var result = PackedByteArray()
		result.resize(25)
		result.encode_u32(0, tick)
		result.encode_float(4, direction.x)
		result.encode_float(8, direction.y)
		result.encode_float(12, direction.z)
		result.encode_float(16, camera_delta.x)
		result.encode_float(20, camera_delta.y)
		result.encode_u8(24, jumping)
		return result
	
	static func decode(data: PackedByteArray):
		var result = InputMessage.new()
		result.tick = data.decode_u32(0)
		result.direction.x = data.decode_float(4)
		result.direction.y = data.decode_float(8)
		result.direction.z = data.decode_float(12)
		result.camera_delta.x = data.decode_float(16)
		result.camera_delta.y = data.decode_float(20)
		result.jumping = data.decode_u8(24) as bool
		return result


	"""if Input.is_action_just_pressed("jump") and $FloorCheck.is_colliding():
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
		#rpc("remote_run", false)"""

