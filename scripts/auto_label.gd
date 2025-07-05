@tool
class_name AutoLabel extends Label

@export var min_scale_size = 100.0;
@export var max_scale_size = 200.0;
@export var min_font_size: int = 50;
@export var max_font_size: int = 200;

func _on_resized() -> void:
	
	var min_size = min(size.x, size.y);
	var alpha = clamp(smoothstep(min_scale_size, max_scale_size, min_size), 0.0, 1.0);
	add_theme_font_size_override("font_size", lerp(min_font_size, max_font_size, alpha));
	return;
