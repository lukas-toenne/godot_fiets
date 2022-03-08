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


func draw_combined_aabb(node: BreakableSlab):
	var c = Color(rand.randi())
	c.a = 1
	draw_aabb(node._custom_aabb, node.transform, c)


func draw_shard_aabbs(node: BreakableSlab):
	for i in node._shards.size():
		var shard_transform := node.get_shard_transform(i)
		var c = Color(rand.randi())
		c.a = 1
		var aabb = node.get_shard_aabb(shard_transform)
		draw_aabb(aabb, node.transform, c)


func draw_shard_collision(node: BreakableSlab):
	for i in node._shards.size():
		var shard_transform := node.get_shard_transform(i)
		var color = Color(rand.randi())
		color.a = 1
		var shape := PhysicsServer3D.body_get_shape(node._shards[i].body, 0)
		var shape_transform := PhysicsServer3D.body_get_shape_transform(node._shards[i].body, 0)
		var shape_type := PhysicsServer3D.shape_get_type(shape)
		var shape_data = PhysicsServer3D.shape_get_data(shape)
		
		var world_transform = node.transform * shard_transform * shape_transform
		if shape_type == PhysicsServer3D.SHAPE_BOX:
			draw_box(shape_data * 0.5, world_transform, color)
		elif shape_type == PhysicsServer3D.SHAPE_CYLINDER:
			draw_cylinder(shape_data["radius"], shape_data["height"], world_transform, color)
		else:
			# TODO
			pass


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
