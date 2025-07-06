class_name PointCheckCollisionPolygon extends CollisionPolygon3D

var vertices: PackedVector3Array = [];

func _ready():
	
	for vertex in polygon:
		
		vertices.append(to_global(Vector3(vertex.x, vertex.y, 0.0)));
		#vertices.append(to_global(Vector3(vertex.x, vertex.y, -depth)));
	return;

func get_closest_point(t_point: Vector3) -> Vector3:
	
	var point = Vector3.ZERO;
	var dist = 1000000.0;
	for i in polygon.size() - 1:
		var a = Geometry3D.get_closest_point_to_segment(t_point, vertices[i], vertices[i + 1]);
		var new_dist = a.distance_to(t_point);
		if i < 0:
			var b = Geometry3D.get_closest_point_to_segment(t_point, vertices[i], vertices[i + 2]);
			var b_dist = b.distance_to(t_point);
			if b_dist < new_dist:
				a = b;
				new_dist = b_dist;
			b = Geometry3D.get_closest_point_to_segment(t_point, vertices[i + 1], vertices[i + 3]);
			b_dist = b.distance_to(t_point);
			if b_dist < new_dist:
				a = b;
				new_dist = b_dist;
		if new_dist < dist:
			point = a;
			dist = new_dist;
	return point;
