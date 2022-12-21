extends Item

var type = "gun"
var weapon_class = Weapon.Class.RIFLE

# For the player to access more easily
onready var cooldown = $Cooldown
onready var reload_timer = $Reload

var damage = 10
var magazine = 100
