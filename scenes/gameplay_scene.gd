class_name Gameplay extends MultiplayerSpawner

static var current: Gameplay = null;

@export var is_ready: bool = false;

var current_scene: LevelManager = null;

var is_spawning_auhtority: bool:
	get: return !multiplayer.has_multiplayer_peer() || multiplayer.is_server();

func try_spawn(t_data: Variant) -> Node:
	
	if !multiplayer.has_multiplayer_peer():
		var node = _spawn(t_data);
		get_node(spawn_path).add_child(node);
		return node;
	if !multiplayer.is_server():
		return null;
	return spawn(t_data);

func _spawn(t_data: Variant):
	
	if t_data is not String:
		push_error("Gameplay was expecting a level name");
	is_ready = false;
	if is_instance_valid(current_scene):
		current_scene.queue_free();
	current_scene = load("res://scenes/" + t_data + ".tscn").instantiate();
	return current_scene;

func _ready():
	
	# store current gameplay for easy access when needed
	if is_instance_valid(current):
		push_error("There shoudl only be one Gameplay at a time");
	current = self;
	
	LoaderScene.current.get_node("MenuScene").visible = false;
	LoaderScene.current.get_node("MenuScene").process_mode = Node.PROCESS_MODE_DISABLED;
	
	spawn_function = _spawn;
	if is_spawning_auhtority:
		try_spawn("SeagullsCove");
	return;

func _physics_process(_delta: float) -> void:
	
	if is_spawning_auhtority:
		is_ready = is_instance_valid(current_scene) && current_scene.is_ready;
	return;
