shader_type spatial;

render_mode cull_disabled;

uniform float wave_speed = 1.0;
uniform float wave_height = 0.5;
uniform float wave_scale = 1.0;
uniform vec3 bottom_color: source_color = vec3(0.4, 1.0, 0.2);
uniform vec3 top_color: source_color = vec3(0.0, 0.9, 0.2);
uniform float gradient_height = 0.5;

uniform sampler2D alpha_sampler;

void vertex() {

	float time = TIME + NODE_POSITION_WORLD.x + NODE_POSITION_WORLD.z;
	float theta = sin(time * wave_speed) * smoothstep(0.0, wave_height, VERTEX.y) * wave_scale;
	float st = sin(theta);
	float ct = cos(theta);
	mat3 rot = mat3(
		vec3(ct, 0.0, st),
		vec3(0.0, 1.0, 0.0),
		vec3(-st, 0.0, ct));
	COLOR = vec4(mix(bottom_color, top_color, clamp(VERTEX.y * gradient_height, 0.0, 1.0)), 0.0);
	VERTEX = VERTEX * rot;
}

void fragment() {

	ALBEDO = COLOR.rgb;
	if (texture(alpha_sampler, UV).a < 0.5)
		discard;
}
