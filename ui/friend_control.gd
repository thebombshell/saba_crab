extends Control

@onready var label: AutoLabel = $Label
@onready var invite_button: Container = $HBoxContainer/InviteContainer;
@onready var join_button: Container = $HBoxContainer/JoinContainer;

var id: int = 0;
var friend_name: String = "";
var is_online: bool = false;
var is_playing: bool = false;
var is_in_this_game: bool = false;

func init(t_friend: Dictionary):
	
	id = t_friend.id;
	friend_name = t_friend.name;
	is_online = t_friend.is_online;
	is_playing = t_friend.is_playing;
	is_in_this_game = t_friend.is_in_this_game;
	
	label.text = friend_name;
	invite_button.visible = !is_in_this_game;
	join_button.visible = is_playing;
	return;


func _on_join_button_pressed() -> void:
	
	SteamManager.join_friend(id);
	return;


func _on_invite_button_pressed() -> void:
	
	SteamManager.invite_friend(id);
	return;
