class_name SteamManager extends Node

const CMD_NAME :String = "STEAMMANAGER";
const IP_ADDRESS_VAR :String = "ip_address";
const NEEDS_UDP_BLASTING_VAR :String = "needs_udp_blasting";
const GAMESERVER_HOST_VAR :String = "gameserver_host";
const UDP_BLASTER_HEADER :int = 0xb335b335;

static var current :SteamManager = null;

static var is_in_lobby :bool :
	get: return is_instance_valid(current) && current.current_lobby != 0;

static var is_hosting_lobby :bool :
	get: return is_instance_valid(current) && current.is_hosting;

static var is_udp_blasting :bool :
	get: return is_instance_valid(current) && current.udp_blasting_start_time >= 0.0;

static var default_port: int = 60123;

var current_lobby :int = 0;
var join_lobby_queue :Array[Callable] = [];
var lobby_members :Array[int] = [];
var is_host_lobby_pending :bool = false;
var is_hosting :bool = false;
var lobby_member_ips :Dictionary[int, String] = {};
var update_metadata_thread :Thread = null;
var update_gameserver_thread :Thread = null;
var udp_blaster_server :PacketPeerUDP = null;
var udp_blaster_peer :PacketPeerUDP = null;
var udp_blasting_start_time :float = -1.0;

signal created_lobby();
signal joined_lobby();
signal kicked_from_lobby();

func _ready():
	
	if current != null:
		push_error("There should only be a single SteamManager");
	current = self;
	
	var ret = Steam.steamInitEx();
	if ret.status != 0 || Steam.restartAppIfNecessary(Steam.current_app_id):
		push_error(ret.verbal)
		get_tree().quit();
	
	Steam.lobby_joined.connect(_on_join_lobby);
	Steam.lobby_created.connect(_on_create_lobby)
	Steam.lobby_kicked.connect(_on_kicked_from_lobby);
	Steam.lobby_data_update.connect(_on_lobby_data_update);
	return;

func process_udp_blaster_peer():
	
	if udp_blaster_peer == null:
		udp_blaster_peer = PacketPeerUDP.new();
		CommandPanel.add_line(CMD_NAME, "Opening UDP Blaster Peer as a %s" % (
			"host" if is_hosting else "client"));
	var data = PackedByteArray();
	data.resize(16);
	data.encode_u64(0, UDP_BLASTER_HEADER);
	data.encode_u64(8, Steam.current_steam_id);
	if is_hosting:
		for member in lobby_member_ips:
			var member_needs_udp_blasting = Steam.getLobbyMemberData(
				current_lobby, member, NEEDS_UDP_BLASTING_VAR) == "true";
			if member_needs_udp_blasting:
				udp_blaster_peer.set_dest_address(lobby_member_ips[member], default_port);
				udp_blaster_peer.put_packet(data);
	else:
		var gameserver = get_lobby_gameserver();
		if gameserver != null:
			udp_blaster_peer.set_dest_address(gameserver[0], gameserver[1]);
			udp_blaster_peer.put_packet(data);
	return;

func process_udp_blaster_server():
	
	if udp_blaster_server == null:
		udp_blaster_server = PacketPeerUDP.new();
		udp_blaster_server.bind(default_port);
		CommandPanel.add_line(CMD_NAME, "Opening UDP Blaster Server");
	for i in min(100, udp_blaster_server.get_available_packet_count()):
		var packet = udp_blaster_server.get_packet();
		print("packet recieved");
		if !is_hosting && packet.size() == 16 && packet.decode_u64(0) == UDP_BLASTER_HEADER:
			var gameserver_host = Steam.getLobbyData(current_lobby, GAMESERVER_HOST_VAR);
			if gameserver_host.is_valid_int() && gameserver_host.to_int() == packet.decode_u64(8):
				_end_udp_blasting(true);
				return;
	if (Time.get_unix_time_from_system() - udp_blasting_start_time) > 20.0:
		_end_udp_blasting(false);
	return;

func process_udp_blasting():
	
	process_udp_blaster_peer();
	if !is_hosting:
		process_udp_blaster_server();
	return;

func _physics_process(_delta: float) -> void:
	
	if (is_hosting || Steam.getLobbyMemberData(
		current_lobby, Steam.current_steam_id, NEEDS_UDP_BLASTING_VAR) == "true"):
		process_udp_blasting();
	Steam.run_callbacks();
	return;

func should_update_lobby_member_ip(t_member_id :int, t_ip :String) -> bool:
	
	return (t_member_id != Steam.current_steam_id &&
		(!lobby_member_ips.has(t_member_id) ||
		lobby_member_ips[t_member_id] != t_ip));

func update_lobby_member_ip(t_member_id :int, t_ip :String):
	
	if !should_update_lobby_member_ip(t_member_id, t_ip):
		return;
	lobby_member_ips[t_member_id] = t_ip;
	return;

func launch_udp_tcp_blasters():
	
	var member_count = Steam.getNumLobbyMembers(current_lobby);
	for i in member_count:
		var member = Steam.getLobbyMemberByIndex(current_lobby, i);
		var data = Steam.getLobbyMemberData(current_lobby, member, "ip_address");
		if data.is_valid_ip_address():
			update_lobby_member_ip(member, data);
	return;

func _on_lobby_data_update(t_success :int, t_lobby_id :int, t_member_id :int):
	
	if t_success != Steam.RESULT_OK:
		return;
	
	if t_member_id != t_lobby_id:
		var data = Steam.getLobbyMemberData(current_lobby, t_member_id, "ip_address");
		if data.is_valid_ip_address():
			update_lobby_member_ip(t_member_id, data);
	return;

func _on_create_lobby(t_connect: int, _lobby: int):
	
	is_host_lobby_pending = false;
	
	if t_connect != Steam.RESULT_OK:
		CommandPanel.add_line("STEAMMANAGAER", "Failed to create lobby with error: 0x016X" % t_connect);
		return;
	SteamManager.try_set_lobby_gameserver();
	created_lobby.emit();
	return

func _on_join_lobby(t_lobby: int, _permission: int, _locked: bool, _response: int):
	
	if SteamManager.is_in_lobby:
		CommandPanel.add_line(CMD_NAME, "Already in lobby");
		return;
	current_lobby = t_lobby;
	for callback in join_lobby_queue:
		callback.call();
	join_lobby_queue.clear();
	try_set_lobby_user_metadata();
	joined_lobby.emit();
	return;

func _on_kicked_from_lobby(_lobby: int, _admin: int, _disconnect: int):
	
	current_lobby = 0;
	kicked_from_lobby.emit();
	return;

func _refresh_lobby_members():
	
	var count = Steam.getNumLobbyMembers(current.current_lobby);
	lobby_members.clear();
	for i in count:
		lobby_members.push_back(Steam.getLobbyMemberByIndex(current.current_lobby, i));
	return;

static func refresh_lobby_members():
	
	current._refresh_lobby_members();
	return;

static func lobby_has_friend(t_friend :int):
	
	if !is_in_lobby:
		return false;
	return current.lobby_members.has(t_friend);

static func get_friend_info():
	
	var output = [];
	for t_i in Steam.getFriendCount(Steam.FriendFlags.FRIEND_FLAG_IMMEDIATE):
		
		var friend_id = Steam.getFriendByIndex(t_i, Steam.FriendFlags.FRIEND_FLAG_IMMEDIATE);
		var gameinfo = Steam.getFriendGamePlayed(friend_id);
		var is_playing = false;
		if (gameinfo.has('id') && gameinfo.id == Steam.current_app_id &&
			gameinfo.has('lobby') && gameinfo.lobby != 0):
			is_playing = true;
		var friend_obj = {
			'id': friend_id,
			'name': Steam.getFriendPersonaName(friend_id),
			'is_online': Steam.getFriendPersonaState(friend_id),
			'is_playing': is_playing,
			'is_in_this_game': lobby_has_friend(friend_id)
		};
		output.push_back(friend_obj);
	return output;

static func host_lobby():
	
	current.is_hosting = true;
	if current.is_host_lobby_pending:
		return;
	current.is_host_lobby_pending = true;
	Steam.createLobby(Steam.LOBBY_TYPE_FRIENDS_ONLY, 8);
	return;

static func invite_friend(t_friend_id :int):
	
	if !is_in_lobby:
		current.join_lobby_queue.push_back(invite_friend.bind(t_friend_id));
		host_lobby();
	else:
		Steam.inviteUserToLobby(current.current_lobby, t_friend_id);
	return;

static func join_friend(t_friend_id: int, t_callback :Variant = null):
	
	current.is_hosting = false;
	if t_callback is Callable:
		current.join_lobby_queue.push_back(t_callback);
	var gameinfo = Steam.getFriendGamePlayed(t_friend_id);
	if (gameinfo.has('id') && gameinfo.id == Steam.current_app_id &&
		gameinfo.has('lobby') && gameinfo.lobby != 0):
		join_lobby(gameinfo.lobby);
	return;

static func join_lobby(t_lobby: int):
	
	Steam.joinLobby(t_lobby);
	return;

static func leave_lobby():
	
	Steam.leaveLobby(current.current_lobby);
	current._on_kicked_from_lobby(current.current_lobby, 0, 1);
	return;

static func get_lobby_owner():
	
	return Steam.getLobbyOwner(current.current_lobby);

static func get_lobby_gameserver() -> Variant:
	
	var gameserver = Steam.getLobbyGameServer(current.current_lobby);
	if gameserver.ret:
		return [gameserver.ip, gameserver.port];
	return null;

static func _on_set_lobby_gameserver_ip_response(t_body :String):
	
	if t_body.is_empty():
		CommandPanel.add_line(CMD_NAME, "Failed to retireve ip for setting the gameserver ip, retrying...");
		try_set_lobby_gameserver.call_deferred();
		return;
	CommandPanel.add_line(CMD_NAME, "Successfully retrieved ip for setting the gameserver ip");
	var ip = t_body
	var port = default_port;
	Steam.setLobbyGameServer(current.current_lobby, ip, port);
	Steam.setLobbyData(current.current_lobby, GAMESERVER_HOST_VAR, str(Steam.current_steam_id));
	return;

func _try_set_lobby_gameserver():
	
	var body = try_get_http("http://ifconfig.me", "/ip");
	_on_set_lobby_gameserver_ip_response.call_deferred(body);
	return;

static func try_set_lobby_gameserver():
	
	if current.update_gameserver_thread != null:
		current.update_gameserver_thread.wait_to_finish();
	current.update_gameserver_thread = Thread.new();
	current.update_gameserver_thread.start(current._try_set_lobby_gameserver);
	return;

static func _on_set_lobby_user_metadata_response(t_body :String):
	
	if t_body.is_empty():
		CommandPanel.add_line(CMD_NAME, "Failed to retireve ip for setting the user metadata, retrying...");
		try_set_lobby_user_metadata.call_deferred();
		return;
	CommandPanel.add_line(CMD_NAME, "Successfully retrieved ip for setting the user metadata");
	Steam.setLobbyMemberData(current.current_lobby, "ip_address", t_body);
	return;

static func connect_to_http(t_address :String) -> HTTPClient:
	
	var http = HTTPClient.new();
	if http.connect_to_host(t_address, 80) != OK:
		return null;
	while http.get_status() == HTTPClient.STATUS_CONNECTING || http.get_status() == HTTPClient.STATUS_RESOLVING:
		http.poll();
		OS.delay_msec(50);
	return http if http.get_status() == HTTPClient.STATUS_CONNECTED else null;

static func try_get_http(t_address :String, t_query :String) -> String:
	
	var http = connect_to_http(t_address);
	if http == null:
		return "";
	
	http.request(HTTPClient.METHOD_GET, t_query, []);
	while http.get_status() == HTTPClient.STATUS_REQUESTING:
		http.poll();
		OS.delay_msec(50);
	if http.get_status() != HTTPClient.STATUS_BODY || !http.has_response():
		return "";
	
	var buffer = PackedByteArray();
	while http.get_status() == HTTPClient.STATUS_BODY:
		http.poll();
		var chunk = http.read_response_body_chunk();
		if chunk.size() == 0:
			OS.delay_msec(50);
		else:
			buffer = buffer + chunk;
	http.close();
	return buffer.get_string_from_ascii();

func _try_set_lobby_user_metadata():
	
	var body = try_get_http("http://ifconfig.me", "/ip");
	_on_set_lobby_user_metadata_response.call_deferred(body);
	return;

static func try_set_lobby_user_metadata():
	
	if current.update_metadata_thread != null:
		current.update_metadata_thread.wait_to_finish();
	current.update_metadata_thread = Thread.new();
	current.update_metadata_thread.start(current._try_set_lobby_user_metadata);
	return;

static func get_my_name() -> String:
	return Steam.getPersonaName();

static func _end_udp_blasting(t_success :bool):
	
	current.udp_blasting_start_time = -1.0;
	current.udp_blaster_peer.close();
	current.udp_blaster_peer = null;
	current.udp_blaster_server.close();
	current.udp_blaster_server = null;
	
	CommandPanel.add_line.call_deferred(CMD_NAME, "UDP blasting has ended %s" % ("successfully" if t_success else "in failure"));
	Steam.setLobbyMemberData(current.current_lobby, NEEDS_UDP_BLASTING_VAR, "false");
	return;

static func try_udp_blasting():
	
	Steam.setLobbyMemberData(current.current_lobby, NEEDS_UDP_BLASTING_VAR, "true");
	current.udp_blasting_start_time = Time.get_unix_time_from_system();
	return;

static func find_new_host():
	
	refresh_lobby_members();
	var members = current.lobby_members.duplicate();
	members.sort();
	var current_gameserver_host :String = Steam.getLobbyData(current.current_lobby, GAMESERVER_HOST_VAR);
	var new_gameserver_host :int = -1;
	if !current_gameserver_host.is_empty() && current_gameserver_host.is_valid_int():
		var gameserver_host = current_gameserver_host.to_int();
		if members.has(gameserver_host):
			new_gameserver_host = members[(members.find(gameserver_host) + 1) % members.size()];
		else:
			new_gameserver_host = members[0];
	else:
		new_gameserver_host = Steam.getLobbyOwner(current.current_lobby);
	if new_gameserver_host == Steam.current_app_id:
		current.is_hosting = true;
		SteamManager.try_set_lobby_gameserver();
	else:
		current.is_hosting = false;
		if Steam.getLobbyOwner(current.current_lobby) == Steam.current_app_id:
			Steam.setLobbyOwner(current.current_lobby, new_gameserver_host);
	return;

func _on_tree_exiting() -> void:
	
	if update_metadata_thread != null: 
		update_metadata_thread.wait_to_finish();
	if update_gameserver_thread != null: 
		update_gameserver_thread.wait_to_finish();
	return;
