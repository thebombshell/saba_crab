class_name Gameplay extends Node3D

static var level_name: String = "SeagullsCove";

func _on_load_complete(t_path: String, t_node: Node):
	
	LoaderScene.current.get_node("MenuScene").visible = false;
	if t_path.contains(level_name + ".tscn"):
		t_node.reparent(self);
	return;

func _ready():
	
	LoaderScene.current.on_load_complete.connect(_on_load_complete);
	LoaderScene.load_scene("res://scenes/" + level_name + ".tscn");
	return;
