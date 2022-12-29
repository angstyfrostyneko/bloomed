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
export var jump_impulse: float = 4.0
var velocity: Vector3 = Vector3.ZERO

onready var world: Spatial = get_node("/root/World")
onready var aimcast: RayCast = $Head/Camera/AimCast

var health = 100
var money = 250

# 4 slots, 3 universal and last for big items
# ammo is magazines you hold in a slot
var inventory = [null, null, null, null]
var current_slot = 0
var reloading = false

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
		if held_item.type != Item.Type.GUN:
			return
		if not held_item.cooldown.is_stopped() or reloading:
			return
		if held_item.magazine == 0:
			reload()
			return
		
		held_item.magazine -= 1
		held_item.cooldown.start()
		held_item.bullet_particles.emitting = true;
		update_ammo_counter(held_item.magazine)
		
		var collider = aimcast.get_collider()
		if collider == null:
			return
		if collider.is_in_group("Player"):
			rpc_id(int(collider.name), "damage", held_item.damage)

	if Input.is_action_just_released("shoot"):
		if held_item != null and held_item.type == Item.Type.GUN:
			pass

	if Input.is_action_just_pressed("pickup"):
		if held_item != null:
			return
		var collider = aimcast.get_collider()
		if collider != null and collider.get_parent() is Item:
			pickup(collider.get_parent())

	if Input.is_action_just_pressed("reload"):
		if held_item == null:
			return
		if held_item.type == Item.Type.GUN:
			reload()

	if Input.is_action_just_pressed("drop"):
		throw_charging = true
	elif throw_charging:
		throw_charge_length = min(MAX_THROW_CHARGE, throw_charge_length + delta)
	
	if Input.is_action_just_released("drop"):
		throw_charging = false
		if held_item != null and held_item.has_method("on_drop"):
			drop(held_item)
		throw_charge_length = 0
	
	if Input.is_action_just_pressed("inventory_first"):
		switch_item(0)
	if Input.is_action_just_pressed("inventory_second"):
		switch_item(1)
	if Input.is_action_just_pressed("inventory_third"):
		switch_item(2)
	if Input.is_action_just_pressed("inventory_big"):
		switch_item(3)

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
	$Head.rotate_x(deg2rad(-event.relative.y * camera_sensitivity))
	$Head.rotation.x = clamp($Head.rotation.x, deg2rad(MIN_CAMERA_ANGLE), deg2rad(MAX_CAMERA_ANGLE))

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
	if Input.is_action_just_pressed("jump") and $FloorCheck.is_colliding():
		velocity.y = jump_impulse
	
	return direction

func modify_money(amount):
	money += amount
	$HUD/Money.bbcode_text = "[color=#00FF00]$[/color]" + str(money)

func update_ammo_counter(magazine):
	var reserve = 0
	for i in range(4):
		if inventory[i] == null:
			continue
		if inventory[current_slot] == null:
			continue
		if inventory[i].type != Item.Type.MAG:
			continue
		if inventory[i].weapon_class == inventory[current_slot].weapon_class:
			reserve += inventory[i].size
	var magazine_color = "#FFFFFF"
	var reserve_color = "#FFFFFF"
	if magazine < 10:
		magazine_color = "#FF0000"
	if reserve < 30:
		reserve_color = "#FF0000"

	$HUD/Ammo.bbcode_text = "[color=%s]%s[/color]/[color=%s]%s" % [magazine_color, magazine, reserve_color, reserve]

func switch_item(new_slot):
	if inventory[current_slot] != null:
		inventory[current_slot].visible = false
		if inventory[current_slot].type == Item.Type.GUN:
			$HUD/Ammo.visible = false
	current_slot = new_slot
	if inventory[new_slot] != null:
		inventory[new_slot].visible = true
		if inventory[new_slot].type == Item.Type.GUN:
			$HUD/Ammo.visible = true
			update_ammo_counter(inventory[new_slot].magazine)
	reloading = false

func reload():
	var gun = inventory[current_slot]
	if reloading:
		return
	if gun.type != Item.Type.GUN:
		return
	for i in range(4):
		if inventory[i] == null:
			continue
		if inventory[i].type != Item.Type.MAG:
			continue
		if inventory[i].weapon_class != gun.weapon_class:
			continue
		if inventory[i].size == 0:
			continue
		
		reloading = true
		gun.reload_timer.start()
		yield(gun.reload_timer, "timeout")
		if reloading == false:
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
	if item.is_big and current_slot != 3:
		return

	var target = get_node("Head/Camera/GunPosition")
	rpc("remote_pickup", target.get_path(), item.get_path())
	inventory[current_slot] = item
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
	inventory[current_slot] = null
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
