shader_type spatial;

uniform float bob_amount = 0.5;

uniform vec3 diffuse_colour : source_color = vec3(1.0, 1.0, 1.0);
uniform float metalness = 0.5;
uniform float roughness = 0.5;
uniform float emission = 0.2;

uniform vec3 perlescence_colour : source_color = vec3(1.0, 1.0, 1.0);
uniform float perlescence_frequency = 1.0;

vec3 irridescence(vec3 t_view, vec3 t_normal, vec3 t_light) {

	float vn = dot(t_view, t_normal);
	float ln = dot(t_light, t_normal);
	float angle = abs(vn - ln);
	float interference = sin(angle * perlescence_frequency) * 0.5 + 0.5;
	return mix(diffuse_colour, perlescence_colour, interference);
}

void vertex() {

	float theta = TIME + (COLOR.x + COLOR.y + COLOR.z);
	float st = sin(theta);
	float ct = cos(theta);
	mat3 rot = mat3(
		vec3(ct, 0.0, st),
		vec3(0.0, 1.0, 0.0),
		vec3(-st, 0.0, ct));
	VERTEX = VERTEX * rot + vec3(0.0, st * bob_amount, 0.0);
	NORMAL = NORMAL * rot;
}

void fragment() {

	ALBEDO = irridescence(VIEW, NORMAL, normalize(vec3(0.2, -1.0, -0.4)));
	METALLIC = metalness;
	ROUGHNESS = roughness;
	EMISSION = vec3(emission, emission, emission);
}