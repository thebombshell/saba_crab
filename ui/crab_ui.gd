class_name CrabUI extends CanvasLayer

@onready var dialog_panel: Panel = $DialogPanel;
@onready var dialog_label: AutoLabel = $DialogPanel/DialogLabel;

var lock_dialog_open = false;
var dialog_alpha = 0.0;

func push_message(t_dialog: String, t_lock_open: bool = false):
	
	lock_dialog_open = t_lock_open;
	dialog_label.text = t_dialog;
	dialog_alpha = 3.0;
	return;

func process_dialog(t_delta: float) -> void:
	
	if lock_dialog_open:
		dialog_alpha = 1.0;
	dialog_alpha -= t_delta;
	dialog_panel.modulate = Color(1.0, 1.0, 1.0, 0.8 * clamp(dialog_alpha, 0.0, 1.0));
	return;

func _physics_process(t_delta: float) -> void:
	
	process_dialog(t_delta);
	return;
