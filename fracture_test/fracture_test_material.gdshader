shader_type spatial;

uniform vec3 shard_location[256];

uniform sampler2D Albedo;

void vertex() {
	
}

void fragment() {
	ALBEDO = texture(Albedo, UV).rgb * shard_location[0].x;
}
