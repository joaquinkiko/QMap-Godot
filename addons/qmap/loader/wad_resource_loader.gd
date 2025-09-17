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
	
	return resource
