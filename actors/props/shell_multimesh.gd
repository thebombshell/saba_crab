class_name ShellManager extends MultiMeshInstance3D

static var current: ShellManager = null;
static var current_shell_count: int:
	get: return current.collected_shell_count if is_instance_valid(current) else 0;
@export var collected_shell_count: int = 0;

static func collect_shell():
	
	if is_instance_valid(current):
		current.collect_shell_internal();
	return;

func collect_shell_internal():
	
	collected_shell_count += 1;
	return;

func _ready():
	
	if is_instance_valid(current):
		push_error("There should only be a single Shell Manager");
	current = self;
	return;

func _process(_delta: float):
	
	Shell.fill_mesh(multimesh);
	return;
