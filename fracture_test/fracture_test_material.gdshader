shader_type spatial;

const int MAX_SHARDS = 256;

uniform vec3 shard_location[MAX_SHARDS];
uniform sampler2D albedo;

varying flat float shard_index_f;

void vertex() {
	shard_index_f = CUSTOM0.x;
}

void fragment() {
	int shard_index = int(shard_index_f);
//	ALBEDO = texture(albedo, UV).rgb * shard_location[shard_index].x;
	ALBEDO = texture(albedo, UV).rgb * float(shard_index % 2);
}
