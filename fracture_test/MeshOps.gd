static func triangulate_polygon(loop: PackedVector2Array, vertices: PackedVector3Array, indices: PackedInt32Array):
	# TODO
	pass


static func _extrude_tangents(tangents: PackedFloat32Array, vertices: PackedVector3Array, boundary: PackedInt32Array, numverts: int, numbound: int):
	tangents.resize(8 * numverts + 8 * numbound)

	for i in numverts:
		tangents[4 * (i + numverts) + 0] = tangents[4 * i + 0]
		tangents[4 * (i + numverts) + 1] = tangents[4 * i + 1]
		tangents[4 * (i + numverts) + 2] = tangents[4 * i + 2]
		tangents[4 * (i + numverts) + 3] = tangents[4 * i + 3]

	var boundstart = 2 * numverts
	for i in numbound >> 1:
		var idx0 = 2 * i + 0
		var idx1 = 2 * i + 1
		var v1 := vertices[boundary[idx0]]
		var v2 := vertices[boundary[idx1]]
		var boundtan := (v2 - v1).normalized()
		tangents[4 * (idx0 + boundstart) + 0] = boundtan.x
		tangents[4 * (idx0 + boundstart) + 1] = boundtan.y
		tangents[4 * (idx0 + boundstart) + 2] = boundtan.z
		tangents[4 * (idx0 + boundstart) + 3] = 1.0
		tangents[4 * (idx1 + boundstart) + 0] = boundtan.x
		tangents[4 * (idx1 + boundstart) + 1] = boundtan.y
		tangents[4 * (idx1 + boundstart) + 2] = boundtan.z
		tangents[4 * (idx1 + boundstart) + 3] = 1.0
		tangents[4 * (idx0 + boundstart + numbound) + 0] = boundtan.x
		tangents[4 * (idx0 + boundstart + numbound) + 1] = boundtan.y
		tangents[4 * (idx0 + boundstart + numbound) + 2] = boundtan.z
		tangents[4 * (idx0 + boundstart + numbound) + 3] = 1.0
		tangents[4 * (idx1 + boundstart + numbound) + 0] = boundtan.x
		tangents[4 * (idx1 + boundstart + numbound) + 1] = boundtan.y
		tangents[4 * (idx1 + boundstart + numbound) + 2] = boundtan.z
		tangents[4 * (idx1 + boundstart + numbound) + 3] = 1.0



static func _extrude_tex_uv(tex_uv: PackedVector2Array, boundary: PackedInt32Array, numverts: int, numbound: int):
	tex_uv.resize(2 * numverts + 2 * numbound)

	for i in numverts:
		tex_uv[i + numverts] = tex_uv[i]

	var boundstart = 2 * numverts
	for i in numbound >> 1:
		var idx0 = 2 * i + 0
		var idx1 = 2 * i + 1
		# TODO boundary UV mapping
		tex_uv[idx0 + boundstart] = tex_uv[boundary[idx0]]
		tex_uv[idx1 + boundstart] = tex_uv[boundary[idx1]]
		tex_uv[idx0 + boundstart + numbound] = tex_uv[boundary[idx0]]
		tex_uv[idx1 + boundstart + numbound] = tex_uv[boundary[idx1]]


static func _extrude_custom(attr, boundary: PackedInt32Array, numverts: int, numbound: int):
	attr.resize(8 * numverts + 8 * numbound)

	for i in numverts:
		attr[4 * (i + numverts) + 0] = attr[4 * i + 0]
		attr[4 * (i + numverts) + 1] = attr[4 * i + 1]
		attr[4 * (i + numverts) + 2] = attr[4 * i + 2]
		attr[4 * (i + numverts) + 3] = attr[4 * i + 3]

	var boundstart = 2 * numverts
	for i in numbound >> 1:
		var idx0 = 2 * i + 0
		var idx1 = 2 * i + 1
		attr[4 * (idx0 + boundstart) + 0] = attr[4 * boundary[idx0] + 0]
		attr[4 * (idx0 + boundstart) + 1] = attr[4 * boundary[idx0] + 1]
		attr[4 * (idx0 + boundstart) + 2] = attr[4 * boundary[idx0] + 2]
		attr[4 * (idx0 + boundstart) + 3] = attr[4 * boundary[idx0] + 3]
		attr[4 * (idx1 + boundstart) + 0] = attr[4 * boundary[idx1] + 0]
		attr[4 * (idx1 + boundstart) + 1] = attr[4 * boundary[idx1] + 1]
		attr[4 * (idx1 + boundstart) + 2] = attr[4 * boundary[idx1] + 2]
		attr[4 * (idx1 + boundstart) + 3] = attr[4 * boundary[idx1] + 3]
		attr[4 * (idx0 + boundstart + numbound) + 0] = attr[4 * boundary[idx0] + 0]
		attr[4 * (idx0 + boundstart + numbound) + 1] = attr[4 * boundary[idx0] + 1]
		attr[4 * (idx0 + boundstart + numbound) + 2] = attr[4 * boundary[idx0] + 2]
		attr[4 * (idx0 + boundstart + numbound) + 3] = attr[4 * boundary[idx0] + 3]
		attr[4 * (idx1 + boundstart + numbound) + 0] = attr[4 * boundary[idx1] + 0]
		attr[4 * (idx1 + boundstart + numbound) + 1] = attr[4 * boundary[idx1] + 1]
		attr[4 * (idx1 + boundstart + numbound) + 2] = attr[4 * boundary[idx1] + 2]
		attr[4 * (idx1 + boundstart + numbound) + 3] = attr[4 * boundary[idx1] + 3]


# Extrude boundary edges along the Z axis, forming a prism.
# boundary must contain pairs of indices describing boundary edges.
static func extrude_mesh(arrays: Array, boundary: PackedInt32Array, depth: float):
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
		_extrude_tangents(arrays[Mesh.ARRAY_TANGENT], vertices, boundary, numverts, numbound)

	if arrays[Mesh.ARRAY_TEX_UV]:
		_extrude_tex_uv(arrays[Mesh.ARRAY_TEX_UV], boundary, numverts, numbound)

	if arrays[Mesh.ARRAY_TEX_UV2]:
		_extrude_tex_uv(arrays[Mesh.ARRAY_TEX_UV2], boundary, numverts, numbound)

	if arrays[Mesh.ARRAY_CUSTOM0]:
		_extrude_custom(arrays[Mesh.ARRAY_CUSTOM0], boundary, numverts, numbound)
	if arrays[Mesh.ARRAY_CUSTOM1]:
		_extrude_custom(arrays[Mesh.ARRAY_CUSTOM1], boundary, numverts, numbound)
	if arrays[Mesh.ARRAY_CUSTOM2]:
		_extrude_custom(arrays[Mesh.ARRAY_CUSTOM2], boundary, numverts, numbound)
	if arrays[Mesh.ARRAY_CUSTOM3]:
		_extrude_custom(arrays[Mesh.ARRAY_CUSTOM3], boundary, numverts, numbound)

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


# Disjoint set data structure with path compression and union by rank.
class DisjointSet:
	var _parents: Array
	var _ranks: Array

	func _init(size: int):
		_parents.resize(size)
		for i in size:
			_parents[i] = i
		_ranks.resize(size)
		_ranks.fill(0)

	# Join the sets containing elements x and y. Nothing happens when they have been in the same set before.
	func join(x: int, y: int):
		var root_x := find_root(x)
		var root_y := find_root(y)

		# x and y are in the same set already.
		if root_x == root_y:
			return

		# Implement union by rank heuristic.
		if _ranks[root_x] < _ranks[root_y]:
			_parents[root_x] = root_y
			if _ranks[root_x] == _ranks[root_y]:
				_ranks[root_y] += 1
		else:
			_parents[root_y] = root_x
			if _ranks[root_x] == _ranks[root_y]:
				_ranks[root_x] += 1

	func is_same_set(x: int, y: int) -> bool:
		var root_x := find_root(x)
		var root_y := find_root(y)
		return root_x == root_y

	func find_root(x: int) -> int:
		var root := x
		while _parents[root] != root:
			root = _parents[root]

		# Compress
		while _parents[x] != root:
			var parent = _parents[x]
			_parents[x] = root
			x = parent
			
		return root


# islands array must be the size of the vertex buffer
static func find_islands(indices: PackedInt32Array, islands: PackedInt32Array):
	var island_set = DisjointSet.new(islands.size())
	for i in indices.size() / 3:
		var v0 = indices[3 * i + 0]
		var v1 = indices[3 * i + 1]
		var v2 = indices[3 * i + 2]
		island_set.join(v0, v1)
		island_set.join(v1, v2)
		island_set.join(v2, v0)
	
	var index = 0
	var root_index = Dictionary()
	for i in islands.size():
		var root = island_set.find_root(i)
		if root_index.has(root):
			islands[i] = root_index[root]
		else:
			root_index[root] = index
			islands[i] = index
			index += 1
