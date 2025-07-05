class_name Shell extends Area3D

static var shell_list: Array[Shell] = [];
var origin_position: Vector3 = Vector3.ZERO;

func _enter_tree() -> void:
	
	shell_list.push_back(self);
	origin_position = global_position;
	$MeshInstance3D.queue_free();
	return;

func _exit_tree() -> void:
	
	shell_list.erase(self);
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


func _on_body_entered(_body: Node3D) -> void:
	
	
	return;
