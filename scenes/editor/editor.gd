extends VBoxContainer

enum TreeColumn {
	TEXT
}

const UNKNOWN_FOLDER_ICON = preload("res://assets/icons/folders/unknown.svg")
const UNKNOWN_FILE_ICON = preload("res://assets/icons/files/unknown.svg")

const FILE_TYPE_HANDLERS: Array[Dictionary] = [
	{
		"pattern": "/data/*/engine/item/*.json",
		"icon": preload("res://assets/icons/files/item.svg"),
		"type": "item"
	},
	{
		"pattern": "/data/*/engine/rule/*.json",
		"icon": preload("res://assets/icons/files/rule.svg"),
		"type": "rule"
	},
	{
		"pattern": "*.aka",
		"icon": preload("res://assets/icons/files/script.svg"),
		"type": "script"
	}
]
const FOLDER_TYPE_HANDLERS: Array[Dictionary] = [
	{
		"pattern": "/data/*/engine/rule*",
		"icon": preload("res://assets/icons/folders/rule.svg"),
		"type": "rule_folder"
	}
]
const hidden_files: Array[String] = [
	"/.gitattributes",
	"/.git"
]

var directory: Directory
var filetree: Tree
var undo_redo = UndoRedo.new()

var code_editor_manager: Node

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	filetree = %FileTree as Tree
	code_editor_manager = %CodeEditorManager
	code_editor_manager.undo_redo = undo_redo
	var split = directory.path.rsplit("/", false, 1)
	DisplayServer.window_set_title("Celestia - %s" % split[1])
	var root = filetree.create_item()
	root.set_icon(TreeColumn.TEXT, UNKNOWN_FOLDER_ICON)
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
		var relative_path = d.path.replace(directory.path, "")
		if relative_path in hidden_files:
			continue
		var item = filetree.create_item(parent)
		item.set_icon(TreeColumn.TEXT, UNKNOWN_FOLDER_ICON)
		item.set_text(TreeColumn.TEXT, d.path.rsplit("/", false, 1)[1])
		item.set_meta("path", d.path)
		
		var handled = false
		for handler in FOLDER_TYPE_HANDLERS:
			if relative_path.match(handler.pattern):
				item.set_icon(TreeColumn.TEXT, handler.icon)
				item.set_meta("type", handler.type)
				handled = true
				break
		
		if not handled:
			item.set_icon(TreeColumn.TEXT, UNKNOWN_FOLDER_ICON)
			item.set_meta("type", "unknown_folder")
		_create_file_tree(item, d)
	for f in dir.files:
		var path = "%s/%s" % [dir.path, f]
		var relative_path = path.replace(directory.path, "")
		if relative_path in hidden_files:
			continue
		var item = filetree.create_item(parent)
		var handled = false
		for handler in FILE_TYPE_HANDLERS:
			if relative_path.match(handler.pattern):
				item.set_icon(TreeColumn.TEXT, handler.icon)
				item.set_meta("type", handler.type)
				handled = true
				break
		
		if not handled:
			item.set_icon(TreeColumn.TEXT, UNKNOWN_FILE_ICON)
			item.set_meta("type", "unknown")

		item.set_text(TreeColumn.TEXT, f)
		item.set_meta("path", path)


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
			if not DirAccess.dir_exists_absolute(path):
				var type = selected.get_meta("type")
				code_editor_manager.open_file(path, type)
