extends Item

var type = Item.Type.GUN
export var weapon_class = Item.Class.RIFLE

# For the player to access more easily
onready var cooldown = $Cooldown
onready var reload_timer = $Reload
onready var bullet_particles = $BulletParticles

export var damage = 10
export var magazine = 100


func _on_Cooldown_timeout():
	bullet_particles.emitting = false
