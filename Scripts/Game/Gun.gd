extends Spatial

var type = "gun"
var weapon_class = "rifle"

export var magazine_size = 30
export var reserve_size = 100

onready var bullet_spawn = $BulletSpawn
onready var cooldown = $Cooldown
onready var reload_timer = $Reload
var backupaimpoint
var aimcast
var ammoUI
onready var bullet = preload("res://Assets/Prefabs/Bullet.tscn")

var ammo_magazine = magazine_size
var ammo_reserve = reserve_size
var reloading = false

#func _ready():
	#_update_ammo_counter(ammo_magazine, ammo_reserve)

func _update_ammo_counter(mag, res):
	var mag_color = "#FFFFFF"
	var res_color = "#FFFFFF"
	if mag < floor(magazine_size / 3):
		mag_color = "#FF0000"
	if res < floor(reserve_size / 3):
		res_color = "#FF0000"

	ammoUI.bbcode_text = "[color=" + mag_color + "]" + str(mag) + "[/color]"  + "/" + "[color=" + res_color + "]" + str(res) + "[/color]"

func reload():
	if reloading:
		return

	var ammo_requested = min(ammo_reserve, magazine_size-ammo_magazine)
	if ammo_requested > 0:
		reloading = true
		reload_timer.start()
		yield(reload_timer, "timeout")
		ammo_magazine += ammo_requested
		ammo_reserve -= ammo_requested
		_update_ammo_counter(ammo_magazine, ammo_reserve)
		reloading = false


func shoot():
	# TODO: spawn two bullets, one visual and one from the camera to deal damage
	if cooldown.is_stopped() and ammo_magazine > 0 and not reloading:
		cooldown.start()
		ammo_magazine -= 1
		_update_ammo_counter(ammo_magazine, ammo_reserve)

		var b = bullet.instance()
		bullet_spawn.add_child(b)
		if aimcast.is_colliding():
			b.look_at(aimcast.get_collision_point(), Vector3.UP)
		else:
			# so that the bullet doesn't face towards the last collided body
			b.look_at(backupaimpoint.global_transform.origin, Vector3.UP)
	elif ammo_magazine == 0:
		reload()

func picked_up(ammo):
	var parent = get_parent()
	backupaimpoint = parent.get_node("../BackUpAimPoint") as Position3D
	backupaimpoint = parent.get_node("../BackUpAimPoint") as Position3D
	aimcast = parent.get_node("../AimCast") as RayCast
	ammoUI = parent.get_parent().get_node("../../HUD/Ammo") as RichTextLabel
	ammo_reserve = ammo
	_update_ammo_counter(ammo_magazine, ammo_reserve)

func dropped():
	# first int is so signal the class
	return [3, ammo_reserve]
