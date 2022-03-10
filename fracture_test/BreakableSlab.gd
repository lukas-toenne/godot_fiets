extends MeshInstance3D
class_name BreakableSlab

@export var Width := 1.0
@export var Height := 1.0
@export var Depth := 0.01

# Limit for colliders, particles will be used if limit is reached.
@export var MaxColliders := 40
# Limit for convex colliders, more box colliders may be created if limit is reached.
@export var MaxConvexColliders := 10
# Minimum size of colliders, use particles below this shard size.
@export var ParticleSizeThreshold := 0.08
# Minimum size of convex colliders, use box colliders below this size.
@export var BoxColliderSizeThreshold := 0.2

const MeshOps = preload("res://fracture_test/MeshOps.gd")
const MAX_SHARDS = 256

var _material = preload("res://fracture_test/fracture_test_material.tres")

class Shard:
	var body := RID()
	# Transform in local space so geometry aligns with the physics body.
	var body_offset := Transform3D.IDENTITY
	var aabb := AABB()
	var principal_components := Vector3.ONE
	var shape_type := PhysicsServer3D.SHAPE_CUSTOM

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

func _exit_tree():
	pass


#func shard_moved_cb(state, index):
#	pass


func get_shard_mesh_transform(shard: Shard) -> Transform3D:
	return get_shard_physics_transform(shard) * shard.body_offset


func get_shard_physics_transform(shard: Shard) -> Transform3D:
	return PhysicsServer3D.body_get_state(shard.body, PhysicsServer3D.BODY_STATE_TRANSFORM)


# Get shard AABB in node space.
func get_shard_local_aabb(shard: Shard) -> AABB:
	return (transform.inverse() * get_shard_mesh_transform(shard)) * shard.aabb

# Get shard AABB in world space.
func get_shard_transformed_aabb(shard: Shard) -> AABB:
	return get_shard_mesh_transform(shard) * shard.aabb


func _physics_process(delta):
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


func _init_shard_physics(shard: Shard, index: int, shape: RID):
	# Create rigid body
	shard.body = PhysicsServer3D.body_create()
	PhysicsServer3D.body_set_space(shard.body, get_world_3d().space)
	PhysicsServer3D.body_set_mode(shard.body, PhysicsServer3D.BODY_MODE_DYNAMIC)
#	var shape = PhysicsServer3D.cylinder_shape_create()
#	PhysicsServer3D.shape_set_data(shape, {"radius": 0.03, "height": 0.1})
	PhysicsServer3D.body_add_shape(shard.body, shape)

#	PhysicsServer3D.body_set_force_integration_callback(shard.body, Callable(self, "shard_moved_cb"), index)
	PhysicsServer3D.body_set_state(shard.body, PhysicsServer3D.BODY_STATE_TRANSFORM, transform * shard.body_offset.inverse())


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
	var shard_vertex_counts := PackedInt32Array()
	shard_vertex_counts.resize(num_shards)
	shard_vertex_counts.fill(0)
	var shard_centroids := PackedVector3Array()
	shard_centroids.resize(num_shards)
	shard_centroids.fill(Vector3.ZERO)
	var shard_min := PackedVector3Array()
	shard_min.resize(num_shards)
	var shard_max := PackedVector3Array()
	shard_max.resize(num_shards)
	for i in vertices.size():
		var shard_index := custom0[4 * i + 0] + (custom0[4 * i + 1] << 8) + (custom0[4 * i + 2] << 16) + (custom0[4 * i + 3] << 24)
		var current_count := shard_vertex_counts[shard_index]
		shard_vertex_counts[shard_index] += 1
		shard_centroids[shard_index] += vertices[i]
		shard_min[shard_index] = compwise_min(shard_min[shard_index], vertices[i]) if current_count > 0 else vertices[i]
		shard_max[shard_index] = compwise_max(shard_max[shard_index], vertices[i]) if current_count > 0 else vertices[i]
	# Normalize centroids
	for i in num_shards:
		shard_centroids[i] /= shard_vertex_counts[i]
	
	# Correlation matrix used for simplified 2D PCA
	# Contains 4 entries for each shard, representing correlation values sigma_xx, sigma_xy, sigma_yy, sigma_zz
	# We only look at x and y components for 2D correlation and PCA for simplicity,
	# assuming that the shard will be mostly flat in the Z plane.
	var shard_correlation := PackedFloat32Array()
	shard_correlation.resize(4 * num_shards)
	shard_correlation.fill(0.0)
	for i in vertices.size():
		var shard_index := custom0[4 * i + 0] + (custom0[4 * i + 1] << 8) + (custom0[4 * i + 2] << 16) + (custom0[4 * i + 3] << 24)
		var delta = vertices[i] - shard_centroids[shard_index]
		shard_correlation[4 * shard_index + 0] += delta.x * delta.x
		shard_correlation[4 * shard_index + 1] += delta.x * delta.y
		shard_correlation[4 * shard_index + 2] += delta.y * delta.y
		shard_correlation[4 * shard_index + 3] += delta.z * delta.z
	# Normalize correlation
	for i in num_shards:
		shard_correlation[4 * i + 0] /= shard_vertex_counts[i]
		shard_correlation[4 * i + 1] /= shard_vertex_counts[i]
		shard_correlation[4 * i + 2] /= shard_vertex_counts[i]
		shard_correlation[4 * i + 3] /= shard_vertex_counts[i]

	# Create shards
	_shards.resize(num_shards)
	for i in _shards.size():
		# Eigenvalues of the 2D correlation matrix are a quadratic equation.
		var s_xx := shard_correlation[4 * i + 0]
		var s_xy := shard_correlation[4 * i + 1]
		var s_yy := shard_correlation[4 * i + 2]
		var s_zz := shard_correlation[4 * i + 3]
		var s_diag = sqrt((s_xx - s_yy) * (s_xx - s_yy) + 4.0 * s_xy * s_xy)
		var lambda_pos := 0.5 * (s_xx + s_yy + s_diag)
		var lambda_neg := 0.5 * (s_xx + s_yy - s_diag)
		# Rotation matrix for orientating the collision box along the principal axis
		var v0 := Vector3(s_xx + s_xy - lambda_neg, s_yy + s_xy - lambda_neg, 0.0).normalized()
		var v1 := Vector3(s_xx + s_xy - lambda_pos, s_yy + s_xy - lambda_pos, 0.0).normalized()
		var v2 := v0.cross(v1) # This is just Z

		_shards[i] = Shard.new()
		_shards[i].body_offset = Transform3D(Basis(v0, v1, v2), shard_centroids[i]).inverse()
		_shards[i].aabb = AABB(shard_min[i], shard_max[i] - shard_min[i])
		_shards[i].principal_components = 2.0 * Vector3(sqrt(lambda_pos), sqrt(lambda_neg), sqrt(s_zz))

	# Index array to sort shards by size in descending order (largest shards first).
	# Has to be a regular Array, PackedInt32Array cannot be sorted by custom key.
	var sorted_index = Array()
	sorted_index.resize(num_shards)
	for i in num_shards:
		sorted_index[i] = i
	var compare_size := func compare_size_fn(a, b):
		return _shards[a].principal_components[0] > _shards[b].principal_components[0]
	sorted_index.sort_custom(compare_size)
	# Assign shape types based on size and budget.
	var current = 0
	while current < min(MaxConvexColliders, MaxColliders, num_shards):
		var shard = _shards[sorted_index[current]]
		if shard.principal_components[0] <= BoxColliderSizeThreshold:
			break
		shard.shape_type = PhysicsServer3D.SHAPE_CONVEX_POLYGON
		current += 1
	var num_convex = current
	while current < min(MaxColliders, num_shards):
		var shard = _shards[sorted_index[current]]
		if shard.principal_components[0] <= ParticleSizeThreshold:
			break
		shard.shape_type = PhysicsServer3D.SHAPE_BOX
		current += 1
	var num_box = current - num_convex
	while current < num_shards:
		var shard = _shards[sorted_index[current]]
		shard.shape_type = PhysicsServer3D.SHAPE_CUSTOM
		current += 1
	var num_particle = current - num_box

	# Stores arrays of vertices for shards with convex hull shapes,
	# these are needed in separate lists for shape creation.
	var convex_hull_verts := Array()
	convex_hull_verts.resize(vertices.size())
	for i in vertices.size():
		var shard_index := custom0[4 * i + 0] + (custom0[4 * i + 1] << 8) + (custom0[4 * i + 2] << 16) + (custom0[4 * i + 3] << 24)
		var shard : Shard = _shards[shard_index]
		if shard.shape_type == PhysicsServer3D.SHAPE_CONVEX_POLYGON:
			if not convex_hull_verts[i]:
				convex_hull_verts[i] = PackedVector3Array()
				

	for i in _shards.size():
		var shard = _shards[i]
		var shape := RID()
		if shard.shape_type == PhysicsServer3D.SHAPE_CONVEX_POLYGON:
			shape = PhysicsServer3D.convex_polygon_shape_create()
			PhysicsServer3D.shape_set_data(shape, vertices)
		elif shard.shape_type == PhysicsServer3D.SHAPE_CONVEX_POLYGON:
			shape = PhysicsServer3D.box_shape_create()
			PhysicsServer3D.shape_set_data(shape, shard.principal_components)
		_init_shard_physics(shard, i, shape)


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
