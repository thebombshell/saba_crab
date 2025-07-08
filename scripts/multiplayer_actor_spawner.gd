class_name MultiplayerActorSpawner extends MultiplayerSpawner

var registered_actors: Dictionary[int, PackedScene] = {};

func register(t_scene: PackedScene):
	
	var uid = ResourceLoader.get_resource_uid(t_scene.resource_path);
	if !registered_actors.has(uid):
		registered_actors[uid] = t_scene;
	return;

func _spawn(t_data: Variant):
	
	if t_data is not Dictionary:
		push_error("Was expecting a dictionary to MultiplayerActorSpawner spawn");
		return null;
	if !t_data.has("uid"):
		push_error("Data does not contain a uid, we can not know what to spawn");
		return null;
	if t_data.uid is not int:
		push_error("UID is not a valid type, we can not know what to spawn");
		return null;
	if !registered_actors.has(t_data.uid):
		push_error("UID given by data is unknown to the spawner, can not spawn");
		return null;
	if !t_data.has("transform"):
		push_error("Data does not contain a transform, do not know whwere to spawn");
		return null;
	if t_data.transform is not Transform3D:
		push_error("Transform is not valid, do not know where to spawn");
		return null;
	
	var packed = registered_actors[t_data.uid];
	var node = packed.instantiate();
	node.transform = t_data.transform;
	if node.has_method("_on_spawn"):
		node._on_spawn(t_data);
	return node;

func try_spawn(t_data: Variant) -> Node:
	
	if !multiplayer.has_multiplayer_peer():
		var node = _spawn(t_data);
		get_node(spawn_path).add_child(node);
		return node;
	if !multiplayer.is_server():
		return null;
	return spawn(t_data);

func _ready():
	
	spawn_function = _spawn;
	return;
