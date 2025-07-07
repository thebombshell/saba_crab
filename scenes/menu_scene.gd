class_name MenuScene extends Node3D

@onready var canvas_layer: CanvasLayer = $CanvasLayer;

func _on_play_button_pressed() -> void:
	
	Gameplay.level_name = "SeagullsCove";
	LoaderScene.load_scene_by_name("GameplayScene");
	return;


func _on_visibility_changed() -> void:
	
	canvas_layer.visible = visible;
	return;
