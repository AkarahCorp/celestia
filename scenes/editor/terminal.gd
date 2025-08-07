extends VBoxContainer

var current_directory: String
var terminal_text: Label
var terminal_input: LineEdit
var scroll_container: ScrollContainer

func _ready() -> void:
	terminal_text = %TerminalText
	terminal_input = %TerminalInput
	scroll_container = get_node("ScrollContainer")

	terminal_input.text_submitted.connect(_on_command_submitted)
	terminal_input.grab_focus()

func set_cwd(path: String) -> void:
	current_directory = path
	terminal_text.text = "cterm %s\n\n" % ProjectSettings.get("application/config/version")
	_update_prompt()

func _on_command_submitted(command: String) -> void:
	if command.is_empty():
		return

	_append_to_terminal(terminal_input.placeholder_text + command)
	terminal_input.clear()

	var parts = command.strip_edges().split(" ", false, 1)
	var executable = parts[0]

	if executable == "cd":
		var new_dir = ""
		if parts.size() > 1:
			new_dir = parts[1].strip_edges()
		else:
			new_dir = OS.get_environment("USERPROFILE") if OS.has_feature("windows") else OS.get_environment("HOME")

		var dir_access = DirAccess.open(current_directory)
		var err = dir_access.change_dir(new_dir)

		if err == OK:
			current_directory = dir_access.get_current_dir()
		else:
			_append_to_terminal("cd: no such file or directory: %s" % new_dir)

	elif executable == "clear":
		terminal_text.text = ""
	else:
		var output = execute(current_directory, command)
		_append_to_terminal(output)

	_update_prompt()
	await get_tree().process_frame
	scroll_container.scroll_vertical = scroll_container.get_v_scroll_bar().max_value


func _update_prompt() -> void:
	var home_dir =  OS.get_environment("USERPROFILE") if OS.has_feature("windows") else OS.get_environment("HOME")
	var prompt_dir = current_directory.replace(home_dir, "~")
	terminal_input.placeholder_text = "%s $ " % prompt_dir

func _append_to_terminal(text: String) -> void:
	terminal_text.text += text + "\n"

func execute(path: String, command: String) -> String:
	var output_array: Array = []
	var exit_code: int = -1
	
	var shell_path: String
	var shell_args: Array[String]
	var cmd: String = "cd %s && %s" % [path, command]
	
	if OS.get_name() == "Windows":
		shell_path = "cmd.exe"
		shell_args = ["/c", command]
	else:
		shell_path = "/bin/sh"
		shell_args = ["-c", command]

	exit_code = OS.execute(shell_path, shell_args, output_array, true, false)
	
	if exit_code != 0:
		return "%s: returned code %s" % [command, exit_code]
	
	return "\n".join(output_array)
