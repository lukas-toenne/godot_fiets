shader_type spatial;

uniform sampler2D albedo;

void fragment() {
//	uint shard_index = packUnorm4x8(shard_index_f);
//	ALBEDO = texture(albedo, UV).rgb * shard_location[shard_index].x;
//	ALBEDO = texture(albedo, UV).rgb * float(shard_index % 2);
//	ALBEDO = texture(albedo, UV).rgb * (int(shard_index) == 1 ? 1.0 : 0.0);
//	ALBEDO = shard_index_f.xyz;
	ALBEDO = texture(albedo, UV).rgb;
}
