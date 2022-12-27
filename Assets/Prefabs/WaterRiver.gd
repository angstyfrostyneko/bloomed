tool
extends MeshInstance

export var width := 1
export var length := 1

# Resolution is length of quad
export var resolution := 0.5


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	var st = SurfaceTool.new()
	
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var uv_ratio := max(width, length)
	
	var x := 0.0
	while x < width:
		var z := 0.0
		while z < length:
			st.add_normal(Vector3(0, 1, 0))
			st.add_uv(Vector2(x/uv_ratio, z/uv_ratio))
			st.add_vertex(Vector3(x, 0, z))
			
			st.add_normal(Vector3(0, 1, 0))
			st.add_uv(Vector2((x+resolution)/uv_ratio, z/uv_ratio))
			st.add_vertex(Vector3(x+resolution, 0, z))
			
			st.add_normal(Vector3(0, 1, 0))
			st.add_uv(Vector2(x/uv_ratio, (z+resolution)/uv_ratio))
			st.add_vertex(Vector3(x, 0, z+resolution))
			
			st.add_normal(Vector3(0, 1, 0))
			st.add_uv(Vector2((x+resolution)/uv_ratio, (z+resolution)/uv_ratio))
			st.add_vertex(Vector3(x+resolution, 0, z+resolution))
			
			st.add_normal(Vector3(0, 1, 0))
			st.add_uv(Vector2(x/uv_ratio, (z+resolution)/uv_ratio))
			st.add_vertex(Vector3(x, 0, z+resolution))
			
			st.add_normal(Vector3(0, 1, 0))
			st.add_uv(Vector2((x+resolution)/uv_ratio, z/uv_ratio))
			st.add_vertex(Vector3(x+resolution, 0, z))
			z += resolution
		x += resolution
	
	st.index()
	
	self.mesh = st.commit()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
