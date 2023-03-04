extends CharacterBody3D
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

@export var camera_sensitivity: float = 0.05
@export var speed: float = WALKING_SPEED
@export var acceleration: float = 6.0
@export var jump_impulse: float = 4.0
var velocity: Vector3 = Vector3.ZERO

@onready var world: Node3D = get_node("/root/GameRoot/World")
@onready var aimcast: RayCast3D = $Head/Camera3D/AimCast

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

var handles_input := true

signal health_changed(value)

func _ready():
	modify_money(0)

func _process(delta):
	if not is_multiplayer_authority():
		return
	if not handles_input:
		return
	
	shoot_and_reload()
	pick_and_drop(delta)
	
	if Input.is_action_just_pressed("inventory_first"):
		swap_item(1)
	if Input.is_action_just_pressed("inventory_second"):
		swap_item(2)
	if Input.is_action_just_pressed("inventory_third"):
		swap_item(3)
	if Input.is_action_just_pressed("inventory_big"):
		swap_item(4)

func _physics_process(delta):
	pass

func shoot_and_reload():
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
	if Input.is_action_just_pressed("reload"):
		if inventory[HAND] == null:
			return
		if inventory[HAND].type == Item.Type.GUN:
			reload()

func pick_and_drop(delta):
	if Input.is_action_just_pressed("pickup"):
		if inventory[HAND] != null:
			return
		var collider = aimcast.get_collider()
		if collider != null and collider.get_parent() is Item:
			pickup(collider.get_parent())
	if Input.is_action_just_pressed("drop"):
		throw_charging = true
	elif throw_charging:
		throw_charge_length = min(MAX_THROW_CHARGE, throw_charge_length + delta)
	if Input.is_action_just_released("drop"):
		throw_charging = false
		if inventory[HAND] != null and inventory[HAND].has_method("on_drop"):
			drop(inventory[HAND])
		throw_charge_length = 0

func modify_money(amount):
	money += amount
	if not NetworkManager.is_server: # TODO: ugly af
		$HUD/Money.text = "[color=#00FF00]$[/color]%s" % str(money)

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
	if not NetworkManager.is_server: # TODO: ugly af
		$HUD/Ammo.text = "[color=%s]%s[/color]/[color=%s]%s" % [magazine_color, magazine, reserve_color, reserve]

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
		await inventory[HAND].reload_timer.timeout
		if reloading == false:
			return
		inventory[HAND].magazine = inventory[i].size
		inventory[i].size = 0
		reloading = false
		update_ammo_counter(inventory[HAND].magazine)
		return

@rpc("any_peer", "call_local") func damage(amount):
	health -= amount
	emit_signal('health_changed', health)
	if health <= 0:
		# TODO: implement death
		print("i am ded")

@rpc("any_peer", "call_local") func remote_crouch(crouched):
	if crouched:
		$Body.mesh.set("height", STANDING_HEIGHT[0])
		$Collider.shape.set("height", STANDING_HEIGHT[1])
		self.speed = WALKING_SPEED
	else:
		$Body.mesh.set("height", CROUCHING_HEIGHT[0])
		$Collider.shape.set("height", CROUCHING_HEIGHT[1])
		self.speed = CROUCHING_SPEED

@rpc("any_peer", "call_local") func remote_run(ran): #I have NO idea what to name this var
	self.speed = WALKING_SPEED if ran else RUNNING_SPEED

func pickup(item: Item):
	if !item.has_method("on_pickup"):
		return
	if inventory[HAND] != null:
		return

	var target = get_node("Head/Camera3D/GunPosition")
	rpc("remote_pickup", target.get_path(), item.get_path())
	inventory[HAND] = item
	if item.type == Item.Type.GUN:
		if not NetworkManager.is_server: # TODO: ugly af
			$HUD/Ammo.visible = true
		update_ammo_counter(item.magazine)
	item.is_held = true

@rpc("any_peer", "call_local") func remote_pickup(target_path, item_path):
	var target = get_node(target_path)
	var item = get_node(item_path)
	item.get_parent().remove_child(item)
	target.add_child(item)
	item.set_owner(target)
	item.position = Vector3(0, 0, 0)
	item.rotation = Vector3(0, 0, 0)
	
	item.on_pickup()

func drop(item: Item):
	item.on_drop()
	rpc("remote_drop", item.get_path(), throw_charge_length)
	inventory[HAND] = null
	if not NetworkManager.is_server: # TODO: ugly af
		$HUD/Ammo.visible = false

@rpc("any_peer", "call_local") func remote_drop(item_path, strength: float):
	var item = get_node(item_path) as Item
	item.on_drop()
	item.get_parent().remove_child(item)
	world.add_child(item)
	item.set_owner(world)
	item.position = $Head.global_translation + Vector3(0,-0.125,0)
	item.on_drop()
	print(strength)
	item.apply_central_impulse(-(5 + THROW_STRENGTH * strength) * $Head.global_transform.basis.z)

func set_display_name(name):
	$NameTag.text = name
