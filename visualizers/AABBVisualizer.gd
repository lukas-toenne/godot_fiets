class_name ShardVisualizer
extends MeshInstance3D

const BreakableSlab = preload("res://fracture_test/BreakableSlab.gd")

@export var target: NodePath
# How far recursive search goes. -1 = everything
#@export_range(-1, 10) var subchildren_levels: int = -1
@export var subchildren_levels: int = -1

var mesh_impl: ImmediateMesh
var target_node: Node
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
		draw_aabbs(target_node, subchildren_levels)


func draw_aabbs(node: Node, recursive := -1):
	# Draw aabb if there is one
	var has_aabb := false
	if node is BreakableSlab:
		if false:
			for i in node._shards.size():
				var shard_transform := Transform3D(Basis(
					node._param_shard_rotation[3 * i + 0],
					node._param_shard_rotation[3 * i + 1],
					node._param_shard_rotation[3 * i + 2]),
					node._param_shard_location[i])
				var aabb = node.get_shard_aabb(shard_transform)
				var c = Color(rand.randi())
				c.a = 1
				draw_aabb(aabb, c)
		else:
			var c = Color(rand.randi())
			c.a = 1
			draw_aabb(node._custom_aabb, c)
		has_aabb = true
	if !has_aabb and node.has_method("get_transformed_aabb") and node != self:
		var aabb = node.get_transformed_aabb()
		var c = Color(rand.randi())
		c.a = 1
		draw_aabb(aabb, c)
		has_aabb = true

	# Then draw aabbs of children
	if recursive != 0:
		for child in node.get_children():
			draw_aabbs(child, recursive - 1)


func draw_aabb(aabb:AABB, color:Color) -> void:
	mesh_impl.surface_begin(Mesh.PRIMITIVE_LINES)
	mesh_impl.surface_set_color(color)
	mesh_impl.surface_set_normal(Vector3(1, 0, 0))

	# Bottom
	mesh_impl.surface_add_vertex(to_local(aabb.position))
	mesh_impl.surface_add_vertex(to_local(aabb.position + aabb.size * Vector3(1, 0, 0)))

	mesh_impl.surface_add_vertex(to_local(aabb.position + aabb.size * Vector3(1, 0, 0)))
	mesh_impl.surface_add_vertex(to_local(aabb.position + aabb.size * Vector3(1, 0, 1)))

	mesh_impl.surface_add_vertex(to_local(aabb.position + aabb.size * Vector3(1, 0, 1)))
	mesh_impl.surface_add_vertex(to_local(aabb.position + aabb.size * Vector3(0, 0, 1)))

	mesh_impl.surface_add_vertex(to_local(aabb.position + aabb.size * Vector3(0, 0, 1)))
	mesh_impl.surface_add_vertex(to_local(aabb.position))

	# Top
	mesh_impl.surface_add_vertex(to_local(aabb.position + aabb.size * Vector3(0, 1, 0)))
	mesh_impl.surface_add_vertex(to_local(aabb.position + aabb.size * Vector3(1, 1, 0)))

	mesh_impl.surface_add_vertex(to_local(aabb.position + aabb.size * Vector3(1, 1, 0)))
	mesh_impl.surface_add_vertex(to_local(aabb.position + aabb.size * Vector3(1, 1, 1)))

	mesh_impl.surface_add_vertex(to_local(aabb.position + aabb.size * Vector3(1, 1, 1)))
	mesh_impl.surface_add_vertex(to_local(aabb.position + aabb.size * Vector3(0, 1, 1)))

	mesh_impl.surface_add_vertex(to_local(aabb.position + aabb.size * Vector3(0, 1, 1)))
	mesh_impl.surface_add_vertex(to_local(aabb.position + aabb.size * Vector3(0, 1, 0)))

	# Sides
	mesh_impl.surface_add_vertex(to_local(aabb.position))
	mesh_impl.surface_add_vertex(to_local(aabb.position + aabb.size * Vector3(0, 1, 0)))

	mesh_impl.surface_add_vertex(to_local(aabb.position + aabb.size * Vector3(1, 0, 0)))
	mesh_impl.surface_add_vertex(to_local(aabb.position + aabb.size * Vector3(1, 1, 0)))

	mesh_impl.surface_add_vertex(to_local(aabb.position + aabb.size * Vector3(0, 0, 1)))
	mesh_impl.surface_add_vertex(to_local(aabb.position + aabb.size * Vector3(0, 1, 1)))

	mesh_impl.surface_add_vertex(to_local(aabb.position + aabb.size * Vector3(1, 0, 1)))
	mesh_impl.surface_add_vertex(to_local(aabb.position + aabb.size * Vector3(1, 1, 1)))
	mesh_impl.surface_end()
