extends CodeEdit

signal text_changed_since_save(is_dirty: bool)

var file_path: String
var text_before_change: String
const KEYWORDS = [
	"if", "else", "local", "repeat", "function", "foreach", "in", "break", "continue", "return", "struct", "new", "event", "as"
]
static func create_syntax_highlighter() -> CodeHighlighter:
	var highlighter = CodeHighlighter.new()
	highlighter.function_color = Color(0.3317, 0.5305, 0.7422, 1.0)
	highlighter.symbol_color = Color(0.7389, 0.7859, 0.8359, 1.0)
	highlighter.number_color = Color(0.5654, 0.8945, 0.7403, 1.0)
	highlighter.member_variable_color = Color(0.8819, 0.8906, 0.7323, 1.0)
	highlighter.add_color_region("$\"", "\"", Color(0.6658, 0.9062, 0.5012, 1.0))
	highlighter.add_color_region("\"", "\"", Color(0.9355, 0.957, 0.5624, 1.0))
	for keyword in KEYWORDS:
		highlighter.add_keyword_color(keyword, Color(0.8984, 0.3527, 0.3527, 1.0))
	return highlighter

func _ready() -> void:
	auto_brace_completion_highlight_matching = true
	syntax_highlighter = create_syntax_highlighter()
	text_changed.connect(_on_text_changed)
	focus_entered.connect(func(): text_before_change = text)
	focus_exited.connect(_on_focus_exited)


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("file_save"):
		_save_file()
		text_changed_since_save.emit(false)
		get_viewport().set_input_as_handled()

func _on_focus_exited() -> void:
	if text != text_before_change:
		Global.undo_redo.create_action("Edit %s" % file_path.get_file())
		Global.undo_redo.add_do_method(set.bind("text", text))
		Global.undo_redo.add_undo_method(set.bind("text", text_before_change))
		Global.undo_redo.commit_action()

func _on_text_changed() -> void:
	text_changed_since_save.emit(true)


func _save_file() -> void:
	var file := FileAccess.open(file_path, FileAccess.WRITE)
	if file:
		file.store_string(text)
