extends MeshInstance3D
class_name BreakableSlab

@export var Width := 1.0
@export var Height := 1.0
@export var Depth := 0.01

const MeshOps = preload("res://fracture_test/MeshOps.gd")

var _material = preload("res://fracture_test/fracture_test_material.tres")


func _ready():
#	create_base_mesh()
	create_prefrac_mesh()


var _time := 0.0
func _process(delta):
	_time += delta
	var mat: ShaderMaterial = mesh.surface_get_material(0)
	var shard_location = PackedVector3Array()
	shard_location.resize(256)
	shard_location[0] = Vector3(sin(_time), cos(_time), 0.0)
	mat.set_shader_param("shard_location", shard_location)

func create_base_mesh():
	var vertices := PackedVector3Array()
	vertices.push_back(Vector3(Width/2, Height/2, 0))
	vertices.push_back(Vector3(Width/2, -Height/2, 0))
	vertices.push_back(Vector3(-Width/2, -Height/2, 0))
	vertices.push_back(Vector3(-Width/2, Height/2, 0))

	var normals := PackedVector3Array()
	normals.resize(4)
	normals.fill(Vector3(0, 0, 1))

	var tex_uv = PackedVector2Array()
	tex_uv.push_back(Vector2(1, 1))
	tex_uv.push_back(Vector2(1, 0))
	tex_uv.push_back(Vector2(0, 0))
	tex_uv.push_back(Vector2(0, 1))

	var indices := PackedInt32Array()
	indices.append_array([0, 1, 2])
	indices.append_array([2, 3, 0])

#	var boundary = PackedInt32Array()
#	boundary.append_array([0, 1, 1, 2, 2, 3, 3, 0])

	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = tex_uv
	arrays[Mesh.ARRAY_INDEX] = indices

	var boundary := MeshOps.find_boundary(indices)
	MeshOps.extrude_polygon(arrays, boundary, Depth)

	var arr_mesh := ArrayMesh.new()
	arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	arr_mesh.surface_set_material(0, _material)
	mesh = arr_mesh


func create_prefrac_mesh():
	var in_arrays = $prefractured/Plane.mesh.surface_get_arrays(0)

	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = in_arrays[Mesh.ARRAY_VERTEX]
	arrays[Mesh.ARRAY_NORMAL] = in_arrays[Mesh.ARRAY_NORMAL]
	arrays[Mesh.ARRAY_TANGENT] = in_arrays[Mesh.ARRAY_TANGENT]
	arrays[Mesh.ARRAY_TEX_UV] = in_arrays[Mesh.ARRAY_TEX_UV]
	arrays[Mesh.ARRAY_INDEX] = in_arrays[Mesh.ARRAY_INDEX]

	var boundary := MeshOps.find_boundary(arrays[Mesh.ARRAY_INDEX])
	MeshOps.extrude_polygon(arrays, boundary, Depth)

	var arr_mesh := ArrayMesh.new()
	arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	arr_mesh.surface_set_material(0, _material)
	mesh = arr_mesh
