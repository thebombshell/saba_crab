class_name MultiplayerManager extends Node

static var current = null;

var tree_multiplayer: MultiplayerAPI:
	get: return get_tree().get_multiplayer();

static func init_multiplayer(t_port: int = 60123):
	
	return current.init_multiplayer_internal(t_port);

static func join_multiplayer(t_ip: String, t_port: int = 60123):
	
	return current.join_multiplayer_internal(t_ip, t_port);

static func end_multiplayer():
	
	return current.end_multiplayer_internal();

func init_multiplayer_internal(t_port: int = 60123):
	
	var peer = ENetMultiplayerPeer.new();
	peer.create_server(t_port, 8);
	tree_multiplayer.multiplayer_peer = peer;
	return;

func join_multiplayer_internal(t_ip: String, t_port: int = 60123):
	
	var peer = ENetMultiplayerPeer.new();
	peer.create_client(t_ip, t_port);
	tree_multiplayer.multiplayer_peer = peer;
	return;

func end_multiplayer_internal():
	
	tree_multiplayer.multiplayer_peer = null;
	return;

func _ready():
	
	if is_instance_valid(current):
		push_error("There should only be a single MultiplayerManager at a time");
	current = self;
	return;
