class_name Water extends MeshInstance3D

const WATER_NOISE_TEXTURE = preload("res://shaders/water/water_noise_texture.png");

static var current : Water = null;

var noise_map : Image = WATER_NOISE_TEXTURE.get_image();
var effect_image : Image = null;
var offset : Vector2 = Vector2.ZERO;
var height_map_scale : float = 4096.0;
var height_map_height : float = 1.0;

func sample_float_at_point(t_map : PackedFloat32Array, t_uv : Vector2) -> float:
	
	var uv = t_uv / height_map_scale + Vector2(0.5, 0.5);
	var size = sqrt(t_map.size());
	var suv = uv * Vector2(size);
	var iuv = Vector2i(floori(suv.x), floori(suv.y));
	var muv = Vector2(suv.x - iuv.x, suv.y - iuv.y);
	
	var tl = t_map[
		clamp(iuv.x + 0, 0, size.x - 1) + clamp(iuv.y + 0, 0, size.y - 1) * size];
	var t_tr = t_map[
		clamp(iuv.x + 1, 0, size.x - 1) + clamp(iuv.y + 0, 0, size.y - 1) * size];
	var bl = t_map[
		clamp(iuv.x + 0, 0, size.x - 1) + clamp(iuv.y + 1, 0, size.y - 1) * size];
	var br = t_map[
		clamp(iuv.x + 1, 0, size.x - 1) + clamp(iuv.y + 1, 0, size.y - 1) * size];
	
	var t = lerp(tl, t_tr, muv.x);
	var b = lerp(bl, br, muv.x);
	
	return lerp(t, b, muv.y);

func sample_image_at_point(t_map : Image, t_uv : Vector2) -> float:
	
	var uv = t_uv / height_map_scale+ Vector2(0.5, 0.5);
	var size = t_map.get_size();
	var suv = uv * Vector2(size);
	var iuv = Vector2i(floori(suv.x), floori(suv.y));
	var muv = Vector2(suv.x - iuv.x, suv.y - iuv.y);
	
	var tl = t_map.get_pixel(
		clamp(iuv.x + 0, 0, size.x - 1), clamp(iuv.y + 0, 0, size.y - 1)).r;
	var t_tr = t_map.get_pixel(
		clamp(iuv.x + 1, 0, size.x - 1), clamp(iuv.y + 0, 0, size.y - 1)).r;
	var bl = t_map.get_pixel(
		clamp(iuv.x + 0, 0, size.x - 1), clamp(iuv.y + 1, 0, size.y - 1)).r;
	var br = t_map.get_pixel(
		clamp(iuv.x + 1, 0, size.x - 1), clamp(iuv.y + 1, 0, size.y - 1)).r;
	
	var t = lerp(tl, t_tr, muv.x);
	var b = lerp(bl, br, muv.x);
	
	return lerp(t, b, muv.y);

func height_at_point(t_position : Vector3):
	
	var uv = Vector2(t_position.x, t_position.z) + offset;
	var wave1 = sample_image_at_point(noise_map, uv * 1.0) * 0.5;
	var wave2 = sample_image_at_point(noise_map, uv * 10.0) * 0.33;
	var wave3 = sample_image_at_point(noise_map, uv * 100.0) * 0.17;
	return (wave1 + wave2 + wave3) * height_map_height;

func _ready():
	
	current = self;
	var mat : ShaderMaterial = mesh.surface_get_material(0);
	mat.set_shader_parameter("water_map_scale", height_map_scale);
	mat.set_shader_parameter("water_map_height", height_map_height);
	return;

func _process(t_delta: float) -> void:
	
	offset += Vector2.ONE * 0.04 * t_delta;
	offset.x = fmod(offset.x, 256.0);
	offset.y = fmod(offset.y, 256.0);
	var mat : ShaderMaterial = mesh.surface_get_material(0);
	mat.set_shader_parameter("offset", offset);
	return;
