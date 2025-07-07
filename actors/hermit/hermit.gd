class_name HermitActor extends CharacterBody3D

const PHYS_LAYER_NORMAL = 1;
const PHYS_LAYER_PLAYER = 2;
const PHYS_LAYER_GRABBABLE = 4;
const PHYS_LAYER_HARMFUL = 8;
const PHYS_LAYER_ENEMIES = 16;
const PHYS_LAYER_FLOOR = 64;

const ANIM_PARAMS_IS_ON_GROUND = "parameters/BlendTree/StateMachine/conditions/is_on_ground";
const ANIM_PARAMS_IS_RAVE_PRESSED = "parameters/BlendTree/StateMachine/conditions/is_rave_pressed";
const ANIM_PARAMS_IS_HIDE_PRESSED = "parameters/BlendTree/StateMachine/conditions/is_hide_pressed";
const ANIM_PARAMS_JUMP_AND_FALL = "parameters/BlendTree/StateMachine/JumpAndFall/blend_position";
const ANIM_PARAMS_WALKING_BLEND = "parameters/BlendTree/StateMachine/Walking/blend_position";
const ANIM_PARAMS_TIME_SCALE = "parameters/BlendTree/TimeScale/scale";
const ANIM_PARAMS_IS_SWINGING = "parameters/BlendTree/HandMachine/conditions/is_swinging";
const ANIM_PARAMS_ARM_BLEND = "parameters/BlendTree/Add2/add_amount";

# audio assets

const SFX_DIVE = preload("res://audio_fx/dives/dives - dive 1.wav");

# misc nodes

@onready var animation_tree: AnimationTree = $AnimationTree;
@onready var animation_player: AnimationPlayer = $hermit/AnimationPlayer;
@onready var skeleton_3d: Skeleton3D = $hermit/CrabSkeleton/Skeleton3D;
@onready var hermit: Node3D = $hermit;

# audio nodes

@onready var pops_player: AudioStreamPlayer3D = $PopsPlayer;
@onready var swings_player: AudioStreamPlayer3D = $SwingsPlayer;


# configurables

@export var acceleration: float = 5.0;
@export var decceleration: float = 20.0;
@export var air_control: float = 0.5;
@export var drag: float = 0.005;

@export var detection_area: Area3D = null;
@export var hostility_area: Area3D = null;
@export var roaming_distance: float = 5.0;

# movement trackers
var move_input: Vector3 = Vector3.ZERO;
var was_on_floor: bool = false;

# blend trackers
var walking_blend: Vector2 = Vector2.ZERO;
var arm_blend: float = 1.0;
var smoothed_up: Vector3 = Vector3.UP + Vector3.ONE * 0.001;

# animation trackers
var is_raving = false;
var is_hiding = false;

# roaming trackers
var origin: Vector3 = Vector3.ZERO;
var roaming_timer: float = 5.0;
var roaming_target: Vector3 = Vector3.ZERO;

func _ready() -> void:
	
	origin = global_position;
	return;

func init_roaming():
	
	roaming_timer = 3.0 + randf() * 5.0;
	var angle = randf() * PI * 2.0;
	var dir = Vector3(cos(angle), 0.0, sin(angle));
	var dist = randf() * roaming_distance;
	roaming_target = origin + dir * dist;
	var query = PhysicsRayQueryParameters3D.new();
	query.from = global_position + Vector3.UP;
	query.to = origin + dir * (dist + 2.0) + Vector3.UP;
	query.collide_with_areas = false;
	query.collide_with_bodies = true;
	query.collision_mask = PHYS_LAYER_FLOOR;
	var result = get_world_3d().direct_space_state.intersect_ray(query);
	if result.has("point"):
		roaming_target = result.point - dir * 2.0;
	return;

func find_input(t_delta) -> Vector3:
	
	var diff_to_origin = (origin - global_position);
	diff_to_origin.y = 0.0;
	var dist_to_origin = diff_to_origin.length();
	
	roaming_timer -= t_delta;
	if roaming_timer < 0.0:
		init_roaming();
	
	if dist_to_origin > roaming_distance:
		roaming_timer = 3.0;
		roaming_target = origin;
	
	var diff_to_roaming = roaming_target - global_position;
	diff_to_roaming.y = 0.0;
	var dist_to_roaming = diff_to_roaming.length();
	var dir_to_roaming = diff_to_roaming.normalized();
	
	if dist_to_roaming > 1.0:
		return dir_to_roaming;
	return Vector3.ZERO;

func set_raving() -> void:
	
	is_raving = true;
	is_hiding = false;
	return;

func set_hiding() -> void:
	
	is_raving = false;
	is_hiding = true;
	return;
	
func process_movement(t_delta: float) -> void:
	
	# this was originally a part of crab, but we dont need to worry about view
	# input, so this is much thinner
	var input = find_input(t_delta);
	move_input = input - up_direction * input.dot(up_direction);
	move_input = move_input.normalized() * input.length();
	
	# handle acceleration if we are using inputs
	if move_input.length() > 0.25:
		
		velocity += move_input * acceleration * (1.0 if is_on_floor() else air_control) * t_delta;
	# decellerate proportional to the wrong direction movement if we are
	# inputting, otherwise apply full decceleration
		var hvelocity = velocity - up_direction * velocity.dot(up_direction);
		hvelocity *= max(0.0, hvelocity.dot(-move_input) - 0.25);
		velocity -= (hvelocity.normalized() * min(1.0, hvelocity.length())) * decceleration * t_delta;
	else:
		var hvelocity = velocity - up_direction * velocity.dot(up_direction);
		velocity -= (hvelocity.normalized() * min(1.0, hvelocity.length())) * decceleration * t_delta;
	
	# handle the foot pop noises
	if move_input.length() < 0.25:
		pops_player.volume_linear = clamp(pops_player.volume_linear - t_delta * 10.0, 0.0, 1.0);
	else:
		pops_player.volume_linear = clamp(move_input.length(), 0.0, 1.0) * 0.1;
	return;

func process_forces(t_delta: float) -> void:
	
	# not so much a force, but it needs to go somewhere, this smooths out the
	# up vector used when finding orientation, such that we align to the floor
	# but not so perfectly that quick changes in orientation become jarring
	if is_on_floor():
		var target = get_floor_normal().normalized();
		smoothed_up = smoothed_up.lerp(target, t_delta * 8.0).normalized();
	else:
		smoothed_up = smoothed_up.lerp(Vector3.UP, t_delta * 8.0).normalized();
	
	# handle gravity
	velocity += get_gravity() * t_delta;
	
	# handle drag so we can't build up to uncontrollable speeds, trippling its
	# strength when below the water-line
	var drag_strength = drag * (1.0 if global_position.y > 0.0 else 8.0);
	var drag_power = min(velocity.length(),
		pow(velocity.length(), 2.0) * drag_strength * t_delta);
	velocity -= velocity * drag_power;
	
	return;

func turn_character_towards(t_forward: Vector3, t_amount: float):
	
	var up = smoothed_up;
	var forward = global_basis.z;
	var right = global_basis.x;
	var basic_right = Vector3(right.x, clamp(right.y, -0.15, 0.15), right.z).normalized();
	var target_forward = t_forward;
	var target_right = target_forward.cross(up);
	global_basis = Basis(
		basic_right.slerp(target_right, t_amount),
		up,
		forward.slerp(target_forward, t_amount)).orthonormalized();
	return;

func find_walking_blend():
	
	var model_right = get_global_transform_interpolated().basis.x;
	var model_forward = get_global_transform_interpolated().basis.z;
	return Vector2(model_right.dot(move_input), -model_forward.dot(move_input));

func process_animation(t_delta: float) -> void:
	
	# set animation params
	animation_tree.set(ANIM_PARAMS_IS_ON_GROUND, is_on_floor());
	animation_tree.set(ANIM_PARAMS_JUMP_AND_FALL, velocity.dot(up_direction));
	animation_tree.set(ANIM_PARAMS_IS_SWINGING, Input.is_action_just_pressed("swing"));
	animation_tree.set(ANIM_PARAMS_ARM_BLEND, arm_blend);
	
	# here, we're passing the walk blending params as the relationship between
	# where we want to go, and where we are facing, so the characters animation
	# should always be going the right way
	walking_blend = walking_blend.lerp(find_walking_blend(), t_delta * 10.0);
	animation_tree.set(ANIM_PARAMS_WALKING_BLEND, walking_blend);
	
	# if we are moving, try to rotate the crab to the camera direction, also
	# handle the crab rave button such that it only plays when we aren't trying
	# to also move
	if move_input.length() > 0.25:
		
		var hvelocity = velocity - up_direction * velocity.dot(up_direction);
		var speed_alpha = clamp(hvelocity.length() / 10.0, 0.0, 1.0);
		animation_tree.set(ANIM_PARAMS_TIME_SCALE, lerp(1.0, 4.0, speed_alpha));
		turn_character_towards(move_input, 1.0 * t_delta);
		animation_tree.set(ANIM_PARAMS_IS_RAVE_PRESSED, false);
		animation_tree.set(ANIM_PARAMS_IS_HIDE_PRESSED, false);
		arm_blend = lerp(arm_blend, 1.0, t_delta * 10.0);
	else:
		
		animation_tree.set(ANIM_PARAMS_TIME_SCALE, 1.0);
		animation_tree.set(ANIM_PARAMS_IS_RAVE_PRESSED, is_raving);
		animation_tree.set(ANIM_PARAMS_IS_HIDE_PRESSED, is_hiding);
		arm_blend = lerp(arm_blend, 0.0 if is_raving || is_hiding else 1.0, t_delta * 10.0);
	return;

func _physics_process(t_delta: float) -> void:
	
	process_movement(t_delta);
	process_forces(t_delta);
	process_animation(t_delta);
	
	was_on_floor = is_on_floor();
	move_and_slide();
	return;
