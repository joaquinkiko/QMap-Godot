@tool
class_name WADResourceSaver extends ResourceFormatSaver

func _get_recognized_extensions(resource: Resource) -> PackedStringArray:
	return ["wad", "WAD"]

func _recognize(resource: Resource) -> bool:
	return resource is WAD

func _save(resource: Resource, path: String, flags: int) -> Error:
	
	return OK
