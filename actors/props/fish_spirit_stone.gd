class_name FishSpiritStone extends StaticBody3D

signal on_activate_stone(t_crab: CrabActor);
signal on_activate_stone_nocrab();

@onready var activation_area: Area3D = $ActivationArea;
@onready var stone_mesh: MeshInstance3D = $StoneMesh;
@onready var glow_mesh: MeshInstance3D = $GlowMesh;

const ACTIVATION_COLOR: Color = Color.DODGER_BLUE;
const HIGHLIGHT_COLOR: Color = Color.CORAL;

@export var message_queue: PackedStringArray = [];

var color: Color = Color.TRANSPARENT;
var activation_time = 0.0;
var highlight_time = 0.0;
var can_activate: bool:
	get: return activation_time <= 0.0;
var crab: CrabActor = null;

var message_index: int = 0;

func end_dialog():
	
	if is_instance_valid(crab):
		crab.crab_ui.lock_dialog_open = false;
	crab = null;
	return;

func push_message():
	
	if !is_instance_valid(crab) || message_queue.is_empty():
		return;
	crab.crab_ui.push_message(message_queue[message_index % message_queue.size()], true);
	message_index += 1;
	return;

func activate(t_crab: CrabActor):
	
	crab = t_crab;
	activation_time = 1.0;
	message_index = 0;
	on_activate_stone.emit(t_crab);
	on_activate_stone_nocrab.emit();
	return;

func soft_activate():
	
	activation_time = 1.0;
	return;

func highlight():
	
	highlight_time = 1.0;
	return;

func try_activate(t_crab: CrabActor):
	
	if can_activate:
		activate(t_crab);
	return;

func try_soft_activate():
	
	if can_activate:
		soft_activate();
	return;

func check_for_activation():
	
	var has_crab = false;
	var is_crab_spinning = false;
	var is_local_crab_spinning = false;
	var t_crab: CrabActor = null;
	for body in activation_area.get_overlapping_bodies():
		if body is CrabActor:
			has_crab = true;
			if body.is_spinning:
				is_crab_spinning = true;
				if body.is_locally_processible:
					is_local_crab_spinning = true;
					t_crab = body;
					break;
	if is_local_crab_spinning && is_instance_valid(t_crab):
		try_activate(t_crab);
	elif is_crab_spinning:
		try_soft_activate();
	elif has_crab:
		highlight();
	return;

func _ready():
	
	glow_mesh.material_override = glow_mesh.material_override.duplicate();
	return;

func process_activation(t_delta: float) -> void:
	
	activation_time -= t_delta;
	if can_activate && activation_area.has_overlapping_bodies():
		check_for_activation();
	return;

func process_highlight(t_delta: float) -> void:
	
	highlight_time -= t_delta;
	var target_color: Color = ACTIVATION_COLOR if activation_time > highlight_time else HIGHLIGHT_COLOR;
	target_color.a = clamp(max(activation_time, highlight_time), 0.0, 1.0);
	color = color.lerp(target_color, t_delta * 4.0);
	glow_mesh.material_override.set("albedo_color", color);
	glow_mesh.material_override.set("emission", color);
	return;

func _physics_process(t_delta: float) -> void:
	
	process_activation(t_delta);
	process_highlight(t_delta);
	return;
