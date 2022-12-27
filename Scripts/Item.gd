extends RigidBody
class_name Item

onready var collider: CollisionShape = $Collider
enum Type {GUN, BANDAGE, MAG}
enum Class {PISTOL, RIFLE, SHOTGUN}

var is_held: bool = false
var is_big: bool = false

func _ready():
	rset_config('transform', 1)

func _physics_process(_delta):
	if not self.is_network_master():
		return
	if not is_held:
		if not self.sleeping:
			rset_unreliable('transform', self.transform)

func on_pickup():
	self.is_held = true
	self.collider.disabled = true
	self.mode = MODE_STATIC

func on_drop():
	self.is_held = false
	self.collider.disabled = false
	self.mode = MODE_RIGID
