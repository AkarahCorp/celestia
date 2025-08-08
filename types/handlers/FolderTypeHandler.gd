## A folder type handler.
##
## Used for converting folder paths into known folder types.
extends Resource
class_name FolderTypeHandler

## The pattern of the folder type, in glob format.
@export var pattern: String
## The icon, shown on the tree view.
@export var icon: Texture2D
## The enum value for the type.
@export var type: Enum.FolderType

func _init(
		p_pattern: String = "",
		p_icon: Texture2D = PlaceholderTexture2D.new(),
		p_type: Enum.FolderType = Enum.FolderType.UNKNOWN
	) -> void:
	pattern = p_pattern
	icon = p_icon
	type = p_type
