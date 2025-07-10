shader_type spatial;

render_mode unshaded, blend_mix, depth_draw_never, depth_test_disabled;

#include "water_helper.gdshaderinc"

const float CAMERA_FOV = PI * .5;
const vec3 CAMERA_UP_WORLD = vec3(0.0, 1.0, 0.0);

uniform sampler2D depth_texture : hint_depth_texture;

varying vec3 v_world_position;


void vertex() {
	POSITION = vec4(VERTEX.xy, 1.0, 1.0);
}

void fragment() {

	vec3 world_position = find_depth_world_position(SCREEN_UV, depth_texture, INV_VIEW_MATRIX, INV_PROJECTION_MATRIX);
	vec3 pixel_direction = normalize(world_position - CAMERA_POSITION_WORLD);
	vec3 pixel_position = find_camera_pixel_position(CAMERA_POSITION_WORLD, pixel_direction);
	float pixel_water_height = sample_water(pixel_position.xz);
	float is_surface_hit = 0.0;
	vec3 surface_position = march_to_water(pixel_position, pixel_direction, is_surface_hit);
	float is_pixel_below_water = step(pixel_position.y, pixel_water_height);
	float surface_water_height = sample_water(surface_position.xz);

	float ground_depth = (distance(surface_position.xyz, world_position));
	float distance_to_ground = (distance(pixel_position, world_position));
	float distance_to_water_surface = distance(pixel_position, surface_position.xyz);
	float surface_line =
		step(world_position.y, surface_position.y) *
		smoothstep(surface_position.y - 1.0, surface_position.y, world_position.y) *
		smoothstep(50.0, 0.0, distance_to_water_surface);
	vec3 normal = find_normal(surface_position.xz);

	vec3 R = normalize(reflect(vec3(0.0, 1.0, 0.0), normal));
	vec3 V = normalize(pixel_direction);
	float fresnel = max(dot(normal, V) + 1.0, 0.0);
	float lamb = max(dot(normal, vec3(0.0, 1.0, 0.0)), 0.0);
	float L = smoothstep(0.0, 0.8, surface_water_height / water_map_height);
	float spec = clamp(min(pow(fresnel, 80.0), 1.0) * 0.67 + min(pow(L, 4.0), 1.0) * 0.33, 0.0, 1.0);

	float nearest_surface = min(distance_to_water_surface, distance_to_ground);
	float can_see_surface = step(distance_to_water_surface, distance_to_ground);
	float final_surface_line = surface_line * can_see_surface;
	vec3 depth_color = mix(shallow_color, deep_color, smoothstep(0.0, deep_depth, distance_to_ground));
	vec3 surface_color = lamb * depth_color + spec + clamp(pow(final_surface_line, 2.0), 0.0, 1.0);
	float depth_alpha = clamp(distance_to_ground / deep_depth, shallow_alpha, deep_depth);
	float surface_alpha = clamp((depth_alpha + spec) * is_surface_hit * can_see_surface + final_surface_line, 0.0, 1.0);
	ALBEDO = clamp(mix(surface_color, depth_color, is_pixel_below_water), 0.0, 1.0);
	ALPHA = clamp(mix(surface_alpha, depth_alpha, is_pixel_below_water), 0.0, 1.0);
}