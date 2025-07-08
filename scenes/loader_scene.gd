class_name LoaderScene extends Node

const SCENE_TABLE : Dictionary[StringName, String] = {
	
	"MenuScene": "uid://xsviydmib70d",
	"GameplayScene": "uid://bvmm651rsd5f"
};

const MASTER_SCENE_DOES_NOT_EXIST_ERROR_STRING = "The MasterScene instance has not been created yet.";
const LOAD_NAME_DOES_NOT_EXIST_FORMAT_STRING = "The scene \"%s\" does not exist in the MasterScene scene table.";
const LOAD_FAILED_FORMAT_STRING = "Failed to load \"%s\", with error: 0x%016X\n\"%s\"";
const RESOURCE_IS_NOT_A_PACKED_SCENE_FORMAT_STRING = "The resource loaded from \"%s\" is not a PackedScene.";

static var current : LoaderScene = null;

static var current_fyi_label :Label :
	get: return current.fyi_label if is_instance_valid(current) else null;

signal on_load_complete(t_path : String, t_root : Node);

var queued_load_paths : Array[String] = [];

#@onready var steam_manager: SteamManager = $SteamManager;
@onready var command_panel: CommandPanel = $CanvasLayer/CommandPanel/Panel;
@onready var fyi_label: Label = $CanvasLayer/FYILabel;

func _ready():
	
	if current != null:
		push_error("There should only be a single MasterScene");
	current = self;
	load_scene_by_name("MenuScene");
	multiplayer.multiplayer_peer = null;
	return;

static func show_scene(t_scene_name: String):
	
	for child in current.get_children():
		
		current.process_mode = (Node.PROCESS_MODE_PAUSABLE
			if child.name == t_scene_name else Node.PROCESS_MODE_DISABLED);
	return;

static func load_failed_error(t_path : String, t_error : int):
	
	push_error(LOAD_FAILED_FORMAT_STRING % [t_path, t_error, error_string(t_error)]);
	return;

static func load_scene_by_name(t_name : StringName):
	
	if current == null:
		push_error(MASTER_SCENE_DOES_NOT_EXIST_ERROR_STRING);
		return;
	current.load_scene_by_name_internal(t_name);
	return;

static func load_scene_by_uid(t_name : StringName):
	
	if current == null:
		push_error(MASTER_SCENE_DOES_NOT_EXIST_ERROR_STRING);
		return;
	current.load_scene_by_uid_internal(t_name);
	return;

static func load_scene(t_name : StringName):
	
	if current == null:
		push_error(MASTER_SCENE_DOES_NOT_EXIST_ERROR_STRING);
		return;
	current.load_scene_internal(t_name);
	return;

func load_scene_by_name_internal(t_name : StringName):
	
	if !SCENE_TABLE.has(t_name):
		push_error(LOAD_NAME_DOES_NOT_EXIST_FORMAT_STRING % t_name);
	var uid = SCENE_TABLE[t_name];
	load_scene_by_uid_internal(uid);
	return;

func load_scene_by_uid_internal(t_uid : Variant):
	
	if t_uid is not String and t_uid is not int:
		push_error("UID is invalid");
		return;
	var uid : int = t_uid if t_uid is int else ResourceUID.text_to_id(t_uid);
	var path = ResourceUID.get_id_path(uid);
	load_scene_internal(path);
	return;

func load_scene_internal(t_path):
	
	if queued_load_paths.has(t_path):
		load_failed_error(t_path, ERR_ALREADY_EXISTS);
		return;
	var error = ResourceLoader.load_threaded_request(t_path, "", false, ResourceLoader.CACHE_MODE_IGNORE);
	if error != OK:
		load_failed_error(t_path, error);
	else:
		queued_load_paths.push_back(t_path);
	return;

func handle_loaded_scene(t_path : String) -> Error:
	
	var resource = ResourceLoader.load_threaded_get(t_path);
	if resource is not PackedScene:
		push_error(RESOURCE_IS_NOT_A_PACKED_SCENE_FORMAT_STRING % t_path);
		return ERR_CANT_ACQUIRE_RESOURCE;
	var node = resource.instantiate();
	add_child(node);
	on_load_complete.emit.call_deferred(t_path, node);
	return OK;

func process_queued_load_paths():
	
	var completed_paths : Array[String] = [];
	for t_path in queued_load_paths:
		
		var status = ResourceLoader.load_threaded_get_status(t_path);
		match status:
			ResourceLoader.THREAD_LOAD_IN_PROGRESS:
				continue;
			ResourceLoader.THREAD_LOAD_FAILED:
				load_failed_error(t_path, ERR_PARSE_ERROR);
				completed_paths.push_back(t_path);
			ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
				load_failed_error(t_path, ERR_INVALID_DATA);
				completed_paths.push_back(t_path);
			ResourceLoader.THREAD_LOAD_LOADED:
				completed_paths.push_back(t_path);
				handle_loaded_scene(t_path);
	for t_path in completed_paths:
		queued_load_paths.erase(t_path);
	return;

func _physics_process(_delta : float) -> void:
	
	if !queued_load_paths.is_empty():
		process_queued_load_paths();
	
	if Input.is_action_just_pressed("enable_command_console") && !command_panel.contains_focus:
		command_panel.visible = !command_panel.visible;
	
	if Input.is_action_just_pressed("initiate_chat") && !command_panel.contains_focus:
		command_panel.visible = true;
		command_panel.should_be_folded = false;
		command_panel.grab_line_focus();
	return;
