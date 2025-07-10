class_name FollowCameraActor extends Camera3D

const PHYS_MASK_FLOOR = 64;

@export var look_strength: float = 5.0;
@export var follow_distance: float = 10.0;
@export var follow_strength: float = 10.0;

@export var follow_target: Node3D = null;
@export var follow_offset: Vector3 = Vector3.UP;

var look: Vector2 = Vector2.ZERO;
var look_hnormal: Vector3 = Vector3.ZERO;

var follow_target_position: Vector3:
	get: return follow_target.global_position + follow_offset * follow_target.global_basis.get_rotation_quaternion();

var is_underwater : bool:
	get: return global_position.y < Water.current.height_at_point(global_position) + 4.0;

func process_looking(t_delta: float):
	
	# changed the input to now affect a look vector because we can stop it from
	# going inverted and becoming useless. we also loop the X
	
	look += Vector2(
		Input.get_axis("look_left", "look_right"),
		Input.get_axis("look_down", "look_up")) * look_strength * t_delta;
	look = Vector2(fmod(look.x, PI * 2.0), clamp(look.y, (PI * 0.5) - 0.5, (PI * 0.5) - 0.1));
	look.y = lerp(look.y, (PI * 0.5) - 0.3, t_delta);
	var y = cos(look.y);
	var w = sin(look.y);
	var x = cos(look.x) * w;
	var z = sin(look.x) * w;
	look_hnormal = Vector3(x, y, z).normalized();
	return;

func process_following(t_delta: float):
	
	# nothing to follow
	if !is_instance_valid(follow_target):
		return;
	
	# our target is a simple projected normal, so we lerp towards it to avoid
	# a snappy or jittery camera when the fraerate drops
	var goto_position = follow_target_position + look_hnormal * follow_distance;
	global_position = global_position.lerp(goto_position, t_delta * follow_strength);
	
	global_basis = Basis.looking_at((follow_target_position - global_position).normalized(), Vector3.UP);
	return;

func process_obstruction(_delta: float) -> void:
	
	# nothing to follow
	if !is_instance_valid(follow_target):
		return;
	
	var physics = get_world_3d().direct_space_state;
	var query = PhysicsRayQueryParameters3D.new();
	query.from = follow_target_position;
	var diff = query.from - global_position;
	var dist = diff.length();
	var dir = (diff).normalized();
	query.to = global_position - dir;
	query.collide_with_bodies = true;
	query.collide_with_areas = false;
	query.exclude = [follow_target];
	query.collision_mask = PHYS_MASK_FLOOR;
	var result = physics.intersect_ray(query);
	if result.has("position"):
		global_position = result.position + dir;
	return;

func process_underwater(t_delta: float) -> void:
	
	var filter : AudioEffectLowPassFilter = AudioServer.get_bus_effect(AudioServer.get_bus_index("Master"), 0);
	filter.cutoff_hz = lerp(filter.cutoff_hz, 500.0 if global_position.y < 0.0 else 20500.0, 4.0 * t_delta);
	return;

func _ready() -> void:
	
	current = true;
	return;

func _physics_process(t_delta: float) -> void:
	
	process_looking(t_delta);
	process_following(t_delta);
	process_obstruction(t_delta);
	process_underwater(t_delta);
	return;
