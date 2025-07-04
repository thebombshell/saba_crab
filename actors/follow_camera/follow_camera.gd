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
	
	# input is simply moving the camera based on its up and right vectors,
	# due to the following behaviour correcting for up and down though, we'll
	# not get much use out of up, though we can certainly give this a play later
	# if it becomes relevant to gameplay
	
	var up = get_global_transform_interpolated().basis.y;
	var right = get_global_transform_interpolated().basis.x;
	global_position += up * Input.get_axis("look_down", "look_up") * look_strength * t_delta;
	global_position += right * Input.get_axis("look_left", "look_right") * look_strength * t_delta;
	return;

func process_following(t_delta: float):
	
	# nothing to follow
	if !is_instance_valid(follow_target):
		return;
	
	var target_up = Vector3.UP;
	var difference = follow_target.global_position - global_position;
	var distance = difference.length();
	var direction = difference / distance;
	
	# smoothly moves the camera to an ideal distance from the following target
	var target_position = follow_target.global_position - direction * follow_distance;
	global_position = global_position.lerp(target_position, t_delta * follow_strength);
	
	# smoothly moves the camera to an ideal height from the following target,
	# this is important for both stopping the camera from staring down from
	# useless angles, and for keeping track of our movements vertically which
	# are much less forgiving of a smooth camera than simply being a speedy
	# crab
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
