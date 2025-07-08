class_name MultiplayerManager extends Node

static var current = null;

var is_waiting_for_gameserver: bool = false;

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
	listen_to_peer(peer);
	tree_multiplayer.multiplayer_peer = peer;
	CommandPanel.add_line("MM", "Initializing server at port: %d" % t_port);
	return;

func join_multiplayer_internal(t_ip: String, t_port: int = 60123):
	
	var peer = ENetMultiplayerPeer.new();
	peer.create_client(t_ip, t_port, 0, 0, 0, t_port + 1);
	listen_to_peer(peer);
	tree_multiplayer.multiplayer_peer = peer;
	CommandPanel.add_line("MM", "Joining server at ip: %s:%d" % [t_ip, t_port]);
	return;

func end_multiplayer_internal():
	
	tree_multiplayer.multiplayer_peer = null;
	CommandPanel.add_line("MM", "Ending multiplayer!");
	return;
	
func _connected_to_server():
	
	CommandPanel.add_line("MM", "Connected to server!");
	return;

func _connection_failed():
	
	CommandPanel.add_line("MM", "Failed to connect to server!");
	return;

func _peer_connected(t_id: int):
	
	CommandPanel.add_line("MM", "Peer %d has connected!" % t_id);
	return

func _peer_disconnected(t_id: int):
	
	CommandPanel.add_line("MM", "Peer %d has disconnected!" % t_id);
	return

func listen_to_peer(t_peer: MultiplayerPeer):
	
	t_peer.peer_connected.connect(_peer_connected);
	t_peer.peer_disconnected.connect(_peer_disconnected);
	return;

func _on_created_lobby():
	
	return;

func _on_joined_lobby():
	
	if SteamManager.is_hosting_lobby:
		return;
	var gameserver = SteamManager.get_lobby_gameserver();
	if gameserver != null:
		
		is_waiting_for_gameserver = false;
		join_multiplayer(gameserver[0], gameserver[1]);
	else:
		is_waiting_for_gameserver = true;
	return;

func _on_kicked_from_lobby():
	
	is_waiting_for_gameserver = false;
	return;

func listen_to_steam_manager():
	
	SteamManager.current.created_lobby.connect(_on_created_lobby);
	SteamManager.current.joined_lobby.connect(_on_joined_lobby);
	SteamManager.current.kicked_from_lobby.connect(_on_kicked_from_lobby);
	return;

func _ready():
	
	if is_instance_valid(current):
		push_error("There should only be a single MultiplayerManager at a time");
	current = self;
	
	tree_multiplayer.connected_to_server.connect(_connected_to_server);
	tree_multiplayer.connection_failed.connect(_connection_failed);
	listen_to_steam_manager.call_deferred();
	return;

func _physics_process(_delta: float) -> void:
	
	if is_waiting_for_gameserver:
		_on_joined_lobby();
	return;
