@tool
extends Node3D
class_name EntitySpawner

@export var entity: PackedScene = null : set = set_entity
@export var entity_name: String = "SpawnedEntity"

# Store the InstanceMesh node here
var _scene: Node3D = null

func _ready() -> void:
	if (Engine.is_editor_hint() or NetworkManager.is_server):
		_scene = entity.instantiate()
		_scene.set_name(entity_name)
		if !Engine.is_editor_hint() and NetworkManager.is_server:
			_scene.spawn(get_tree())
			self.queue_free()
		else:
			self.add_child(_scene)
		


func set_entity(m: PackedScene) -> void:
	entity = m

