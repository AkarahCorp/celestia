extends Resource
class_name Directory

@export var path: String
@export var files: Array[String]
@export var directories: Array[Directory]

func _init(p_path: String = "", p_files: Array[String] = [], p_dirs: Array[Directory] = []) -> void:
	path = p_path
	files = p_files
	directories = p_dirs

func to_pretty() -> Dictionary:
	return {
		"path"=path,
		"files"=files,
		"directories"=directories
	}

static func create(path: String):
	var dir = DirAccess.open(path)
	var directories: Array[Directory] = []
	var files: Array[String] = []
	if not dir:
		printerr("Failed to open directory: %s" % path)
		return null
	dir.set_include_hidden(true)
	var err: int = dir.list_dir_begin()
	if err != OK:
		printerr("dir listing failed")
		return
	while true:
		var name: String = dir.get_next()
		if name == "": # End of listing
			break
		if dir.current_is_dir():
			directories.append(create("%s/%s" % [path, name]))
		else:
			files.append(name)
	return Directory.new(path, files, directories)
