@tool
## [QPalette] resource loader
class_name QPaletteResourceLoader extends ResourceFormatLoader

func _get_recognized_extensions() -> PackedStringArray:
	return ["lmp"]

func _handles_type(type: StringName) -> bool:
	return ClassDB.is_parent_class(type, "ImageTexture")

func _get_resource_type(path: String) -> String:
	if path.get_extension().to_lower() == "lmp": return "ImageTexture"
	else: return ""

func _load(path: String, original_path: String, use_sub_threads: bool, cache_mode: int) -> Variant:
	var resource := QPalette.new()
	var data = FileAccess.get_file_as_bytes(path)
	if data.is_empty(): return resource
	resource.colors.resize(data.size() / 3)
	for n in resource.colors.size():
		if n * 3 + 2 >= data.size(): break
		resource.colors[n].r8 = data[n * 3]
		resource.colors[n].g8 = data[n * 3 + 1]
		resource.colors[n].b8 = data[n * 3 + 2]
	resource.refresh_image()
	return resource
