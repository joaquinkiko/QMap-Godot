class_name QMapResourceSaver extends ResourceFormatSaver

func _get_recognized_extensions(resource: Resource) -> PackedStringArray:
	return ["map", "MAP"]

func _recognize(resource: Resource) -> bool:
	return resource is QMap

func _save(resource: Resource, path: String, flags: int) -> Error:
	
	return OK
