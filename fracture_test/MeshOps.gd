static func triangulate_polygon(loop: PackedVector2Array, vertices: PackedVector3Array, indices: PackedInt32Array):
	# TODO
	pass


# Extrude boundary edges along the Z axis, forming a prism.
# boundary must contain pairs of indices describing boundary edges.
static func extrude_polygon(arrays: Array, boundary: PackedInt32Array, depth: float):
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	# Cache these before changing array sizes
	var numverts := vertices.size()
	var numbound := boundary.size()
	# Duplicate vertices and offset.
	# Boundary faces get own copies of vertices so we can define sharp normals.
	vertices.resize(2 * numverts + 2 * numbound)
	# Mirror the polygon.
	for i in numverts:
		var v := vertices[i]
		vertices[i] = v + Vector3(0, 0, 0.5 * depth)
		vertices[i + numverts] = v + Vector3(0, 0, -0.5 * depth)
	# Add vertices for boundary triangles.
	var vboundstart = 2 * numverts
	for i in numbound >> 1:
		var idx0 = 2 * i + 0
		var idx1 = 2 * i + 1
		var v1 = vertices[boundary[idx0]]
		var v2 = vertices[boundary[idx1]]
		var v1m = vertices[boundary[idx0] + numverts]
		var v2m = vertices[boundary[idx1] + numverts]
		vertices[idx0 + vboundstart] = v1
		vertices[idx1 + vboundstart] = v2
		vertices[idx0 + vboundstart + numbound] = v1m
		vertices[idx1 + vboundstart + numbound] = v2m

	arrays[Mesh.ARRAY_VERTEX] = vertices

	if arrays[Mesh.ARRAY_NORMAL]:
		var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
		normals.resize(2 * numverts + 2 * numbound)

		for i in numverts:
			var n := normals[i]
	#		normals[i] = n
			normals[i + numverts] = Vector3(n.x, n.y, -n.z)
		for i in numbound >> 1:
			var idx0 = 2 * i + 0
			var idx1 = 2 * i + 1
			var v1 := vertices[boundary[idx0]]
			var v2 := vertices[boundary[idx1]]
			var boundnor := (v2 - v1).cross(Vector3(0, 0, -1)).normalized()
			normals[idx0 + vboundstart] = boundnor
			normals[idx1 + vboundstart] = boundnor
			normals[idx0 + vboundstart + numbound] = boundnor
			normals[idx1 + vboundstart + numbound] = boundnor

		arrays[Mesh.ARRAY_NORMAL] = normals

	if arrays[Mesh.ARRAY_TANGENT]:
		var tangents: PackedFloat32Array = arrays[Mesh.ARRAY_TANGENT]
		tangents.resize(8 * numverts + 8 * numbound)

		for i in numverts:
			var t := tangents[i]
	#		tangents[i] = t
			tangents[4 * (i + numverts) + 0] = tangents[4 * i + 0]
			tangents[4 * (i + numverts) + 1] = tangents[4 * i + 1]
			tangents[4 * (i + numverts) + 2] = tangents[4 * i + 2]
			tangents[4 * (i + numverts) + 3] = tangents[4 * i + 3]
		for i in numbound >> 1:
			var idx0 = 2 * i + 0
			var idx1 = 2 * i + 1
			var v1 := vertices[boundary[idx0]]
			var v2 := vertices[boundary[idx1]]
			var boundtan := (v2 - v1).normalized()
			tangents[4 * (idx0 + vboundstart) + 0] = boundtan.x
			tangents[4 * (idx0 + vboundstart) + 1] = boundtan.y
			tangents[4 * (idx0 + vboundstart) + 2] = boundtan.z
			tangents[4 * (idx0 + vboundstart) + 3] = 1.0
			tangents[4 * (idx1 + vboundstart) + 0] = boundtan.x
			tangents[4 * (idx1 + vboundstart) + 1] = boundtan.y
			tangents[4 * (idx1 + vboundstart) + 2] = boundtan.z
			tangents[4 * (idx1 + vboundstart) + 3] = 1.0
			tangents[4 * (idx0 + vboundstart + numbound) + 0] = boundtan.x
			tangents[4 * (idx0 + vboundstart + numbound) + 1] = boundtan.y
			tangents[4 * (idx0 + vboundstart + numbound) + 2] = boundtan.z
			tangents[4 * (idx0 + vboundstart + numbound) + 3] = 1.0
			tangents[4 * (idx1 + vboundstart + numbound) + 0] = boundtan.x
			tangents[4 * (idx1 + vboundstart + numbound) + 1] = boundtan.y
			tangents[4 * (idx1 + vboundstart + numbound) + 2] = boundtan.z
			tangents[4 * (idx1 + vboundstart + numbound) + 3] = 1.0

		arrays[Mesh.ARRAY_TANGENT] = tangents

	if arrays[Mesh.ARRAY_TEX_UV]:
		var tex_uv: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
		tex_uv.resize(2 * numverts + 2 * numbound)

		for i in numverts:
			tex_uv[i + numverts] = tex_uv[i]
		# Add vertices for boundary triangles.
		for i in numbound >> 1:
			var idx0 = 2 * i + 0
			var idx1 = 2 * i + 1
			# TODO boundary UV mapping
			tex_uv[idx0 + vboundstart] = tex_uv[boundary[idx0]]
			tex_uv[idx1 + vboundstart] = tex_uv[boundary[idx1]]
			tex_uv[idx0 + vboundstart + numbound] = tex_uv[boundary[idx0]]
			tex_uv[idx1 + vboundstart + numbound] = tex_uv[boundary[idx1]]

		arrays[Mesh.ARRAY_TEX_UV] = tex_uv

	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	var numidx := indices.size()

	# Every pair of indices of boundary describe a quad, i.e. 6 new indices, or 6/2=3 for each boundary index.
	indices.resize(2 * numidx + 3 * numbound)
	for i in numidx / 3:
		# Change winding order for mirrored triangles
		indices[3 * i + 1 + numidx] = indices[3 * i + 0] + numverts
		indices[3 * i + 0 + numidx] = indices[3 * i + 1] + numverts
		indices[3 * i + 2 + numidx] = indices[3 * i + 2] + numverts
	var iboundstart = 2 * numidx
	for i in numbound >> 1:
		indices[6 * i + 0 + iboundstart] = 2 * i + 0 + vboundstart
		indices[6 * i + 1 + iboundstart] = 2 * i + 0 + vboundstart + numbound
		indices[6 * i + 2 + iboundstart] = 2 * i + 1 + vboundstart + numbound
		indices[6 * i + 3 + iboundstart] = 2 * i + 1 + vboundstart + numbound
		indices[6 * i + 4 + iboundstart] = 2 * i + 1 + vboundstart
		indices[6 * i + 5 + iboundstart] = 2 * i + 0 + vboundstart

	arrays[Mesh.ARRAY_INDEX] = indices

static func find_boundary(indices: PackedInt32Array) -> PackedInt32Array:
	var edge_tri_count := Dictionary()
	for i in indices.size() / 3:
		var v0 = indices[3 * i + 0]
		var v1 = indices[3 * i + 1]
		var v2 = indices[3 * i + 2]
		var idx0: int = (min(v0, v1) << 8) + max(v0, v1)
		var idx1: int = (min(v1, v2) << 8) + max(v1, v2)
		var idx2: int = (min(v2, v0) << 8) + max(v2, v0)
		if edge_tri_count.has(idx0):
			edge_tri_count[idx0][2] += 1
		else:
			edge_tri_count[idx0] = [v0, v1, 1]
		if edge_tri_count.has(idx1):
			edge_tri_count[idx1][2] += 1
		else:
			edge_tri_count[idx1] = [v1, v2, 1]
		if edge_tri_count.has(idx2):
			edge_tri_count[idx2][2] += 1
		else:
			edge_tri_count[idx2] = [v2, v0, 1]

	var boundary := PackedInt32Array()
	for edge in edge_tri_count.values():
		if edge[2] == 1:
			boundary.push_back(edge[0])
			boundary.push_back(edge[1])
	
	return boundary

static func _connect_islands(islands: PackedInt32Array, a: int, b: int):
	var next_a = islands[a]
	var next_b = islands[b]
	if next_a < 0:
		islands[a] = b
	elif next_b >= 0:
		islands[a] = next_b
	if next_b < 0:
		islands[b] = a
	elif next_a >= 0:
		islands[b] = next_a

static func _flush_island(islands: PackedInt32Array, start: int):
	var current := start
	while current != start:
		var next = islands[current]
		islands[current] = start
		current = next

# islands array must be the size of the vertex buffer
static func find_islands(indices: PackedInt32Array, islands: PackedInt32Array):
	if indices.is_empty():
		islands.resize(0)
		return

	islands.fill(-1)

	# First construct singly-linked lists of connnected vertices
	# by storing the index of a connected vertex in islands.
	# Each edge either adds an uninitialized vertex to an existing list,
	# or connects two lists by "crossing over", i.e. connect a to island[b] and b to island[a].
	# All resulting lists are closed loops.
	for i in indices.size() / 3:
		var v0 = indices[3 * i + 0]
		var v1 = indices[3 * i + 1]
		var v2 = indices[3 * i + 2]
		_connect_islands(islands, v0, v1)
		_connect_islands(islands, v1, v2)
		_connect_islands(islands, v2, v0)

	# Now assign the same index to all connected vertices.
	# The lowest vertex index is used as island index.
	for i in islands.size():
		# Any time we find a target higher than the index we know it's an new island.
		if islands[i] > i:
			_flush_island(islands, i)
