@tool
## [QPalette] resource saver
class_name QPaletteResourceSaver extends ResourceFormatSaver

func _get_recognized_extensions(resource: Resource) -> PackedStringArray:
	return ["lmp"]

func _recognize(resource: Resource) -> bool:
	return resource is QPalette

func _save(resource: Resource, path: String, flags: int) -> Error:
	if !(resource is QPalette): return ERR_INVALID_DATA
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null: return ERR_CANT_OPEN
	var lmp := resource as QPalette
	var data: PackedByteArray
	for color in lmp.colors:
		data.append_array([color.r8,color.g8,color.b8])
	file.store_buffer(data)
	file.close()
	resource.refresh_image()
	return OK
