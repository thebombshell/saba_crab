class_name CrabActor extends CharacterBody3D

const ANIM_PARAMS_IS_ON_GROUND = "parameters/BlendTree/StateMachine/conditions/is_on_ground";
const ANIM_PARAMS_IS_RAVE_PRESSED = "parameters/BlendTree/StateMachine/conditions/is_rave_pressed";
const ANIM_PARAMS_JUMP_AND_FALL = "parameters/BlendTree/StateMachine/JumpAndFall/blend_position";
const ANIM_PARAMS_WALKING_BLEND = "parameters/BlendTree/StateMachine/Walking/blend_position";
const ANIM_PARAMS_TIME_SCALE = "parameters/BlendTree/TimeScale/scale";

@onready var animation_tree: AnimationTree = $AnimationTree;
@onready var animation_player: AnimationPlayer = $crab/AnimationPlayer;
@onready var crab: Node3D = $crab;

@export var acceleration: float = 5.0;
@export var decceleration: float = 20.0;
@export var jump_impulse: float = 6.0;
@export var air_control: float = 0.5;
@export var drag: float = 0.005;


var move_input: Vector3 = Vector3.ZERO;
var walking_blend: Vector2 = Vector2.ZERO;
var camera: Camera3D = null;
var camera_forward: Vector3 = Vector3.FORWARD;
var camera_right: Vector3 = Vector3.RIGHT;

func process_movement(t_delta: float) -> void:
	
	# we'll need the scene camera, if there isn't one active, then we've no
	# reason to be moving anyway.
	if !is_instance_valid(camera):
		return;
	
	# here we get the camera's local Forward and Right vectors, we use them to
	# get our inputs relative to the camera, and then we remove part of the
	# input relating to our characters up direction, as we don't want to be
	# applying up and down forces when we are only scuttling around.
	
	camera_forward = Vector3.FORWARD * camera.global_basis.inverse();
	camera_right = Vector3.RIGHT * camera.global_basis.inverse();
	var input = (
		(camera_right * Input.get_axis("move_left", "move_right")) +
		(camera_forward * Input.get_axis("move_down", "move_up")));
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
	
	# handle jumping
	if is_on_floor() && Input.is_action_just_pressed("jump"):
		velocity -= up_direction * velocity.dot(up_direction);
		velocity += up_direction * jump_impulse;
	return;
	
func process_forces(t_delta: float) -> void:
	
	# handle gravity
	velocity += get_gravity() * t_delta;
	
	# handle drag so we can't build up to uncontrollable speeds
	var drag_power = min(velocity.length(),
		pow(velocity.length(), 2.0) * drag * t_delta);
	velocity -= velocity * drag_power;
	return;

func turn_character_towards(t_forward: Vector3, t_amount: float):
	
	var ref_forward = Vector3.FORWARD * Quaternion(up_direction, 0.0);
	var ref_right = Vector3.RIGHT * Quaternion(up_direction, 0.0);
	var forward = Vector3.FORWARD * global_basis;
	var right = Vector3.RIGHT * global_basis;
	var angle = atan2(ref_forward.dot(-right), ref_forward.dot(forward));
	var target_angle = atan2(ref_forward.dot(t_forward.cross(up_direction)), ref_forward.dot(t_forward));
	var angle_diff = angle_difference(angle, target_angle);
	global_basis = Basis(Quaternion(up_direction, angle + angle_diff * t_amount));
	return;

func find_walking_blend():
	
	var model_right = get_global_transform_interpolated().basis.x;
	var model_forward = get_global_transform_interpolated().basis.z;
	return Vector2(model_right.dot(move_input), -model_forward.dot(move_input));

func process_animation(t_delta: float) -> void:
	
	if !is_instance_valid(camera):
		return;
	
	# set animation params
	animation_tree.set(ANIM_PARAMS_IS_ON_GROUND, is_on_floor());
	animation_tree.set(ANIM_PARAMS_JUMP_AND_FALL, velocity.dot(up_direction));
	
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
		if Input.is_action_pressed("target_hold"):
			turn_character_towards(camera_forward, 4.0 * t_delta);
		else:
			turn_character_towards(move_input, 1.0 * t_delta);
		animation_tree.set(ANIM_PARAMS_IS_RAVE_PRESSED, false);
	elif Input.is_action_pressed("rave"):
		
		animation_tree.set(ANIM_PARAMS_TIME_SCALE, 1.0);
		animation_tree.set(ANIM_PARAMS_IS_RAVE_PRESSED, true);
	else:
		
		animation_tree.set(ANIM_PARAMS_TIME_SCALE, 1.0);
		animation_tree.set(ANIM_PARAMS_IS_RAVE_PRESSED, false);
	return;

func _physics_process(t_delta: float) -> void:
	
	camera = get_viewport().get_camera_3d();
	process_movement(t_delta);
	process_forces(t_delta);
	process_animation(t_delta);
	move_and_slide();
	return;
