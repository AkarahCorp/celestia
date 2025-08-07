extends CodeEdit

signal text_changed_since_save(is_dirty: bool)

var undo_redo: UndoRedo
var file_path: String
var text_before_change: String

func _ready() -> void:
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
		undo_redo.create_action("Edit %s" % file_path.get_file())
		undo_redo.add_do_method(set.bind("text", text))
		undo_redo.add_undo_method(set.bind("text", text_before_change))
		undo_redo.commit_action()

func _on_text_changed() -> void:
	text_changed_since_save.emit(true)


func _save_file() -> void:
	var file := FileAccess.open(file_path, FileAccess.WRITE)
	if file:
		file.store_string(text)
