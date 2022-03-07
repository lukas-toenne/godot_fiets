extends MeshInstance3D
class_name BreakableSlab

@export var Width := 1.0
@export var Height := 1.0
@export var Depth := 0.01

const MeshOps = preload("res://fracture_test/MeshOps.gd")
const MAX_SHARDS = 256

var _material = preload("res://fracture_test/fracture_test_material.tres")

class Shard:
	func _init():
		pass

var _shards := []
var _param_shard_location := PackedVector3Array()
var _param_shard_rotation := PackedVector3Array()
var _param_shard_rotation_inv_transpose := PackedVector3Array()

func _ready():
	_param_shard_location.resize(MAX_SHARDS)
	_param_shard_rotation.resize(3 * MAX_SHARDS)
	_param_shard_rotation_inv_transpose.resize(3 * MAX_SHARDS)

#	mesh = construct_base_mesh()
#	mesh = construct_test_mesh()
	mesh = construct_prefrac_mesh()


func expand_aabb_transform(transform: Transform3D, aabb: AABB):
	var a := get_aabb().position
	var b := get_aabb().end
	aabb.expand(transform * a)
	aabb.expand(transform * Vector3(b.x, a.y, a.z))
	aabb.expand(transform * Vector3(a.x, b.y, a.z))
	aabb.expand(transform * Vector3(b.x, b.y, a.z))
	aabb.expand(transform * Vector3(a.x, a.y, b.z))
	aabb.expand(transform * Vector3(b.x, a.y, b.z))
	aabb.expand(transform * Vector3(a.x, b.y, b.z))
	aabb.expand(transform * b)

var _time := 0.0
func _process(delta):
	_time += delta
	var mat: ShaderMaterial = mesh.surface_get_material(0)
	var rng = RandomNumberGenerator.new()
	rng.seed = 12345
	var aabb = AABB()
	for i in min(_shards.size(), MAX_SHARDS):
		var shard = _shards[i]
		var phase = rng.randf_range(0, 2*PI)
		var speed = rng.randf_range(1.5, 2.5)
		var angle = _time * speed + phase
		var transform = Transform3D(Basis.IDENTITY, Vector3(sin(angle), cos(angle), 0.0))
		_param_shard_location[i] = transform.origin
		_param_shard_rotation[3 * i + 0] = transform.basis.x
		_param_shard_rotation[3 * i + 1] = transform.basis.y
		_param_shard_rotation[3 * i + 2] = transform.basis.z
		var inv_basis = transform.basis.inverse().transposed()
		_param_shard_rotation_inv_transpose[3 * i + 0] = inv_basis.x
		_param_shard_rotation_inv_transpose[3 * i + 1] = inv_basis.y
		_param_shard_rotation_inv_transpose[3 * i + 2] = inv_basis.z
		
		var orig_aabb = get_aabb()
		orig_aabb.
	mat.set_shader_param("shard_location", _param_shard_location)
	mat.set_shader_param("shard_rotation", _param_shard_rotation)
	mat.set_shader_param("shard_rotation_inv_transpose", _param_shard_rotation_inv_transpose)
	
	var aabb := AABB()
	set_custom_aabb(aabb)


func create_mesh(arrays: Array) -> ArrayMesh:
	var vertices = arrays[Mesh.ARRAY_VERTEX]
	var indices = arrays[Mesh.ARRAY_INDEX]
	var islands := PackedInt32Array()
	islands.resize(vertices.size())
	MeshOps.find_islands(indices, islands)
	
	# Encode shard index in the CUSTOM0 vertex attribute
	_shards.clear()
	var custom0 := PackedByteArray()
	custom0.resize(4 * vertices.size())
	for i in vertices.size():
		var shard_index = islands[i]
		custom0[4 * i + 0] = shard_index & 0x000000ff
		custom0[4 * i + 1] = shard_index & 0x0000ff00
		custom0[4 * i + 2] = shard_index & 0x00ff0000
		custom0[4 * i + 3] = shard_index & 0xff000000

		var current_size = _shards.size()
		_shards.resize(max(current_size, shard_index + 1))
		for j in range(current_size, _shards.size()):
			_shards[j] = Shard.new()
	arrays[Mesh.ARRAY_CUSTOM0] = custom0

	var boundary := MeshOps.find_boundary(arrays[Mesh.ARRAY_INDEX])
	MeshOps.extrude_mesh(arrays, boundary, Depth)

	var arr_mesh := ArrayMesh.new()
	arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	arr_mesh.surface_set_material(0, _material)

	return arr_mesh


func construct_base_mesh():
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

	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = tex_uv
	arrays[Mesh.ARRAY_INDEX] = indices
	return create_mesh(arrays)


func construct_test_mesh():
	var vertices := PackedVector3Array()
	vertices.push_back(Vector3(Width/2, Height/2, 0))
	vertices.push_back(Vector3(Width/2, -Height/2, 0))
	vertices.push_back(Vector3(-Width/2, -Height/2, 0))
	vertices.push_back(Vector3(-Width/2, -Height/2, 0))
	vertices.push_back(Vector3(-Width/2, Height/2, 0))
	vertices.push_back(Vector3(Width/2, Height/2, 0))

	var normals := PackedVector3Array()
	normals.resize(4)
	normals.fill(Vector3(0, 0, 1))

	var tex_uv = PackedVector2Array()
	tex_uv.push_back(Vector2(1, 1))
	tex_uv.push_back(Vector2(1, 0))
	tex_uv.push_back(Vector2(0, 0))
	tex_uv.push_back(Vector2(0, 0))
	tex_uv.push_back(Vector2(0, 1))
	tex_uv.push_back(Vector2(1, 1))

	var indices := PackedInt32Array()
	indices.append_array([0, 1, 2])
	indices.append_array([3, 4, 5])

	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = tex_uv
	arrays[Mesh.ARRAY_INDEX] = indices
	return create_mesh(arrays)


func construct_prefrac_mesh():
	var in_arrays = $prefractured/Plane.mesh.surface_get_arrays(0)

	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = in_arrays[Mesh.ARRAY_VERTEX]
	arrays[Mesh.ARRAY_NORMAL] = in_arrays[Mesh.ARRAY_NORMAL]
	arrays[Mesh.ARRAY_TANGENT] = in_arrays[Mesh.ARRAY_TANGENT]
	arrays[Mesh.ARRAY_TEX_UV] = in_arrays[Mesh.ARRAY_TEX_UV]
	arrays[Mesh.ARRAY_INDEX] = in_arrays[Mesh.ARRAY_INDEX]
	return create_mesh(arrays)
