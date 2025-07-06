class_name Shell extends Area3D

const PHYS_MASK_FLOOR = 64;

static var shell_list: Array[Shell] = [];

@export var is_airborne: bool = false;
var origin_position: Vector3 = Vector3.ZERO;

func _enter_tree() -> void:
	
	shell_list.push_back(self);
	origin_position = global_position;
	$MeshInstance3D.queue_free();
	return;

func _exit_tree() -> void:
	
	shell_list.erase(self);
	return;

func correct_height() -> void:
	
	var query = PhysicsRayQueryParameters3D.new();
	query.collision_mask = PHYS_MASK_FLOOR;
	query.collide_with_areas = false;
	query.collide_with_bodies = true;
	query.from = global_position + Vector3.UP * 2.0;
	query.to = global_position + Vector3.DOWN * 5.0;
	var result = get_world_3d().direct_space_state.intersect_ray(query);
	if result.has("position"):
		global_position = result.position + Vector3.UP * 1.2;
	return;

func _ready() -> void:
	
	if !is_airborne:
		correct_height.call_deferred();
	return;

static func fill_mesh(t_mesh: MultiMesh):
	
	t_mesh.instance_count = max(t_mesh.instance_count, shell_list.size());
	t_mesh.visible_instance_count = shell_list.size();
	for i in shell_list.size():
		t_mesh.set_instance_transform(i, Transform3D(Basis.from_scale(Vector3.ONE * 0.5), shell_list[i].global_position));
		t_mesh.set_instance_color(i, Color(
			shell_list[i].origin_position.x,
			shell_list[i].origin_position.y,
			shell_list[i].origin_position.z));
	return;

func _on_body_entered(t_body: Node3D) -> void:
	
	if t_body is CrabActor && !is_queued_for_deletion():
		t_body.collect_shell();
		queue_free();
	return;
