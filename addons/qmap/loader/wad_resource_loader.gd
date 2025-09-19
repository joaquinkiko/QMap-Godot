@tool
class_name WADResourceLoader extends ResourceFormatLoader

func _get_recognized_extensions() -> PackedStringArray:
	return ["wad", "WAD"]

func _handles_type(type: StringName) -> bool:
	return ClassDB.is_parent_class(type, "Resource")

func _get_resource_type(path: String) -> String:
	if path.get_extension().to_lower() == "wad": return "Resource"
	else: return ""

func _load(path: String, original_path: String, use_sub_threads: bool, cache_mode: int) -> Variant:
	var resource := WAD.new()
	var data = FileAccess.get_file_as_bytes(path)
	if data.size() < 12: 
		printerr("Error loading data from '%s'"%path)
		return resource
	match data.slice(0, 4).get_string_from_ascii():
		"WAD2": resource.format = WAD.WadFormat.Q_FORMAT
		"WAD3": resource.format = WAD.WadFormat.HL_FORMAT
		_:
			printerr("Cannot load '%s': is not WAD2 or WAD3 format"%path)
			return resource
	var entry_count: int = data.decode_u32(4)
	var dir_offset: int = data.decode_u32(8)
	return resource
	return resource
