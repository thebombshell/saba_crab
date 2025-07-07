class_name FoldablePanel extends Panel

# this is a foldable panel, just a nice smooth transition made into a base class

@onready var fold_button: TextureButton = $FoldButton
@export var fold_size_minimum: float = 20.0;
@export var fold_size_maximum: float = 350.0;
@export var fold_size_scaling: float = 1.0;

var should_be_folded :bool :
	get: return fold_button.button_pressed;
	set(t_value): fold_button.button_pressed = t_value; return;

func _physics_process(t_delta :float) -> void:
	
	var parent = get_parent_control();
	var parent_height = parent.size.y if is_instance_valid(parent) else fold_size_maximum;
	var height = clamp(size.y + t_delta * 5000.0 * (-1.0 if should_be_folded else 1.0),
		fold_size_minimum, lerp(fold_size_maximum, parent_height, fold_size_scaling));
	size = Vector2(size.x, height);
	return;
