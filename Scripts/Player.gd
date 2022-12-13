extends KinematicBody
class_name Player


const MIN_CAMERA_ANGLE = -90
const MAX_CAMERA_ANGLE = 90
const GRAVITY = -9.8
const THROW_STRENGTH := 35
const MAX_THROW_CHARGE := 1.0

export var camera_sensitivity: float = 0.05
export var speed: float = 2.5
export var acceleration: float = 6.0
export var jump_impulse: float = 12.0
var velocity: Vector3 = Vector3.ZERO

onready var HUD = $HUD
onready var head: Spatial = $Head
onready var floorcheck = $FloorCheck
onready var world := get_node("/root/World") as Spatial
onready var player := get_node(".") as Player
onready var aimcast := $Head/Camera/AimCast as RayCast

var health = 100
var money = 250

# 2 weapon slots
# 2 hand & briefcase
#     if briefcase only one handed items
# 3 auxilary slot for misc items (bandages)
# 4 ammo slots for the classes (sniper, pistol, shotgun, rifle)

# ^^ NEEDS HEAVY RETHINKING, IGNORE FOR NOW ^^
# 4 slots, any of them could hold anything
var inventory = [null, null, null, null]
var current_slot = 0
var ammunition = [10, 150, 15, 100]

var throw_charging := false
var throw_charge_length := 0.0

func _ready():
	rset_config('transform', 1)
	modify_money(0)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _process(delta):
	if not is_network_master():
		return
		
	var held_item = inventory[current_slot]
	if Input.is_action_pressed("shoot"):
		if held_item == null:
			return
		if held_item.type == "gun":
			held_item.shoot()

	if Input.is_action_just_pressed("pickup"):
		if held_item != null:
			return
		var collider = aimcast.get_collider()
		if collider != null and collider.get_parent() is Item:
			pickup(collider.get_parent())

	if Input.is_action_just_pressed("reload"):
		if held_item == null:
			return
		if held_item.type == "gun":
			held_item.reload()

	if Input.is_action_just_pressed("drop"):
		throw_charging = true
	elif throw_charging:
		throw_charge_length = min(MAX_THROW_CHARGE, throw_charge_length + delta)

	if Input.is_action_just_released("drop"):
		throw_charging = false
		if held_item != null and held_item.has_method("dropped"):
			drop(held_item)
		throw_charge_length = 0

func _physics_process(delta):
	if not is_network_master():
		return
	var movement = _get_movement_direction()
	
	velocity.x = lerp(velocity.x,movement.x * speed,acceleration * delta)
	velocity.z = lerp(velocity.z,movement.z * speed,acceleration * delta)
	velocity.y += GRAVITY * delta
	velocity = move_and_slide(velocity)
	
	rset_unreliable('transform', self.transform)

func _unhandled_input(event):
	if not is_network_master():
		return
	if event is InputEventMouseMotion:
		_handle_camera_rotation(event)

func _handle_camera_rotation(event):
	rotate_y(deg2rad(-event.relative.x * camera_sensitivity))
	head.rotate_x(deg2rad(-event.relative.y * camera_sensitivity))
	head.rotation.x = clamp(head.rotation.x, deg2rad(MIN_CAMERA_ANGLE), deg2rad(MAX_CAMERA_ANGLE))

func _get_movement_direction():
	var direction = Vector3.DOWN
	
	if Input.is_action_pressed("forward"):
		direction -= transform.basis.z
	if Input.is_action_pressed("backward"):
		direction += transform.basis.z
	if Input.is_action_pressed("left"):
		direction -= transform.basis.x
	if Input.is_action_pressed("right"):
		direction += transform.basis.x
	if Input.is_action_just_pressed("jump") and floorcheck.is_colliding():
		velocity.y = jump_impulse
	
	return direction

func modify_money(amount):
	money += amount
	HUD.get_node("Money").bbcode_text = "[color=#00FF00]$[/color]" + str(money)

func damage(amount):
	var healthUI = HUD.get_node("Health")
	health -= amount
	if health > 50:
		healthUI.bbcode_text = "[color=#FFFFFF]%s[/color]" % str(health)
	else:
		healthUI.bbcode_text = "[color=#FF0000]%s[/color]" % str(health)
	if health <= 0:
		# TODO: don't actually kill, fake it
		queue_free()

func pickup(item: Item):
	if item.has_method("picked_up"):
		var target := get_node("Head/Camera/GunPosition") as Spatial
		rpc("remote_pickup", target.get_path(), item.get_path())
		inventory[current_slot] = item
		match item.get("type"):
			"gun":
				get_node("HUD/Ammo").visible = true
				var reserve_ammo
				match item.get("weapon_class"):
					"sniper":
						reserve_ammo = ammunition[0]
					"pistol":
						reserve_ammo = ammunition[1]
					"shotgun":
						reserve_ammo = ammunition[2]
					"rifle":
						reserve_ammo = ammunition[3]
				item.picked_up(reserve_ammo)
			"bandage":
				pass
		item.is_held = true

remotesync func remote_pickup(target_path, item_path):
	var target = get_node(target_path)
	var item = get_node(item_path)
	item.get_parent().remove_child(item)
	target.add_child(item)
	item.set_owner(target)
	item.translation = Vector3(0, 0, 0)
	item.rotation = Vector3(0, 0, 0)
	
	item.on_pickup()

func drop(item: Item):
	var response = item.dropped()
	rpc("remote_drop", item.get_path(), throw_charge_length)
	inventory[current_slot] = null
	get_node("HUD/Ammo").visible = false
	
	if item.get("type") == "gun":
		ammunition[response[0]] = response[1]

remotesync func remote_drop(item_path, strength: float):
	var item = get_node(item_path) as Item
	item.dropped()
	item.get_parent().remove_child(item)
	world.add_child(item)
	item.set_owner(world)
	
	item.translation = self.head.global_translation + Vector3(0,-0.125,0)
	
	item.on_drop()
	print(strength)
	item.apply_central_impulse(-(5 + THROW_STRENGTH * strength) * head.global_transform.basis.z)

func set_main():
	$Head/Camera.make_current()
