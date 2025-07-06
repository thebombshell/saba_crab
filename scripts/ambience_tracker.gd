class_name AmbienceTrackerActor extends Node3D

@onready var audio_stream_player_3d: AudioStreamPlayer3D = $AudioStreamPlayer3D;
@onready var mesh_instance_3d: MeshInstance3D = $MeshInstance3D

@export var listener_node: Node3D = null;
@export var ambience_names: Dictionary[String, int] = {};
@export var ambience_fade_distance: Dictionary[String, float] = {};
@export var default_fade_distance: float = 100.0;

func find_nearest_distance(t_area: Area3D) -> float:
	
	if !t_area.has_node("CollisionPolygon3D"):
		return 1000000.0;
	var collision_polygon: PointCheckCollisionPolygon = t_area.get_node("CollisionPolygon3D");
	return collision_polygon.get_closest_point(listener_node.global_position).distance_to(
		listener_node.global_position);

func get_fade_distance(t_name: String):
	
	return ambience_fade_distance[t_name] if ambience_fade_distance.has(t_name) else default_fade_distance;

func _physics_process(_delta: float) -> void:
	
	# need a listener to reference
	if !is_instance_valid(listener_node):
		return;
	
	mesh_instance_3d.global_position = (get_node("Sea/CollisionPolygon3D").get_closest_point(listener_node.global_position));
	
	# need a
	if audio_stream_player_3d.stream is not AudioStreamSynchronized:
		return;
	
	var stream: AudioStreamSynchronized = audio_stream_player_3d.stream;
	for t_name in ambience_names:
		if !has_node(t_name):
			continue;
		var area: Area3D = get_node(t_name);
		var id = ambience_names[t_name];
		if area.has_overlapping_bodies():
			stream.set_sync_stream_volume(id, 0.0);
		else:
			var alpha = clamp(smoothstep(0.0, get_fade_distance(t_name),
				find_nearest_distance(area)), 0.0, 1.0);
			stream.set_sync_stream_volume(id, lerp(0.0, -60.0, alpha));
	return;
