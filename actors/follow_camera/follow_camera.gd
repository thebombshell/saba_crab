class_name FollowCameraActor extends Camera3D

@export var look_strength: float = 10.0;
@export var follow_distance: float = 10.0;
@export var follow_height: float = 2.0;
@export var follow_strength: float = 4.0;
@export var follow_up_strength: float = 4.0;

@export var follow_target: Node3D = null;

var is_underwater : bool:
	get: return global_position.y < Water.current.height_at_point(global_position) + 4.0;

func process_looking(t_delta: float):
	
	var up = get_global_transform_interpolated().basis.y;
	var right = get_global_transform_interpolated().basis.x;
	global_position += up * Input.get_axis("look_down", "look_up") * look_strength * t_delta;
	global_position += right * Input.get_axis("look_left", "look_right") * look_strength * t_delta;
	return;

func process_following(t_delta: float):
	
	# nothing to follow
	if !is_instance_valid(follow_target):
		return;
	
	var target_up =Vector3.UP# Vector3.UP * follow_target.global_basis;
	var difference = follow_target.global_position - global_position;
	var distance = difference.length();
	var direction = difference / distance;
	
	global_position = global_position.lerp(follow_target.global_position - direction * follow_distance, t_delta * follow_strength);
	var height = global_position.dot(target_up);
	var target_height = follow_target.global_position.dot(target_up);
	global_position -= target_up * height;
	height = lerp(height, target_height + follow_height, t_delta * follow_up_strength);
	global_position += target_up * height;
	
	global_basis = Basis.looking_at(direction, Vector3.UP);
	return;

func _physics_process(t_delta: float) -> void:
	
	process_looking(t_delta);
	process_following(t_delta);
	
	return;
