@tool
## Loader for [FGD]
class_name FGDResourceLoader extends ResourceFormatLoader

func _get_recognized_extensions() -> PackedStringArray:
	return ["fgd", "FGD"]

func _handles_type(type: StringName) -> bool:
	return ClassDB.is_parent_class(type, "Resource")

func _get_resource_type(path: String) -> String:
	if path.get_extension().to_lower() == "fgd": return "Resource"
	else: return ""

func _load(path: String, original_path: String, use_sub_threads: bool, cache_mode: int) -> Variant:
	var resource := FGD.new()
	var contents := FileAccess.get_file_as_string(path)
	# Parse header
	for line: String in contents.split("\n", false):
		if line.split("//", true, 1).size() > 1:
			if !resource.header.is_empty(): resource.header += "\n"
			resource.header += line.split("//", true, 1)[1].trim_prefix(" ")
		elif line.is_empty(): continue
		else: break
	# Remove comments for parsing
	var parsing_contents := contents
	contents = ""
	for line: String in parsing_contents.split("\n", false):
		line = line.split("//", true)[0]
		if line.is_empty(): continue
		else: contents += line + "\n"
	# Parse @include
	var include_pattern = RegEx.new()
	include_pattern.compile(r'@include\s*"([^"]*)"')
	for r_include in include_pattern.search_all(contents):
		resource.base_fgds.append(r_include.get_string(1))
	# Parse @mapsize
	var map_size_pattern = RegEx.new()
	map_size_pattern.compile(r"@mapsize\s*\((-?\w*),\s*(-?\w*\))")
	for r_map_size in map_size_pattern.search_all(contents):
		if !r_map_size.get_string(1).is_empty() && !r_map_size.get_string(2).is_empty():
			resource.max_map_size.x = r_map_size.get_string(1).to_int()
			resource.max_map_size.y = r_map_size.get_string(2).to_int()
	# Parse entity classes
	var entity_pattern = RegEx.new()
	entity_pattern.compile(r"@(\w+)([^\n=]*)\s*=\s*(\w+)\s*[:\s]\s*([^\n=]*)\s*(\[[^@]*)")
	for r_entity in entity_pattern.search_all(contents):
		var new_class := FGDClass.new()
		match r_entity.get_string(1).to_lower():
			"baseclass": new_class.class_type = FGDClass.ClassType.BASE
			"solidclass": new_class.class_type = FGDClass.ClassType.SOLID
			"pointclass": new_class.class_type = FGDClass.ClassType.POINT
			_: continue
		new_class.description = r_entity.get_string(4).strip_edges().trim_prefix('"').trim_suffix('"')
		# Pare class helper functions
		var function_pattern := RegEx.new()
		function_pattern.compile(r"(\w+)\(([^)]*)\)")
		for r_func in function_pattern.search_all(r_entity.get_string(2).strip_edges()):
			match r_func.get_string(1).to_lower():
				"base":
					new_class.base_classes = r_func.get_string(2).strip_edges().replace(",", "").split(" ", false)
				"color":
					var args: PackedStringArray = r_func.get_string(2).strip_edges().split(" ", false)
					if args.size() >= 3:
						new_class.color.r8 = args[0].to_int()
						new_class.color.g8 = args[1].to_int()
						new_class.color.b8 = args[2].to_int()
					else:
						new_class.misc_functions[r_func.get_string(1)] = r_func.get_string(2).strip_edges()
				"size":
					var args: PackedStringArray = r_func.get_string(2).strip_edges().split(" ", false)
					if args.size() >= 3:
						if args.size() >= 6:
							new_class.sizing_type = FGDClass.SizingType.NEGATIVE_AND_POSITIVE
							new_class.negative_size.x = args[0].to_int()
							new_class.negative_size.y = args[1].to_int()
							new_class.negative_size.z = args[2].to_int()
							new_class.positive_size.x = args[3].to_int()
							new_class.positive_size.y = args[4].to_int()
							new_class.positive_size.z = args[5].to_int()
						else:
							new_class.sizing_type = FGDClass.SizingType.ONLY_POSITIVE
							new_class.positive_size.x = args[0].to_int()
							new_class.positive_size.y = args[1].to_int()
							new_class.positive_size.z = args[2].to_int()
					else:
						new_class.misc_functions[r_func.get_string(1)] = r_func.get_string(2).strip_edges()
				"iconsprite":
					new_class.icon_sprite = r_func.get_string(2).strip_edges().trim_prefix('"').trim_suffix('"')
				"studio":
					new_class.studio = r_func.get_string(2).strip_edges().trim_prefix('"').trim_suffix('"')
				"decal":
					new_class.includes_decal = true
				"sprite":
					new_class.includes_sprite = true
		resource.classes[r_entity.get_string(3)] = new_class
		# Parse class properties
		var prop_pattern := RegEx.new()
		prop_pattern.compile(r"(\w+)\((\w+)\)(?:\s*:\s*(\"[^\"]+\"))?(?:\s*:\s*([^\=\n:]+))?(?::\s*(\"[^\"]+\"))?(?:\s*=\s*(\[[\s\S]*?\]))?")
		for r_prop in prop_pattern.search_all(r_entity.get_string(5)):
			var prop := FGDEntityProperty.new()
			match r_prop.get_string(2).to_lower():
				"string": prop.type = FGDEntityProperty.PropertyType.STRING
				"integer": prop.type = FGDEntityProperty.PropertyType.INTEGER
				"choices": prop.type = FGDEntityProperty.PropertyType.CHOICES
				"flags": prop.type = FGDEntityProperty.PropertyType.FLAGS
				"color255": prop.type = FGDEntityProperty.PropertyType.COLOR_255
				"studio": prop.type = FGDEntityProperty.PropertyType.STUDIO
				"float": prop.type = FGDEntityProperty.PropertyType.FLOAT
				"decal": prop.type = FGDEntityProperty.PropertyType.DECAL
				"sprite": prop.type = FGDEntityProperty.PropertyType.SPRITE
				"target_source":  prop.type = FGDEntityProperty.PropertyType.TARGET_SOURCE
				"angle":  prop.type = FGDEntityProperty.PropertyType.ANGLE
				"color1":  prop.type = FGDEntityProperty.PropertyType.COLOR_1
				"sound":  prop.type = FGDEntityProperty.PropertyType.SOUND
				"target_destination":  prop.type = FGDEntityProperty.PropertyType.TARGET_DESTINATION
				"scale":  prop.type = FGDEntityProperty.PropertyType.SCALE
				"vector":  prop.type = FGDEntityProperty.PropertyType.VECTOR
				"res":  prop.type = FGDEntityProperty.PropertyType.RESOURCE
				"respath":  prop.type = FGDEntityProperty.PropertyType.RESOURCE_PATH
				_: prop.type = FGDEntityProperty.PropertyType.STRING
			prop.display_name = r_prop.get_string(3).trim_prefix('"').trim_suffix('"')
			prop.default_value = r_prop.get_string(4).strip_edges().trim_prefix('"').trim_suffix('"')
			prop.display_tooltip = r_prop.get_string(5).trim_prefix('"').trim_suffix('"')
			# Parse choices / flags
			if !r_prop.get_string(6).strip_edges().is_empty():
				var parts_pattern := RegEx.new()
				parts_pattern.compile(r"(\w+)\s*:\s*\"([^\"]+)\"(?:\s*:\s*([^\n]+))?")
				for r_parts in parts_pattern.search_all(r_prop.get_string(6).strip_edges()):
					prop.choices[r_parts.get_string(1).strip_edges().to_int()] = r_parts.get_string(2).strip_edges().trim_prefix('"').trim_suffix('"')
					if !r_parts.get_string(3).strip_edges().is_empty():
						if bool(r_parts.get_string(3).strip_edges().to_int()): prop.default_flags.append(r_parts.get_string(1).strip_edges().to_int())
			new_class.properties[r_prop.get_string(1)] = prop
	return resource
