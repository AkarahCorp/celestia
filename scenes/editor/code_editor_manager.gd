extends VBoxContainer

var undo_redo: UndoRedo
var tabs: TabBar
var editors: VBoxContainer
var open_files: Dictionary = {}
var file_cache: Dictionary = {}
var placeholder: CenterContainer

func _ready() -> void:
	tabs = %Tabs
	editors = %Editors
	placeholder = %Placeholder
	tabs.tab_changed.connect(_on_tab_changed)
	tabs.tab_close_pressed.connect(_on_tab_close_pressed)

func open_file(path: String, type: String) -> void:
	if open_files.has(path):
		tabs.current_tab = open_files[path].tab_index
		return

	placeholder.hide()

	var editor
	match type:
		"item", "rule", "script", "unknown":
			editor = CodeEdit.new()
			editor.set_script(preload("res://scenes/editor/CodeEditorHandler.gd"))
			editor.file_path = path
			editor.undo_redo = undo_redo
			if file_cache.has(path):
				editor.text = file_cache[path]
			else:
				var file = FileAccess.open(path, FileAccess.READ)
				if file:
					var text = file.get_as_text()
					editor.text = text
					file_cache[path] = text
			editor.size_flags_vertical = Control.SIZE_EXPAND_FILL
			editor.text_changed_since_save.connect(_on_text_changed_since_save.bind(path))
		_:
			printerr("Unsupported file type: %s" % type)
			return

	var tab_index = tabs.get_tab_count()
	tabs.add_tab(path.get_file())
	tabs.set_tab_close_display_policy(TabBar.CLOSE_BUTTON_SHOW_ALWAYS)
	editors.add_child(editor)
	open_files[path] = {
		"editor": editor,
		"tab_index": tab_index,
		"type": type
	}
	tabs.current_tab = tab_index


func _on_tab_changed(tab: int) -> void:
	if tab < 0 or tab >= tabs.get_tab_count():
		return
	for path in open_files:
		var file_data = open_files[path]
		if file_data.tab_index == tab:
			file_data.editor.show()
		else:
			file_data.editor.hide()


func _on_tab_close_pressed(tab: int) -> void:
	var path_to_close = ""
	for path in open_files:
		if open_files[path].tab_index == tab:
			path_to_close = path
			break

	if path_to_close != "":
		var file_data = open_files[path_to_close]
		open_files.erase(path_to_close)
		file_data.editor.queue_free()
		
		for path in open_files:
			if open_files[path].tab_index > tab:
				open_files[path].tab_index -= 1

		tabs.remove_tab(tab)

		if open_files.is_empty():
			placeholder.show()

func _on_text_changed_since_save(is_dirty: bool, path: String) -> void:
	var tab_index = open_files[path].tab_index
	var tab_text = tabs.get_tab_title(tab_index)
	if is_dirty and not tab_text.ends_with("*"):
		tabs.set_tab_title(tab_index, tab_text + "*")
	elif not is_dirty and tab_text.ends_with("*"):
		tabs.set_tab_title(tab_index, tab_text.trim_suffix("*"))
