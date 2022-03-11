class_name ShardVisualizer
extends MeshInstance3D

const BreakableSlab = preload("res://fracture_test/BreakableSlab.gd")

@export var target: NodePath

@export var show_combined_aabb := true
@export var show_shard_aabbs := true
@export var show_shard_collision := false

var mesh_impl: ImmediateMesh
var target_node: BreakableSlab
var rand = RandomNumberGenerator.new()
var draw_data := Array()

func _ready() -> void:
	mesh_impl = ImmediateMesh.new()
	mesh =  mesh_impl
	
	target_node = get_node(target)
	var mat = StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true 
	set_material_override(mat)


func _process(_delta):
	mesh_impl.clear_surfaces()
	# Give random colors, but similiar each frame by initializing with same seed
	rand.seed = get_instance_id()
	if target_node:
		if show_combined_aabb:
			draw_combined_aabb(target_node)
		if show_shard_aabbs:
			draw_shard_aabbs(target_node)
		if show_shard_collision:
			draw_shard_collision(target_node)
		else:
			draw_data.clear()
	else:
		draw_data.clear()


func draw_combined_aabb(node: BreakableSlab):
	var c = Color(rand.randi())
	c.a = 1
	draw_aabb(node._custom_aabb, node.transform, c)


func draw_shard_aabbs(node: BreakableSlab):
	for shard in node._shards:
		var c = Color(rand.randi())
		c.a = 1
		draw_aabb(shard.aabb, node.get_shard_mesh_transform(shard), c)


func draw_shard_collision(node: BreakableSlab):
	draw_data.resize(node._shards.size())
	for i in node._shards.size():
		var shard = node._shards[i]
		if not shard.body.is_valid():
			draw_data[i] = null
			continue
		
		var shard_transform := node.get_shard_physics_transform(shard)
		var color = Color(rand.randi())
		color.a = 1
		var shape := PhysicsServer3D.body_get_shape(shard.body, 0)
		var shape_transform := PhysicsServer3D.body_get_shape_transform(shard.body, 0)
		var shape_type := PhysicsServer3D.shape_get_type(shape)
		var shape_data = PhysicsServer3D.shape_get_data(shape)
		
		var world_transform = shard_transform * shape_transform
		if shape_type == PhysicsServer3D.SHAPE_BOX:
			draw_data[i] = null
			draw_box(shape_data * 0.5, world_transform, color)
		elif shape_type == PhysicsServer3D.SHAPE_CYLINDER:
			draw_data[i] = null
			draw_cylinder(shape_data["radius"], shape_data["height"], world_transform, color)
		elif shape_type == PhysicsServer3D.SHAPE_CONVEX_POLYGON:
			if not draw_data[i]:
				var poly_shape = ConvexPolygonShape3D.new()
				poly_shape.points = shape_data
				var dmesh = poly_shape.get_debug_mesh()
				draw_data[i] = dmesh
#				var tmesh = dmesh.generate_triangle_mesh()
#				draw_data[i] = tmesh
			draw_mesh(draw_data[i], world_transform, color)
		else:
			# TODO
			pass


func draw_mesh(mesh: Mesh, shape_transform: Transform3D, color:Color) -> void:
	mesh_impl.surface_begin(Mesh.PRIMITIVE_LINES)
	mesh_impl.surface_set_color(color)
	mesh_impl.surface_set_normal(Vector3(1, 0, 0))

	var arrays := mesh.surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	if arrays[Mesh.ARRAY_INDEX]:
		var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
		for i in indices.size() / 3:
			var idx0 = indices[3 * i + 0]
			var idx1 = indices[3 * i + 1]
			var idx2 = indices[3 * i + 2]
			draw_line(vertices[idx0], vertices[idx1], shape_transform)
			draw_line(vertices[idx1], vertices[idx2], shape_transform)
			draw_line(vertices[idx2], vertices[idx0], shape_transform)
	else:
		for i in vertices.size() / 3:
			var v0 = vertices[3 * i + 0]
			var v1 = vertices[3 * i + 1]
			var v2 = vertices[3 * i + 2]
			draw_line(v0, v1, shape_transform)
			draw_line(v1, v2, shape_transform)
			draw_line(v2, v0, shape_transform)
	
	mesh_impl.surface_end()


func draw_aabb(aabb: AABB, aabb_transform: Transform3D, color: Color):
	var shape_transform = aabb_transform * Transform3D(Basis.IDENTITY, aabb.get_center())
	var half_extent = aabb.size * 0.5
	draw_box(half_extent, shape_transform, color)


func draw_box(half_extent: Vector3, shape_transform: Transform3D, color:Color) -> void:
	mesh_impl.surface_begin(Mesh.PRIMITIVE_LINES)
	mesh_impl.surface_set_color(color)
	mesh_impl.surface_set_normal(Vector3(1, 0, 0))

	var swizzle := func swizzle_fn(x, y, z):
		return Vector3(x * half_extent.x, y * half_extent.y, z * half_extent.z)
	draw_line(swizzle.call( 1,  1,  1), swizzle.call(-1,  1,  1), shape_transform)
	draw_line(swizzle.call(-1,  1,  1), swizzle.call(-1, -1,  1), shape_transform)
	draw_line(swizzle.call(-1, -1,  1), swizzle.call( 1, -1,  1), shape_transform)
	draw_line(swizzle.call( 1, -1,  1), swizzle.call( 1,  1,  1), shape_transform)

	draw_line(swizzle.call( 1,  1, -1), swizzle.call(-1,  1, -1), shape_transform)
	draw_line(swizzle.call(-1,  1, -1), swizzle.call(-1, -1, -1), shape_transform)
	draw_line(swizzle.call(-1, -1, -1), swizzle.call( 1, -1, -1), shape_transform)
	draw_line(swizzle.call( 1, -1, -1), swizzle.call( 1,  1, -1), shape_transform)

	draw_line(swizzle.call( 1,  1,  1), swizzle.call( 1,  1, -1), shape_transform)
	draw_line(swizzle.call(-1,  1,  1), swizzle.call(-1,  1, -1), shape_transform)
	draw_line(swizzle.call(-1, -1,  1), swizzle.call(-1, -1, -1), shape_transform)
	draw_line(swizzle.call( 1, -1,  1), swizzle.call( 1, -1, -1), shape_transform)
	
	mesh_impl.surface_end()


func draw_cylinder(radius: float, height: float, shape_transform: Transform3D, color: Color):
	mesh_impl.surface_begin(Mesh.PRIMITIVE_LINES)
	mesh_impl.surface_set_color(color)
	mesh_impl.surface_set_normal(Vector3(1, 0, 0))

	var segments = 12
	for i in segments:
		var angle0 = 2.0 * PI * i / segments
		var angle1 = 2.0 * PI * (i + 1) / segments
		var base0 := Vector3(cos(angle0), 0, sin(angle0)) * radius
		var base1 := Vector3(cos(angle1), 0, sin(angle1)) * radius
		draw_line(base0 + Vector3(0, 0.5 * height, 0), base0 + Vector3(0, -0.5 * height, 0), shape_transform)
		draw_line(base0 + Vector3(0, 0.5 * height, 0), base1 + Vector3(0, 0.5 * height, 0), shape_transform)
		draw_line(base0 + Vector3(0, -0.5 * height, 0), base1 + Vector3(0, -0.5 * height, 0), shape_transform)
	
	mesh_impl.surface_end()


func draw_line(a: Vector3, b: Vector3, shape_transform: Transform3D):
	mesh_impl.surface_add_vertex(to_local(shape_transform * a))
	mesh_impl.surface_add_vertex(to_local(shape_transform * b))
