class_name MultiplayerSpawnPoint extends Node3D

@export var spawn_actor: PackedScene = null;
@export var spawn_immediately: bool = true;
@export var spawn_once: bool = true;
@export var spawn_data: Dictionary[String, Variant] = {};

@onready var uid: int = ResourceLoader.get_resource_uid(spawn_actor.resource_path);

var actor_spawner: MultiplayerActorSpawner:
	get: 
		var parent = get_parent();
		if parent is not MultiplayerActorSpawner:
			push_error("Parent of MultiplayerSpawnPoint needs to be a MultiplayerActorSpawner");
			return null;
		return parent;

func spawn(t_data: Variant = null):
	
	if spawn_actor == null:
		return;
	var data = {
		"uid": uid,
		"data": spawn_data if t_data == null else t_data,
		"transform": global_transform
		};
	var node = actor_spawner.try_spawn(data);
	if spawn_once:
		queue_free.call_deferred();
	return node;

func _ready():
	
	hide();
	if spawn_actor == null:
		return;
	actor_spawner.register(spawn_actor);
	if spawn_immediately:
		spawn.call_deferred();
	return;
