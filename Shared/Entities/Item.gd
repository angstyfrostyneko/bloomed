extends RigidBody3D
class_name Item

@onready var collider: CollisionShape3D = $Collider
enum Type {GUN, BANDAGE, MAG}
enum Class {PISTOL, RIFLE, SHOTGUN}

var id: int = -1

var is_held: bool = false
var is_big: bool = false

func _ready():
	pass

func spawn(tree: SceneTree):
	self.id = get_instance_id()
	self.name = str(self.id)
	tree.get_root().get_node("/root/GameRoot").spawn_item(self)

func _physics_process(_delta):
	if not self.is_multiplayer_authority():
		return
	if not is_held:
		if not self.sleeping:
			rpc('sync_state', self.transform)

@rpc("unreliable", "any_peer")
func sync_state(transform: Transform3D):
	self.transform = transform
	
func on_pickup():
	self.is_held = true
	self.collider.disabled = true
	self.freeze = true

func on_drop():
	self.is_held = false
	self.collider.disabled = false
	self.freeze = false
