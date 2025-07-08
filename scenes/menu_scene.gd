class_name MenuScene extends Node3D

const FRIEND_CONTROL = preload("res://ui/friend_control.tscn");

@onready var canvas_layer: CanvasLayer = $CanvasLayer;
@onready var play_button: Button = $CanvasLayer/Control/MenuList/PlayButton;
@onready var ip_edit: LineEdit = $CanvasLayer/MultiplayerContainer/IpEdit;
@onready var join_button: Button = $CanvasLayer/MultiplayerContainer/JoinButton;
@onready var multiplayer_container: VBoxContainer = $CanvasLayer/MultiplayerContainer;
@onready var host_button: Button = $CanvasLayer/MultiplayerContainer/HostButton;
@onready var friend_list: VBoxContainer = $CanvasLayer/MultiplayerContainer/ScrollContainer/MarginContainer/FriendList;

var last_update = 0.0;

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

func handle_initial_focus():
	
	play_button.grab_focus();
	return;

func _on_join_lobby():
	
	_on_play_button_pressed();
	return;

func _ready() -> void:
	
	handle_initial_focus.call_deferred();
	SteamManager.current.joined_lobby.connect(_on_join_lobby);
	return;


func _on_host_button_pressed() -> void:
	
	MultiplayerManager.init_multiplayer();
	SteamManager.host_lobby();
	return;

func _on_join_button_pressed() -> void:
	
	MultiplayerManager.join_multiplayer(ip_edit.text);
	_on_play_button_pressed();
	return;

func _on_ip_edit_text_changed(t_new_text: String) -> void:
	
	join_button.disabled = !t_new_text.is_valid_ip_address();
	return;

func update_friend_list():
	
	for child in friend_list.get_children():
		child.queue_free.call_deferred();
		
	var friends = SteamManager.get_friend_info();
	var removes = [];
	# list friends in this game first (not relevant now, but when I port this to
	# the in game menu it will be
	for friend in friends:
		if friend.is_online && friend.is_in_this_game:
			var node = FRIEND_CONTROL.instantiate();
			friend_list.add_child(node);
			node.init.call_deferred(friend);
			removes.push_back(friend);
	for friend in removes:
		friends.erase(friend);
	removes.clear();
	# next list friends in a joinable game
	for friend in SteamManager.get_friend_info():
		if friend.is_online && friend.is_playing:
			var node = FRIEND_CONTROL.instantiate();
			friend_list.add_child(node);
			node.init.call_deferred(friend);
			removes.push_back(friend);
	for friend in removes:
		friends.erase(friend);
	removes.clear();
	# then everyone else
	for friend in SteamManager.get_friend_info():
		if friend.is_online:
			var node = FRIEND_CONTROL.instantiate();
			friend_list.add_child(node);
			node.init.call_deferred(friend);
	return;

func _physics_process(_delta: float) -> void:
	
	var now = Time.get_unix_time_from_system();
	if now - last_update > 3.0:
		last_update = now;
		update_friend_list();
	return;


func _on_multiplayer_button_toggled(t_toggled_on: bool) -> void:
	
	multiplayer_container.visible = t_toggled_on;
	return;
