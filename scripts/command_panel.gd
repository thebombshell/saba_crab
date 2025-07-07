class_name CommandPanel extends FoldablePanel

# this is a class for recieving commands and chat messages
# its both a handy debugging tool and a good feature to have if you plan to have
# people talking in multiplayer

const COMMAND_LABEL = preload("res://ui/command_label.tscn");

static var current: CommandPanel = null;
static var username: String = "Kaniki";

@onready var commands_box: VBoxContainer = $ScrollContainer/CommandsBox;
@onready var line_edit: LineEdit = $BottomBar/LineEdit;
@onready var submit_button: Button = $BottomBar/SubmitButton;
@onready var bottom_bar: HBoxContainer = $BottomBar;
@onready var scroll_container: ScrollContainer = $ScrollContainer

var _contains_focus :bool = false;
var contains_focus :bool:
	get: return _contains_focus;

var _is_mouse_over :bool = false;
var is_mouse_over :bool :
	get: return _is_mouse_over;

func _on_mouse_entered() -> void:
	_is_mouse_over = true;
	return;

func _on_mouse_exited() -> void:
	_is_mouse_over = false;
	return;

func _ready() -> void:
	
	if current != null:
		push_error("There is already a command panel");
	current = self;
	return;

@rpc("any_peer", "call_remote", "reliable", 0)
func add_line_internal(t_source :String, t_message :String):
	
	if t_message.length() > 240:
		t_message = t_message.substr(0, 240);
	
	var label = COMMAND_LABEL.instantiate();
	label.text = "[%s]:%s" % [t_source, t_message];
	commands_box.add_child(label);
	if commands_box.get_child_count() > 40:
		commands_box.get_child(0).queue_free.call_deferred();
	scroll_container.get_v_scroll_bar().value = scroll_container.get_v_scroll_bar().max_value;
	return;

static func add_line(t_source :String, t_message :String):
	
	if !is_instance_valid(current):
		return;
	current.add_line_internal(t_source, t_message);
	return;

static func string_from_args_array(t_arg_array :Array[String]) -> String:
	
	var output :String = "";
	for part in t_arg_array:
		output += part + " ";
	return output.substr(1, output.length() - 3);

func run_command(t_message :String):
	
	var args :PackedStringArray = t_message.split(" ");
	var final_args :Array[String] = [];
	var string_buffer :Array[String] = [];
	var command :String = args[0].substr(1);
	args.remove_at(0);
	for arg in args:
		if arg.begins_with("\"") || !string_buffer.is_empty():
			string_buffer.push_back(arg);
			if arg.ends_with("\""):
				final_args.push_back(string_from_args_array(string_buffer));
				string_buffer.clear();
		else:
			final_args.push_back(arg);
	print("command: " + command);
	print("args: " + str(final_args));
	return;

func on_submit_text(t_text: String) -> void:
	
	line_edit.text = "";
	if t_text.begins_with("\\"):
		add_line_internal("CMD", t_text);
		run_command(t_text);
	else:
		if multiplayer.has_multiplayer_peer():
			add_line_internal.rpc(username, t_text);
		else:
			add_line("LOCAL", t_text);
	return;

func _on_line_edit_text_submitted(t_text: String) -> void:
	
	on_submit_text(t_text);
	return;

func _on_submit_button_pressed() -> void:
	
	on_submit_text(line_edit.text);
	return;

func grab_line_focus():
	
	line_edit.grab_focus();
	return;

func _physics_process(t_delta: float) -> void:
	
	super(t_delta);
	bottom_bar.visible = !should_be_folded;
	
	_contains_focus = is_mouse_over || line_edit.has_focus();
	modulate = Color(1.0, 1.0, 1.0, 1.0 if contains_focus else 0.25);
	return;
