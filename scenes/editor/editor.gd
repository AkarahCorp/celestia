extends VBoxContainer

enum TreeColumn {
	TEXT
}

var directory: Directory
var filetree: Tree
var undo_redo = UndoRedo.new()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	filetree = %FileTree as Tree
	var split = directory.path.rsplit("/", false, 1)
	DisplayServer.window_set_title("Celestia - %s" % split[1])
	var root = filetree.create_item()
	root.set_icon(TreeColumn.TEXT, preload("res://assets/icons/folder.svg"))
	root.set_text(TreeColumn.TEXT, split[1])
	root.set_meta("path", directory.path)
	_create_file_tree(root, directory)

	filetree.item_activated.connect(_on_item_activated)
	filetree.item_mouse_selected.connect(_on_item_mouse_selected)
	filetree.item_edited.connect(_on_item_edited)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_undo"):
		if undo_redo.has_undo():
			undo_redo.undo()
	elif event.is_action_pressed("ui_redo"):
		if undo_redo.has_redo():
			undo_redo.redo()


func _create_file_tree(parent: TreeItem, dir: Directory) -> void:
	for d in dir.directories:
		var item = filetree.create_item(parent)
		item.set_icon(TreeColumn.TEXT, preload("res://assets/icons/folder.svg"))
		item.set_text(TreeColumn.TEXT, d.path.rsplit("/", false, 1)[1])
		item.set_meta("path", d.path)
		_create_file_tree(item, d)
	for f in dir.files:
		var item = filetree.create_item(parent)
		item.set_icon(TreeColumn.TEXT, preload("res://assets/icons/text_file.svg"))
		item.set_text(TreeColumn.TEXT, f)
		item.set_meta("path", "%s/%s" % [dir.path, f])


func _on_item_activated() -> void:
	var selected = filetree.get_selected()
	if selected:
		selected.set_editable(TreeColumn.TEXT, true)
		filetree.edit_selected()


func _on_item_edited() -> void:
	var item = filetree.get_edited()
	if not item:
		return

	item.set_editable(TreeColumn.TEXT, false)
	var new_text = item.get_text(TreeColumn.TEXT)
	var old_path = item.get_meta("path")
	var old_name = old_path.get_file()

	if new_text == old_name:
		return

	var new_path = old_path.get_base_dir().path_join(new_text)

	undo_redo.create_action("Rename")
	undo_redo.add_do_method(_rename_file.bind(old_path, new_path))
	undo_redo.add_do_method(item.set_meta.bind("path", new_path))
	undo_redo.add_do_method(item.set_text.bind(TreeColumn.TEXT, new_text))
	undo_redo.add_undo_method(_rename_file.bind(new_path, old_path))
	undo_redo.add_undo_method(item.set_meta.bind("path", old_path))
	undo_redo.add_undo_method(item.set_text.bind(TreeColumn.TEXT, old_name))
	undo_redo.commit_action()


func _rename_file(from: String, to: String) -> void:
	var err = DirAccess.rename_absolute(from, to)
	if err != OK:
		printerr("Failed to rename %s to %s with error code %s" % [from, to, err])


func _on_item_mouse_selected(position: Vector2, mouse_button_index: int) -> void:
	if mouse_button_index == MOUSE_BUTTON_LEFT:
		var selected = filetree.get_selected()
		if selected:
			var path = selected.get_meta("path")
