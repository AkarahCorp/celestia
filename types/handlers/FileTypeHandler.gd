## A file type handler.
##
## Used for converting file names into known file types.
extends Resource
class_name FileTypeHandler

## The pattern of the file type, in glob format. 
## For simple file types, this can be e.g. [code]*.filetype[/code].
@export var pattern: String
## The icon, shown on the tree view.
@export var icon: Texture2D
## The enum value for the type.
@export var type: Enum.FileType

func _init(
		p_pattern: String = "",
		p_icon: Texture2D = PlaceholderTexture2D.new(),
		p_type: Enum.FileType = Enum.FileType.UNKNOWN
	) -> void:
	pattern = p_pattern
	icon = p_icon
	type = p_type
