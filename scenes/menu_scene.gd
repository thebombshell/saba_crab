class_name MenuScene extends Node3D

@onready var canvas_layer: CanvasLayer = $CanvasLayer;
@onready var play_button: Button = $CanvasLayer/VBoxContainer/PlayButton;
@onready var ip_edit: LineEdit = $CanvasLayer/MultiplayerContainer/IpEdit;
@onready var join_button: Button = $CanvasLayer/MultiplayerContainer/JoinButton;
@onready var multiplayer_container: VBoxContainer = $CanvasLayer/MultiplayerContainer;
@onready var host_button: Button = $CanvasLayer/MultiplayerContainer/HostButton

func _on_play_button_pressed() -> void:
	
	LoaderScene.load_scene_by_name("GameplayScene");
	return;

func _on_multiplayer_button_pressed() -> void:
	
	multiplayer_container.visible = true;
	host_button.grab_focus();
	return;

func _on_visibility_changed() -> void:
	
	canvas_layer.visible = visible;
	process_mode = Node.PROCESS_MODE_PAUSABLE if visible else Node.PROCESS_MODE_DISABLED;
	return;

func _ready() -> void:
	
	play_button.grab_focus();
	return;


func _on_host_button_pressed() -> void:
	
	MultiplayerManager.init_multiplayer();
	_on_play_button_pressed();
	return;

func _on_join_button_pressed() -> void:
	
	MultiplayerManager.join_multiplayer(ip_edit.text);
	_on_play_button_pressed();
	return;

func _on_ip_edit_text_changed(t_new_text: String) -> void:
	
	join_button.disabled = !t_new_text.is_valid_ip_address();
	return;
