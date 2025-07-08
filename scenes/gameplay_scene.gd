class_name Gameplay extends MultiplayerSynchronizer

static var current: Gameplay = null;

@export var level_name: String = "SeagullsCove";
var current_level_name: String = "";
var previous_level_name: String = "";

func load_level(t_name: String):
	
	# on loading new level, clean the curent level, store the previous level so
	# we can handle the veyr rare edgecase that someone joins the exact frame a
	# new load occurs, so they know to clena it up, then ask the loader scene to
	# grab our target level
	
	for child in get_children():
		child.queue_free.call_deferred();
	previous_level_name = current_level_name;
	current_level_name = t_name;
	LoaderScene.load_scene("res://scenes/" + t_name + ".tscn");
	return;

func _on_load_complete(t_path: String, t_node: Node):
	
	# ensure menu is hidden
	LoaderScene.current.get_node("MenuScene").visible = false;
	
	# if the previous level is loaded, then we know we're in a rare edgecase and
	# can ignore it by cleaning up the node
	if (!previous_level_name.is_empty() &&
		t_path.contains(previous_level_name + ".tscn")):
		t_node.queue_free.call_deferred();
	
	# if this is a level we expect to load, then we reparent it here, and enable
	# it. Addendum, this can be hit when you first load gameplay due to the
	# order of operations on LoaderScene, so we only want to handle this when we
	# know current_level_name has content
	if (!current_level_name.is_empty() &&
		t_path.contains(current_level_name + ".tscn")):
		t_node.reparent(self);
		t_node.process_mode = Node.PROCESS_MODE_ALWAYS;
		t_node.visible = true;
	return;

func _ready():
	
	# store current gameplay for easy access when needed
	if is_instance_valid(current):
		push_error("There shoudl only be one Gameplay at a time");
	current = self;
	
	# listen to the loader scenes load completion
	LoaderScene.current.on_load_complete.connect(_on_load_complete);
	
	if multiplayer.has_multiplayer_peer() && !multiplayer.is_server():
		level_name = "";
	return;

func _physics_process(_delta: float) -> void:
	
	# if level has changed we should load the new one
	if level_name != current_level_name:
		load_level(level_name);
	return;
