class_name AmbienceTrackerActor extends Node3D

@onready var audio_stream_player_3d: AudioStreamPlayer3D = $AudioStreamPlayer3D;

@export var ambience_names: Dictionary[String, int] = {};
@export var ambience_max_volumes: Dictionary[String, float] = {};
@export var ambience_fade_distance: Dictionary[String, float] = {};
@export var default_fade_distance: float = 100.0;

var listener_node: Camera3D:
	get: return get_viewport().get_camera_3d();

func find_nearest_distance(t_area: Area3D) -> float:
	
	if !t_area.has_node("CollisionPolygon3D"):
		return 1000000.0;
	var collision_polygon: PointCheckCollisionPolygon = t_area.get_node("CollisionPolygon3D");
	return collision_polygon.get_closest_point(listener_node.global_position).distance_to(
		listener_node.global_position);

func get_fade_distance(t_name: String):
	
	return ambience_fade_distance[t_name] if ambience_fade_distance.has(t_name) else default_fade_distance;

func get_max_volume(t_name: String):
	
	return ambience_max_volumes[t_name] if ambience_max_volumes.has(t_name) else -14.0;

func _physics_process(t_delta: float) -> void:
	
	# need a listener to reference
	if !is_instance_valid(listener_node):
		return;
	
	# need an audio stream synchronized to modify stream volumes
	if audio_stream_player_3d.stream is not AudioStreamSynchronized:
		return;
	
	var stream: AudioStreamSynchronized = audio_stream_player_3d.stream;
	for t_name in ambience_names:
		if !has_node(t_name):
			continue;
		var area: Area3D = get_node(t_name);
		var id = ambience_names[t_name];
		var max_value = get_max_volume(t_name);
		if area.has_overlapping_areas():
			stream.set_sync_stream_volume(id, max_value);
			#print("%s:%d" % [t_name, max_value]);
		else:
			var alpha = clamp(smoothstep(0.0, get_fade_distance(t_name),
				find_nearest_distance(area)), 0.0, 1.0);
			var value = lerp(max_value, -60.0, alpha);
			var old_value = stream.get_sync_stream_volume(id);
			if value <= -60.0:
				stream.set_sync_stream_volume(id, old_value - t_delta);
			else:
				stream.set_sync_stream_volume(id, value);
			#print("%s:%d" % [t_name, value]);
	return;
