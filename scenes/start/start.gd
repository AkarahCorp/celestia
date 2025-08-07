extends VBoxContainer

var editor = preload("res://scenes/editor/editor.tscn")
var dialog: FileDialog
func _ready() -> void:
	DisplayServer.window_set_min_size(Vector2i(400, 300))


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func open_existing_datapack() -> void:
	dialog = FileDialog.new()
	dialog.set_file_mode(FileDialog.FILE_MODE_OPEN_DIR)
	dialog.set_access(FileDialog.ACCESS_FILESYSTEM)
	dialog.dir_selected.connect(open_directory)
	dialog.set_use_native_dialog(true)
	add_child(dialog)
	dialog.show()
	
func open_directory(dir: String):
	dialog.queue_free()
	var directory = Directory.create(dir)
	var inst = editor.instantiate()
	inst.directory = directory
	hide()
	get_tree().root.add_child(inst)
	queue_free()
