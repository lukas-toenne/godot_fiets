shader_type spatial;
render_mode unshaded, shadows_disabled;

const int MAX_SHARDS = 256;
// 3 columns forming a rotation matrix
const int MAX_SHARDS_MATRIX = 768;

uniform vec3 shard_location[MAX_SHARDS];
uniform vec3 shard_rotation[MAX_SHARDS_MATRIX];
uniform sampler2D albedo;

varying flat vec4 shard_index_f;

void vertex() {
	shard_index_f = CUSTOM0;

	uint shard_index = packUnorm4x8(shard_index_f);
	vec3 loc = shard_location[shard_index];
	vec3 rot_x = shard_rotation[3u * shard_index + 0u];
	vec3 rot_y = shard_rotation[3u * shard_index + 1u];
	vec3 rot_z = shard_rotation[3u * shard_index + 2u];
	mat4 shard_transform;
	shard_transform[0] = vec4(rot_x, 0);
	shard_transform[1] = vec4(rot_y, 0);
	shard_transform[2] = vec4(rot_z, 0);
	shard_transform[3] = vec4(loc, 1);
	// Note: In general one needs to use the transposed inverse matrix for transforming normals etc.,
	// but we are only using translation and rotation here so the matrix is the same.
	
	VERTEX = (shard_transform * vec4(VERTEX, 1)).xyz;
	NORMAL = (shard_transform * vec4(NORMAL, 0)).xyz;
	TANGENT = (shard_transform * vec4(TANGENT, 0)).xyz;
	BINORMAL = (shard_transform * vec4(BINORMAL, 0)).xyz;
}

void fragment() {
	uint shard_index = packUnorm4x8(shard_index_f);
//	ALBEDO = texture(albedo, UV).rgb * shard_location[shard_index].x;
//	ALBEDO = texture(albedo, UV).rgb * float(shard_index % 2);
//	ALBEDO = texture(albedo, UV).rgb * (int(shard_index) == 1 ? 1.0 : 0.0);
	ALBEDO = shard_index_f.xyz;
}
