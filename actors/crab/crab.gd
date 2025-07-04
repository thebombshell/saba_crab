class_name CrabActor extends CharacterBody3D

const PHYS_LAYER_NORMAL = 1;
const PHYS_LAYER_PLAYER = 2;
const PHYS_LAYER_GRABBABLE = 4;
const PHYS_LAYER_HARMFUL = 8;
const PHYS_LAYER_ENEMIES = 16;

const ANIM_PARAMS_IS_ON_GROUND = "parameters/BlendTree/StateMachine/conditions/is_on_ground";
const ANIM_PARAMS_IS_RAVE_PRESSED = "parameters/BlendTree/StateMachine/conditions/is_rave_pressed";
const ANIM_PARAMS_JUMP_AND_FALL = "parameters/BlendTree/StateMachine/JumpAndFall/blend_position";
const ANIM_PARAMS_WALKING_BLEND = "parameters/BlendTree/StateMachine/Walking/blend_position";
const ANIM_PARAMS_TIME_SCALE = "parameters/BlendTree/TimeScale/scale";
const ANIM_PARAMS_IS_GRABBING_ONE = "parameters/BlendTree/HandMachine/conditions/is_grabbing_1";
const ANIM_PARAMS_IS_GRABBING_TWO = "parameters/BlendTree/HandMachine/conditions/is_grabbing_2";
const ANIM_PARAMS_HAS_GRABBED = "parameters/BlendTree/HandMachine/conditions/has_grabbed";
const ANIM_PARAMS_IS_YEETING = "parameters/BlendTree/HandMachine/conditions/is_yeeting";
const ANIM_PARAMS_ARM_BLEND = "parameters/BlendTree/Add2/add_amount";

@onready var animation_tree: AnimationTree = $AnimationTree;
@onready var animation_player: AnimationPlayer = $crab/AnimationPlayer;
@onready var skeleton_3d: Skeleton3D = $crab/CrabSkeleton/Skeleton3D;
@onready var bone_attachment_3d: BoneAttachment3D = $crab/CrabSkeleton/Skeleton3D/BoneAttachment3D;
@onready var grab_area: Area3D = $GrabArea;
@onready var crab: Node3D = $crab;

@export var acceleration: float = 5.0;
@export var decceleration: float = 20.0;
@export var jump_impulse: float = 6.0;
@export var air_control: float = 0.5;
@export var drag: float = 0.005;

var move_input: Vector3 = Vector3.ZERO;
var camera: Camera3D = null;
var camera_forward: Vector3 = Vector3.FORWARD;
var camera_right: Vector3 = Vector3.RIGHT;
var grabbed: RigidBody3D = null;
var grab_start_timer : float = -1.0;

var walking_blend: Vector2 = Vector2.ZERO;
var arm_blend: float = 1.0;
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

func process_grabbing(t_delta: float):
	
	if grab_start_timer <= 0.0:
		update_grabbed(t_delta);
		return;
	var diff = Time.get_unix_time_from_system() - grab_start_timer;
	if diff >= 0.4:
		grab_start_timer = -1.0;
		try_grab();
	return;

func turn_character_towards(t_forward: Vector3, t_amount: float):
	
	var ref_forward = Vector3.FORWARD * Quaternion(up_direction, 0.0);
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

func update_grabbed(t_delta: float):
	
	if !is_instance_valid(grabbed):
		
		if Input.is_action_just_pressed("grab"):
			init_grab();
		return;
	
	grabbed.position = grabbed.position.lerp(grabbed.grab_point, t_delta * 10.0);
	grabbed.rotation = grabbed.rotation.slerp(grabbed.grab_rotation, t_delta * 10.0);
	if Input.is_action_just_pressed("yeet"):
		yeet();
	return;

func init_grab():
	
	if is_instance_valid(grabbed) || grab_start_timer >= 0.0:
		return;
	
	for obj in grab_area.get_overlapping_bodies():
		if obj is GrabbableActor:
			grab_start_timer = Time.get_unix_time_from_system();
			if obj.two_handed:
				animation_tree.set(ANIM_PARAMS_IS_GRABBING_TWO, true);
			else:
				animation_tree.set(ANIM_PARAMS_IS_GRABBING_ONE, true);
			break;
	return;

func try_grab():
	
	# ignore request if we're already holding something
	if is_instance_valid(grabbed):
		return;
	
	animation_tree.set(ANIM_PARAMS_IS_GRABBING_ONE, false);
	animation_tree.set(ANIM_PARAMS_IS_GRABBING_TWO, false);
	# check overlapping objects for the first valid grabbable
	for obj in grab_area.get_overlapping_bodies():
		if obj is GrabbableActor:
			grabbed = obj;
			grabbed.collision_layer = grabbed.collision_layer & (~PHYS_LAYER_NORMAL);
			grabbed.reparent(bone_attachment_3d);
			animation_tree.set(ANIM_PARAMS_IS_YEETING, false);
			animation_tree.set(ANIM_PARAMS_HAS_GRABBED, true);
			break;
	return;

func yeet():
	
	animation_tree.set(ANIM_PARAMS_IS_GRABBING_ONE, false);
	animation_tree.set(ANIM_PARAMS_IS_GRABBING_TWO, false);
	animation_tree.set(ANIM_PARAMS_IS_YEETING, true);
	grabbed.reparent(get_parent_node_3d());
	var dir = (grabbed.global_position -
		(global_position + get_global_transform_interpolated().basis.z * 10.0)).normalized();
	grabbed.global_position += dir;
	grabbed.linear_velocity = (dir + up_direction * 0.5) * 10.0;
	grabbed.collision_layer = grabbed.collision_layer | PHYS_LAYER_NORMAL;
	grabbed = null;
	return;

func process_animation(t_delta: float) -> void:
	
	if !is_instance_valid(camera):
		return;
	
	# set animation params
	animation_tree.set(ANIM_PARAMS_IS_ON_GROUND, is_on_floor());
	animation_tree.set(ANIM_PARAMS_JUMP_AND_FALL, velocity.dot(up_direction));
	animation_tree.set(ANIM_PARAMS_HAS_GRABBED, is_instance_valid(grabbed));
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
		if Input.is_action_pressed("target_hold"):
			turn_character_towards(camera_forward, 4.0 * t_delta);
		else:
			turn_character_towards(move_input, 1.0 * t_delta);
		animation_tree.set(ANIM_PARAMS_IS_RAVE_PRESSED, false);
		arm_blend = lerp(arm_blend, 1.0, t_delta * 10.0);
	elif Input.is_action_pressed("rave"):
		
		animation_tree.set(ANIM_PARAMS_TIME_SCALE, 1.0);
		animation_tree.set(ANIM_PARAMS_IS_RAVE_PRESSED, true);
		arm_blend = lerp(arm_blend, 0.0, t_delta * 10.0);
	else:
		
		animation_tree.set(ANIM_PARAMS_TIME_SCALE, 1.0);
		animation_tree.set(ANIM_PARAMS_IS_RAVE_PRESSED, false);
		arm_blend = lerp(arm_blend, 1.0, t_delta * 10.0);
	return;

func _physics_process(t_delta: float) -> void:
	
	camera = get_viewport().get_camera_3d();
	process_movement(t_delta);
	process_grabbing(t_delta);
	process_forces(t_delta);
	process_animation(t_delta);
	move_and_slide();
	return;
