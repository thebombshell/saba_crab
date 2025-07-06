class_name PointCheckCollisionPolygon extends CollisionPolygon3D

var vertices: PackedVector3Array = [];

func _ready():
	
	for vertex in polygon:
		
		vertices.append(to_global(Vector3(vertex.x, vertex.y, -depth)));
		vertices.append(to_global(Vector3(vertex.x, vertex.y, +depth)));
	return;

func get_closest_point(t_point: Vector3) -> Vector3:
	
	var point = Vector3.ZERO;
	var dist = 1000000.0;
	for i in polygon.size() - 1:
		var x = i * 2;
		var a = Geometry3D.get_closest_point_to_segment(t_point,
			vertices[(x + 0) % vertices.size()], vertices[(x + 2) % vertices.size()]);
		var b = Geometry3D.get_closest_point_to_segment(t_point,
			vertices[(x + 1) % vertices.size()], vertices[(x + 3) % vertices.size()]);
		var c = Geometry3D.get_closest_point_to_segment(t_point, a, b);
		var new_dist = c.distance_to(t_point);
		if new_dist < dist:
			point = c;
			dist = new_dist;
	return point;
