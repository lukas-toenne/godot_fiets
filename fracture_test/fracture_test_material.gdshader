shader_type spatial;

const int MAX_SHARDS = 256;

uniform vec3 shard_location[MAX_SHARDS];
uniform sampler2D albedo;

varying flat vec4 shard_index_f;

void vertex() {
	shard_index_f = CUSTOM0;
}

void fragment() {
	uint shard_index = packUnorm4x8(shard_index_f);
	ALBEDO = texture(albedo, UV).rgb * shard_location[shard_index].x;
//	ALBEDO = texture(albedo, UV).rgb * float(shard_index % 2);
//	ALBEDO = texture(albedo, UV).rgb * (int(shard_index) == 1 ? 1.0 : 0.0);
//	ALBEDO = texture(albedo, UV).rgb;
}
