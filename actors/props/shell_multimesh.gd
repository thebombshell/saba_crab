class_name ShellMultimesh extends MultiMeshInstance3D

func _process(_delta: float):
	
	Shell.fill_mesh(multimesh);
	return;
