@tool
class_name QPaletteResourceSaver extends ResourceFormatSaver

func _get_recognized_extensions(resource: Resource) -> PackedStringArray:
	return ["lmp", "LMP"]

func _recognize(resource: Resource) -> bool:
	return resource is QPalette

func _save(resource: Resource, path: String, flags: int) -> Error:
	
	return OK
