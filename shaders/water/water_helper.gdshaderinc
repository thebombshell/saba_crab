
uniform vec3 shallow_color : source_color;
uniform vec3 deep_color : source_color;
uniform float shallow_depth = 200.0;
uniform float deep_depth = 500.0;
uniform float water_map_scale = 16.0;
uniform float water_map_height = 2.0;
uniform sampler2D effect_map;
uniform sampler2D noise_map;
uniform vec2 offset;

float sample_water(vec2 t_uv)
{
	vec2 uv = t_uv / water_map_scale;
	float noise = texture(noise_map, uv + offset + vec2(0.5, 0.5)).r * 0.33 +
		texture(noise_map, uv * 10.0 + offset + vec2(0.5, 0.5)).r * 0.33 +
		texture(noise_map, uv * 100.0 + offset + vec2(0.5, 0.5)).r * 0.33;
	float effect = 0.0;
	return noise * water_map_height + effect;
}

vec3 sample_normal(vec2 t_uv, float t_offset)
{
	float x = sample_water(t_uv + vec2(t_offset, 0.0)) - sample_water(t_uv - vec2(t_offset, 0.0));
	float y = 1.0;
	float z = sample_water(t_uv + vec2(0.0, t_offset)) - sample_water(t_uv - vec2(0.0, t_offset));
	return normalize(vec3(x, y, z));
}

vec3 find_normal(vec2 t_uv)
{
	return normalize(sample_normal(t_uv, 1.0));
}

vec3 find_depth_world_position(vec2 t_screen_uv, sampler2D t_sampler, mat4 t_inverse_view_matrix, mat4 t_inverse_proj_matrix) {
	
	vec3 ndc = vec3(t_screen_uv, texture(t_sampler, t_screen_uv).x) * 2.0 - 1.0;
	vec4 view = t_inverse_proj_matrix * vec4(ndc, 1.0);
	view.xyz /= view.w;
	float linear_depth = -view.z;
	vec4 world = t_inverse_view_matrix * t_inverse_proj_matrix * vec4(ndc, 1.0);
	return world.xyz / world.w;
}

vec3 find_camera_pixel_direction(vec2 t_screen_uv, vec3 t_camera_direction, vec3 t_camera_up, float t_fov) {
	
	vec3 x = normalize(cross(t_camera_direction, t_camera_up));
	vec3 y = normalize(cross(t_camera_direction, x));
	vec3 z = normalize(t_camera_direction);
	return normalize(x * t_fov * t_screen_uv.x + y * t_fov * t_screen_uv.y + z);
}

vec3 find_camera_pixel_position(vec3 t_camera_position, vec3 t_pixel_direction) {
	
	return t_camera_position + t_pixel_direction * 0.05;
}

vec3 march_to_water(vec3 ray_position, vec3 ray_direction, out float t_is_surface_hit) {
	
	float ray_sign = sign(ray_position.y);
	t_is_surface_hit = step(ray_sign * ray_direction.y, 0.0);
	
	vec3 ray = ray_position;
	float dist = 0.0;
	float water_height = sample_water(ray.xz);
	float travel = distance(ray_position.y, water_map_height) / abs(ray_direction.y);
	ray += ray_direction * travel;
	
	for (int i = 0; i < 64; i++) {
		
		ray = ray_position + ray_direction * dist;
		water_height = sample_water(ray.xz);
		travel = abs(ray.y - water_height);
		if (dist >= 8192.0 || travel < 0.01 || (ray.y - water_height) * ray_sign < 0.0) {
			t_is_surface_hit = 1.0;
			return ray;
		}
		dist += travel;
	}
	return ray;
}