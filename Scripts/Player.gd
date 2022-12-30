extends KinematicBody
class_name Player

const CROUCHING_SPEED := 1
const WALKING_SPEED := 2.5
const RUNNING_SPEED := 4.75
const MAX_STAMINA := 7.5
# model and hitbox respectively
const STANDING_HEIGHT = [1.25, 2.25]
const CROUCHING_HEIGHT = [0.75, 1.75]

const MIN_CAMERA_ANGLE = -90
const MAX_CAMERA_ANGLE = 90
const GRAVITY = -9.8
const THROW_STRENGTH := 35
const MAX_THROW_CHARGE := 1.0
const HAND = 0

export var camera_sensitivity: float = 0.05
export var speed: float = WALKING_SPEED
export var acceleration: float = 6.0
export var jump_impulse: float = 4.0
var velocity: Vector3 = Vector3.ZERO

onready var world: Spatial = get_node("/root/World")
onready var aimcast: RayCast = $Head/Camera/AimCast

var health = 100
var money = 250

# 5 slots, 0 is hand, 1-3 universal and 4 big items
# ammo is magazines you hold in a slot
var inventory = [null, null, null, null, null]
var reloading = false
var crouching = false
var running = false

var throw_charging := false
var throw_charge_length := 0.0
var stamina = MAX_STAMINA

func _ready():
	rset_config('transform', 1)
	modify_money(0)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _process(delta):
	if not is_network_master():
		return
		
	if Input.is_action_pressed("shoot"):
		if inventory[HAND] == null:
			return
		if inventory[HAND].type != Item.Type.GUN:
			return
		if not inventory[HAND].cooldown.is_stopped() or reloading:
			return
		if inventory[HAND].magazine == 0:
			reload()
			return
		
		inventory[HAND].magazine -= 1
		inventory[HAND].cooldown.start()
		inventory[HAND].bullet_particles.emitting = true;
		update_ammo_counter(inventory[HAND].magazine)
		
		var collider = aimcast.get_collider()
		if collider == null:
			return
		if collider.is_in_group("Player"):
			rpc_id(int(collider.name), "damage", inventory[HAND].damage)

	if Input.is_action_just_pressed("pickup"):
		if inventory[HAND] != null:
			return
		var collider = aimcast.get_collider()
		if collider != null and collider.get_parent() is Item:
			pickup(collider.get_parent())

	if Input.is_action_just_pressed("reload"):
		if inventory[HAND] == null:
			return
		if inventory[HAND].type == Item.Type.GUN:
			reload()

	if Input.is_action_just_pressed("drop"):
		throw_charging = true
	elif throw_charging:
		throw_charge_length = min(MAX_THROW_CHARGE, throw_charge_length + delta)
	
	if Input.is_action_just_released("drop"):
		throw_charging = false
		if inventory[HAND] != null and inventory[HAND].has_method("on_drop"):
			drop(inventory[HAND])
		throw_charge_length = 0
	
	if Input.is_action_just_pressed("inventory_first"):
		swap_item(1)
	if Input.is_action_just_pressed("inventory_second"):
		swap_item(2)
	if Input.is_action_just_pressed("inventory_third"):
		swap_item(3)
	if Input.is_action_just_pressed("inventory_big"):
		swap_item(4)

func _physics_process(delta):
	if not is_network_master():
		return
	var movement = _get_movement_direction(delta)
	
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
	$Head.rotate_x(deg2rad(-event.relative.y * camera_sensitivity))
	$Head.rotation.x = clamp($Head.rotation.x, deg2rad(MIN_CAMERA_ANGLE), deg2rad(MAX_CAMERA_ANGLE))

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
		# modify model and hitbox size
		if crouching:
			$Body.mesh.set("mid_height", STANDING_HEIGHT[0])
			$Collider.shape.set("height", STANDING_HEIGHT[1])
			speed = WALKING_SPEED
			crouching = false
		else:
			$Body.mesh.set("mid_height", CROUCHING_HEIGHT[0])
			$Collider.shape.set("height", CROUCHING_HEIGHT[1])
			speed = CROUCHING_SPEED
			crouching = true
			running = false
	if Input.is_action_just_pressed("run"):
		if running:
			speed = WALKING_SPEED
			running = false
		else:
			speed = RUNNING_SPEED
			running = true
			crouching = false
	if running:
		stamina -= delta
	if !running and stamina < MAX_STAMINA:
		stamina += delta
	elif stamina > MAX_STAMINA:
		stamina = MAX_STAMINA
	if stamina <= 0:
		speed = WALKING_SPEED
		running = false
	return direction

func modify_money(amount):
	money += amount
	$HUD/Money.bbcode_text = "[color=#00FF00]$[/color]%s" % str(money)

func update_ammo_counter(magazine):
	var reserve = 0
	for i in range(5):
		if inventory[i] == null:
			continue
		if inventory[HAND] == null:
			continue
		if inventory[i].type != Item.Type.MAG:
			continue
		if inventory[i].weapon_class == inventory[HAND].weapon_class:
			reserve += inventory[i].size
	var magazine_color = "#FFFFFF"
	var reserve_color = "#FFFFFF"
	if magazine < 10:
		magazine_color = "#FF0000"
	if reserve < 30:
		reserve_color = "#FF0000"

	$HUD/Ammo.bbcode_text = "[color=%s]%s[/color]/[color=%s]%s" % [magazine_color, magazine, reserve_color, reserve]

func swap_item(slot):
	if inventory[slot] == null and inventory[HAND] == null:
		return
	if inventory[HAND] == null:
		inventory[HAND] = inventory[slot]
		inventory[HAND].visible = true
		if inventory[HAND].type == Item.Type.GUN:
			$HUD/Ammo.visible = true
			update_ammo_counter(inventory[HAND].magazine)
		inventory[slot] = null
		return
	if inventory[slot] == null:
		if inventory[HAND].is_big and slot != 4:
			return # TODO: alert player about this
		inventory[slot] = inventory[HAND]
		inventory[HAND].visible = false
		$HUD/Ammo.visible = false
		inventory[HAND] = null
		return
	var temp = inventory[HAND]
	inventory[HAND].visible = false
	inventory[HAND] = inventory[slot]
	inventory[HAND].visible = true
	if inventory[HAND].type == Item.Type.GUN:
		$HUD/Ammo.visible = true
		update_ammo_counter(inventory[HAND].magazine)
	inventory[slot] = temp

func reload():
	if reloading:
		return
	if inventory[HAND].type != Item.Type.GUN:
		return
	for i in range(5):
		if inventory[i] == null:
			continue
		if inventory[i].type != Item.Type.MAG:
			continue
		if inventory[i].weapon_class != inventory[HAND].weapon_class:
			continue
		if inventory[i].size == 0:
			continue
		
		reloading = true
		inventory[HAND].reload_timer.start()
		yield(inventory[HAND].reload_timer, "timeout")
		if reloading == false:
			return
		inventory[HAND].magazine = inventory[i].size
		inventory[i].size = 0
		reloading = false
		update_ammo_counter(inventory[HAND].magazine)
		return

remotesync func damage(amount):
	var healthUI = $HUD/Health
	health -= amount
	if health > 50:
		healthUI.bbcode_text = "[color=#FFFFFF]%s[/color]" % str(health)
	else:
		healthUI.bbcode_text = "[color=#FF0000]%s[/color]" % str(health)
	if health <= 0:
		# TODO: implement death
		print("i am ded")

func pickup(item: Item):
	if !item.has_method("on_pickup"):
		return
	if inventory[HAND] != null:
		return

	var target = get_node("Head/Camera/GunPosition")
	rpc("remote_pickup", target.get_path(), item.get_path())
	inventory[HAND] = item
	if item.type == Item.Type.GUN:
		$HUD/Ammo.visible = true
		update_ammo_counter(item.magazine)
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
	item.on_drop()
	rpc("remote_drop", item.get_path(), throw_charge_length)
	inventory[HAND] = null
	$HUD/Ammo.visible = false

remotesync func remote_drop(item_path, strength: float):
	var item = get_node(item_path) as Item
	item.on_drop()
	item.get_parent().remove_child(item)
	world.add_child(item)
	item.set_owner(world)
	
	item.translation = $Head.global_translation + Vector3(0,-0.125,0)
	
	item.on_drop()
	print(strength)
	item.apply_central_impulse(-(5 + THROW_STRENGTH * strength) * $Head.global_transform.basis.z)

func set_display_name(name):
	$NameTag.text = name

func set_main():
	$Head/Camera.make_current()
