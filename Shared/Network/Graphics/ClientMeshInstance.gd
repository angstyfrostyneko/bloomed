@tool
extends Node3D
class_name ClientMeshInstance

@export var mesh: Mesh = null : set = set_mesh

# Store the InstanceMesh node here
var _mesh_node: MeshInstance3D = null


func _ready() -> void:
	if (Engine.is_editor_hint() || !NetworkManager.is_server):
		_mesh_node = MeshInstance3D.new()
		_mesh_node.set_name("mesh")
		add_child(_mesh_node)
		# This is necessary for pre-created nodes (level design for example)
		_mesh_node.mesh = mesh


func set_mesh(m: Mesh) -> void:
	mesh = m
	call_deferred("_check_mesh")


func _check_mesh() -> void:
	if (_mesh_node):
		_mesh_node.mesh = mesh
