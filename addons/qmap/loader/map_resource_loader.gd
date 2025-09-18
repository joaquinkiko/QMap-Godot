class_name QMapResourceLoader extends ResourceFormatLoader

func _get_recognized_extensions() -> PackedStringArray:
	return ["map", "MAP"]

func _handles_type(type: StringName) -> bool:
	return ClassDB.is_parent_class(type, "Resource")

func _get_resource_type(path: String) -> String:
	if path.get_extension().to_lower() == "map": return "Resource"
	else: return ""

func _load(path: String, original_path: String, use_sub_threads: bool, cache_mode: int) -> Variant:
	var resource := QMap.new()
	var contents: String
	# Parse header
	for line: String in FileAccess.get_file_as_string(path).split("\n", false):
		if line.contains("// entity 0"): break
		if line.split("//", true, 1).size() > 1:
			if !resource.header.is_empty(): resource.header += "\n"
			resource.header += line.split("//", true, 1)[1].trim_prefix(" ")
		elif line.is_empty(): continue
		else: break
	# Remove comments for parsing, and temporarily replace {} in strings with ¡¿
	for line: String in FileAccess.get_file_as_string(path).split("\n", false):
		if line.contains("//"): line = line.split("//", true)[0]
		if line.is_empty(): continue
		else: 
			line = line.replace('"{', '"¡').replace('}"','¿"')
			contents += line + "\n"
	# Compile regex
	var entity_pattern = RegEx.new()
	entity_pattern.compile(r"\{([^{]*)((?:[^{}]|\{(?:[^{}])*\})*)\}")
	var properties_pattern = RegEx.new()
	properties_pattern.compile(r'(?:"([^"]*)"\s*("[^"]*"|\w*))')
	var brush_pattern = RegEx.new()
	brush_pattern.compile(r"{([^}]*)")
	var plane_pattern = RegEx.new()
	plane_pattern.compile(r"(\([^\)]*\)|\[[^\)]*\]|\S+)")
	var vector_pattern = RegEx.new()
	vector_pattern.compile(r"\w+")
	# Parse entities
	for r_entity in entity_pattern.search_all(contents):
		var entity := QEntity.new()
		# Parse properties
		for r_property in properties_pattern.search_all(r_entity.get_string(1).strip_edges()):
			match r_property.get_string(1):
				"classname": entity.classname = r_property.get_string(2).trim_prefix('"').trim_suffix('"').replace("¡", "{").replace("¿", "}")
				_: entity.properties[r_property.get_string(1)] = r_property.get_string(2).trim_prefix('"').trim_suffix('"').replace("¡", "{").replace("¿", "}")
		# Parse brushes
		for r_brush in brush_pattern.search_all(r_entity.get_string(2).strip_edges()):
			var brush: Array[Dictionary]
			# Parse planes
			for line in r_brush.get_string().strip_edges().split("\n"):
				var plane := {
					&"p1":Vector3i.ZERO,
					&"p2":Vector3i.ZERO,
					&"p3":Vector3i.ZERO,
					&"texture":"",
					&"u_offset":Vector4.ZERO,
					&"v_offset":Vector4.ZERO,
					&"rotation":0.0,
					&"u_scale":0.0,
					&"v_scale":0.0,
					}
				var r_plane := plane_pattern.search_all(line)
				if !r_plane.size() >= 9: continue
				var results := vector_pattern.search_all(r_plane[0].get_string())
				if results.size() >= 3:
					plane[&"p1"].x = results[0].get_string().to_float()
					plane[&"p1"].y = results[1].get_string().to_float()
					plane[&"p1"].z = results[2].get_string().to_float()
				results = vector_pattern.search_all(r_plane[1].get_string())
				if results.size() >= 3:
					plane[&"p2"].x = results[0].get_string().to_float()
					plane[&"p2"].y = results[1].get_string().to_float()
					plane[&"p2"].z = results[2].get_string().to_float()
				results = vector_pattern.search_all(r_plane[2].get_string())
				if results.size() >= 3:
					plane[&"p3"].x = results[0].get_string().to_float()
					plane[&"p3"].y = results[1].get_string().to_float()
					plane[&"p3"].z = results[2].get_string().to_float()
				plane[&"texture"] = r_plane[3].get_string()
				if r_plane[4].get_string().begins_with("["):
					results = vector_pattern.search_all(r_plane[4].get_string())
					if results.size() >= 4:
						plane[&"u_offset"].x = results[0].get_string().to_float()
						plane[&"u_offset"].y = results[1].get_string().to_float()
						plane[&"u_offset"].z = results[2].get_string().to_float()
						plane[&"u_offset"].w = results[3].get_string().to_float()
				else:
					plane[&"u_offset"] = r_plane[4].get_string().to_float()
				if r_plane[5].get_string().begins_with("["):
					if results.size() >= 4:
						plane[&"v_offset"].x = results[0].get_string().to_float()
						plane[&"v_offset"].y = results[1].get_string().to_float()
						plane[&"v_offset"].z = results[2].get_string().to_float()
						plane[&"v_offset"].w = results[3].get_string().to_float()
				else:
					plane[&"v_offset"] = r_plane[5].get_string().to_float()
				plane[&"rotation"] = r_plane[6].get_string().to_float()
				plane[&"u_scale"] = r_plane[7].get_string().to_float()
				plane[&"v_scale"] = r_plane[8].get_string().to_float()
				if r_plane.size() >= 12:
					plane[&"surface_flag"] = r_plane[9].get_string().to_int()
					plane[&"contents_flag"] = r_plane[10].get_string().to_int()
					plane[&"value"] = r_plane[11].get_string().to_int()
				brush.append(plane)
			entity.brushes.append(brush)
		resource.entities.append(entity)
	return resource
