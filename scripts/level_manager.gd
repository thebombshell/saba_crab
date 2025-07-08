class_name LevelManager extends Node3D

@export var player_spawn_points: Array[MultiplayerSpawnPoint] = [];
@export var content_path: String = "";

var player_nodes: Dictionary[int, Node] = {};
var is_ready = false;

func spawn_player(t_id: int) -> void:
	
	player_nodes[t_id] = player_spawn_points.pick_random().spawn(t_id);
	return;

func process_multiplayer(_delta: float) -> void:
	
	if !multiplayer.is_server():
		return;
	
	var removes = [];
	# handle destroying disconnected players
	for id in player_nodes:
		if !multiplayer.get_peers().has(id) && id != multiplayer.get_unique_id():
			if is_instance_valid(player_nodes[id]):
				player_nodes[id].queue_free();
			removes.push_back(id);
	for id in removes:
		player_nodes.erase(id);
	
	# handle creating connected players
	for id in multiplayer.get_peers():
		if !player_nodes.has(id):
			spawn_player(id);
	
	# handle creating host player
	if !player_nodes.has(multiplayer.get_unique_id()):
		spawn_player(multiplayer.get_unique_id());
	return;

func _on_load_complete(t_path: String, t_node: Node):
	
	if t_path == content_path:
		t_node.reparent(self);
		LoaderScene.current.on_load_complete.disconnect(_on_load_complete);
		is_ready = true;
	return;

func _ready():
	
	LoaderScene.current.on_load_complete.connect(_on_load_complete);
	LoaderScene.load_scene(content_path);
	return;

func _physics_process(t_delta: float) -> void:
	
	if multiplayer.has_multiplayer_peer():
		process_multiplayer(t_delta);
	elif !player_nodes.has(0):
			spawn_player(0);
	return;
