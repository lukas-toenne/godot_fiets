extends MeshInstance3D
class_name BreakableSlab

@export var Width := 1.0
@export var Height := 1.0
@export var Depth := 0.01

const MeshOps = preload("res://fracture_test/MeshOps.gd")
const MAX_SHARDS = 256

var _material = preload("res://fracture_test/fracture_test_material.tres")

class Shard:
	var body := RID()
	# Transform of the visible mesh so it aligns with the physics body.
	var center_of_mass_transform := Transform3D.IDENTITY
	var aabb := AABB()

var _shards := []
# Uniform buffers for displacement in the shader
var _shader_shard_location := PackedVector3Array()
var _shader_shard_rotation := PackedVector3Array()
var _custom_aabb := AABB()

func _init():
	_shader_shard_location.resize(MAX_SHARDS)
	_shader_shard_rotation.resize(3 * MAX_SHARDS)

func _enter_tree():
#	mesh = construct_base_mesh()
#	mesh = construct_test_mesh()
	mesh = construct_prefrac_mesh()

	_create_shards_from_mesh()

	for i in _shards.size():
		init_shard(_shards[i], i)

func _exit_tree():
	pass


func init_shard(shard: Shard, index: int):
	# Create rigid body
	shard.body = PhysicsServer3D.body_create()
	PhysicsServer3D.body_set_space(shard.body, get_world_3d().space)
	PhysicsServer3D.body_set_mode(shard.body, PhysicsServer3D.BODY_MODE_DYNAMIC)
	var shape = PhysicsServer3D.cylinder_shape_create()
	PhysicsServer3D.shape_set_data(shape, {"radius": 0.03, "height": 0.1})
	PhysicsServer3D.body_add_shape(shard.body, shape)
	PhysicsServer3D.body_set_state(shard.body, PhysicsServer3D.BODY_STATE_TRANSFORM, Transform3D(Basis.IDENTITY, Vector3(0, 10, 0)))
#	PhysicsServer3D.body_set_force_integration_callback(shard.body, Callable(self, "shard_moved_cb"), index)


#func shard_moved_cb(state, index):
#	pass


func get_shard_mesh_transform(shard: Shard) -> Transform3D:
	return get_shard_physics_transform(shard) * shard.center_of_mass_transform


func get_shard_physics_transform(shard: Shard) -> Transform3D:
	return PhysicsServer3D.body_get_state(shard.body, PhysicsServer3D.BODY_STATE_TRANSFORM)


# Get shard AABB in node space.
func get_shard_local_aabb(shard: Shard) -> AABB:
	return (transform.inverse() * get_shard_mesh_transform(shard)) * shard.aabb

# Get shard AABB in world space.
func get_shard_transformed_aabb(shard: Shard) -> AABB:
	return get_shard_mesh_transform(shard) * shard.aabb


func _process(delta):
	# TODO disable update when all shards are sleeping
	var inv_transform = transform.inverse()
	var aabb = null
	for i in min(_shards.size(), MAX_SHARDS):
		var shard = _shards[i]
		var local_transform = inv_transform * get_shard_mesh_transform(shard)
		_shader_shard_location[i] = local_transform.origin
		_shader_shard_rotation[3 * i + 0] = local_transform.basis.x
		_shader_shard_rotation[3 * i + 1] = local_transform.basis.y
		_shader_shard_rotation[3 * i + 2] = local_transform.basis.z
		
		if i == 0:
			aabb = get_shard_local_aabb(shard)
		else:
			aabb = aabb.merge(get_shard_local_aabb(shard))

	var mat: ShaderMaterial = mesh.surface_get_material(0)
	mat.set_shader_param("shard_location", _shader_shard_location)
	mat.set_shader_param("shard_rotation", _shader_shard_rotation)
	
	if aabb:
		_custom_aabb = aabb
		set_custom_aabb(aabb)
	else:
		set_custom_aabb(AABB())


static func compwise_min(a: Vector3, b: Vector3) -> Vector3:
	return Vector3(min(a.x, b.x), min(a.y, b.y), min(a.z, b.z))


static func compwise_max(a: Vector3, b: Vector3) -> Vector3:
	return Vector3(max(a.x, b.x), max(a.y, b.y), max(a.z, b.z))


func _create_shards_from_mesh():
	assert(mesh)
	var arrays = mesh.surface_get_arrays(0)
	var vertices = arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array
	var custom0 = arrays[Mesh.ARRAY_CUSTOM0] as PackedByteArray

	# Count the number of required shards
	var num_shards := 0
	for i in vertices.size():
		var shard_index := custom0[4 * i + 0] + (custom0[4 * i + 1] << 8) + (custom0[4 * i + 2] << 16) + (custom0[4 * i + 3] << 24)
		if shard_index + 1 > num_shards:
			num_shards = shard_index + 1

	# Compute AABBs and transforms for shard physics
	var shard_centroids = PackedVector3Array()
	shard_centroids.resize(num_shards)
	shard_centroids.fill(Vector3.ZERO)
	var shard_min = PackedVector3Array()
	shard_min.resize(num_shards)
	var shard_max = PackedVector3Array()
	shard_max.resize(num_shards)
	var shard_vertex_counts = PackedInt32Array()
	shard_vertex_counts.resize(num_shards)
	shard_vertex_counts.fill(0)

	for i in vertices.size():
		var shard_index := custom0[4 * i + 0] + (custom0[4 * i + 1] << 8) + (custom0[4 * i + 2] << 16) + (custom0[4 * i + 3] << 24)
		var current_count := shard_vertex_counts[shard_index]
		shard_centroids[shard_index] += vertices[i]
		shard_min[shard_index] = compwise_min(shard_min[shard_index], vertices[i]) if current_count > 0 else vertices[i]
		shard_max[shard_index] = compwise_max(shard_max[shard_index], vertices[i]) if current_count > 0 else vertices[i]
		shard_vertex_counts[shard_index] += 1
	# Create shards
	_shards.resize(num_shards)
	for i in _shards.size():
		shard_centroids[i] /= shard_vertex_counts[i]
		_shards[i] = Shard.new()
		_shards[i].center_of_mass_transform = Transform3D(Basis.IDENTITY, -shard_centroids[i])
		_shards[i].aabb = AABB(shard_min[i], shard_max[i] - shard_min[i])


func _create_mesh_from_arrays(arrays: Array) -> ArrayMesh:
	var vertices = arrays[Mesh.ARRAY_VERTEX]
	var indices = arrays[Mesh.ARRAY_INDEX]
	var islands := PackedInt32Array()
	islands.resize(vertices.size())
	MeshOps.find_islands(indices, islands)
	
	# Encode shard index in the CUSTOM0 vertex attribute
	var custom0 := PackedByteArray()
	custom0.resize(4 * vertices.size())
	for i in vertices.size():
		var shard_index := islands[i]
		custom0[4 * i + 0] = shard_index & 0x000000ff
		custom0[4 * i + 1] = shard_index & 0x0000ff00
		custom0[4 * i + 2] = shard_index & 0x00ff0000
		custom0[4 * i + 3] = shard_index & 0xff000000
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
	return _create_mesh_from_arrays(arrays)


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
	return _create_mesh_from_arrays(arrays)


func construct_prefrac_mesh():
	var in_arrays = $prefractured/Plane.mesh.surface_get_arrays(0)

	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = in_arrays[Mesh.ARRAY_VERTEX]
	arrays[Mesh.ARRAY_NORMAL] = in_arrays[Mesh.ARRAY_NORMAL]
	arrays[Mesh.ARRAY_TANGENT] = in_arrays[Mesh.ARRAY_TANGENT]
	arrays[Mesh.ARRAY_TEX_UV] = in_arrays[Mesh.ARRAY_TEX_UV]
	arrays[Mesh.ARRAY_INDEX] = in_arrays[Mesh.ARRAY_INDEX]
	return _create_mesh_from_arrays(arrays)
