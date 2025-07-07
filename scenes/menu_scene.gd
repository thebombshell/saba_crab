class_name MenuScene extends Node3D

@onready var canvas_layer: CanvasLayer = $CanvasLayer;
@onready var play_button: Button = $CanvasLayer/VBoxContainer/PlayButton

func _on_play_button_pressed() -> void:
	
	Gameplay.level_name = "SeagullsCove";
	LoaderScene.load_scene_by_name("GameplayScene");
	return;


func _on_visibility_changed() -> void:
	
	canvas_layer.visible = visible;
	process_mode = Node.PROCESS_MODE_PAUSABLE if visible else Node.PROCESS_MODE_DISABLED;
	return;

func _ready() -> void:
	
	play_button.grab_focus();
	return;
