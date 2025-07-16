class_name FishSpiritActor extends CharacterBody3D

const ANIM_PARAMS_IS_ON_GROUND = "parameters/StateMachine/conditions/is_on_ground";
const ANIM_PARAMS_IS_SITTING = "parameters/StateMachine/conditions/is_sitting";
const ANIM_PARAMS_VERTICAL_SPEED = "parameters/StateMachine/InAir/blend_position";
const ANIM_PARAMS_HORIZONTAL_SPEED = "parameters/StateMachine/OnGround/blend_position";
const ANIM_PARAMS_HEAD_LOOK_DIRECTION = "parameters/HeadLook/blend_position";

@onready var animation_tree: AnimationTree = $AnimationTree;

var is_move_to_order_active: bool = false;
var move_to_target: Vector3 = Vector3.ZERO;
var look_to_target: Node3D = null;
var look_direction: Vector2 = Vector2.ZERO;

func look_to(t_target: Node3D):
	
	look_to_target = t_target;
	return;

func jump():
	
	animation_tree.set(ANIM_PARAMS_IS_SITTING, false);
	velocity.y = 10.0;
	return;

func sit():
	
	animation_tree.set(ANIM_PARAMS_IS_SITTING, true);
	return;

func move_to_position(t_position : Vector3):
	
	animation_tree.set(ANIM_PARAMS_IS_SITTING, false);
	is_move_to_order_active = true;
	move_to_target = t_position;
	return;

func process_forces(t_delta: float) -> void:
	
	velocity += get_gravity() * t_delta;
	return;

func process_moving(t_delta: float) -> void:
	
	var hvelocity = velocity - Vector3.UP * velocity.y;
	if is_move_to_order_active:
		
		var diff = move_to_target - global_position;
		var dist = diff.length();
		var dir = diff.normalized();
		if dist < 0.5:
			is_move_to_order_active = false;
		else:
			var target_vel = dir * 10.0;
			velocity = velocity.lerp(target_vel, t_delta * 8.0);
	else:
		velocity = Vector3(0.0, velocity.y, 0.0);
	var turn_vector = (velocity - Vector3.UP * velocity.y);
	var turn_direction = turn_vector.normalized();
	if turn_vector.length() > 0.1:
		global_basis = global_basis.slerp(Basis(
			turn_direction.cross(Vector3.UP),
			Vector3.UP,
			turn_direction).orthonormalized(), t_delta * 4.0).orthonormalized();
	return;


func process_animation(t_delta: float) -> void:
	
	var hspeed = Vector2(velocity.x, velocity.z).length();
	var vspeed = velocity.y;
	animation_tree.set(ANIM_PARAMS_IS_ON_GROUND, is_on_floor());
	animation_tree.set(ANIM_PARAMS_HORIZONTAL_SPEED, hspeed);
	animation_tree.set(ANIM_PARAMS_VERTICAL_SPEED, vspeed);
	
	if is_instance_valid(look_to_target):
		
		var target = look_to_target.global_position;
		var dir = (target - global_position).normalized();
		var look_dir = Vector2(
			-global_basis.x.dot(dir),
			global_basis.y.dot(dir));
		if global_basis.z.dot(dir) > 0.0:
			look_direction = look_direction.lerp(look_dir, t_delta * 8.0);
		else:
			look_direction = look_direction.lerp(Vector2.ZERO, t_delta * 8.0);
	else:
		look_direction = look_direction.lerp(Vector2.ZERO, t_delta * 8.0);
	animation_tree.set(ANIM_PARAMS_HEAD_LOOK_DIRECTION, look_direction);
	return;

func _physics_process(t_delta: float) -> void:
	
	process_forces(t_delta);
	process_moving(t_delta);
	process_animation(t_delta);
	move_and_slide();
	return;
