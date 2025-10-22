@tool
## Loader for [QMap]
class_name QMapResourceLoader extends ResourceFormatLoader

func _get_recognized_extensions() -> PackedStringArray:
	return ["map"]

func _handles_type(type: StringName) -> bool:
	return ClassDB.is_parent_class(type, "Resource")

func _get_resource_type(path: String) -> String:
	if path.get_extension().to_lower() == "map": return "Resource"
	else: return ""

func _load(path: String, original_path: String, use_sub_threads: bool, cache_mode: int) -> Variant:
	var resource := QMap.new()
	var file := FileAccess.open(path, FileAccess.READ)
	var is_in_header := true
	var is_in_entity := false
	var is_in_brush := false
	var is_in_patch := false
	var patch_depth: int = 0
	var current_entity: QEntity
	var current_brush: QEntity.Brush
	var face_regex := RegEx.new()
	face_regex.compile(r'(\([^\)]*\)|\[[^\]]*\]|"[^"]*"|\S+)')
	while !file.eof_reached():
		var line := file.get_line()
		line = line.strip_edges()
		# Parse header
		if is_in_header:
			if line.begins_with("//"):
				line = line.trim_prefix("//").trim_prefix(" ")
				if line == "entity 0":
					resource.use_entity_headers = true
					is_in_header = false
				elif line.begins_with("Game: "):
					resource.game_name = line.trim_prefix("Game: ").strip_edges()
				elif line.begins_with("Format: "):
					resource.format_name = line.trim_prefix("Format: ").strip_edges()
				else:
					if !resource.header.is_empty(): resource.header += "\n"
					resource.header += line
				continue
			else:
				is_in_header = false
		# Clear comments / check if empty
		line.split("//", true)[0].strip_edges()
		if line.is_empty(): continue
		# Check opening / closing bracket
		match line:
			"{":
				if is_in_patch:
					patch_depth += 1
				if is_in_brush:
					is_in_patch = true
					patch_depth = 0
				elif is_in_entity:
					is_in_brush = true
					current_brush = QEntity.Brush.new()
				else:
					is_in_entity = true
					current_entity = QEntity.new()
					current_entity.properties.clear()
				continue
			"}":
				if is_in_patch:
					if patch_depth > 0: patch_depth -= 1
					else:
						is_in_patch = false
				elif is_in_brush:
					is_in_brush = false
					current_entity.brushes.append(current_brush)
				elif is_in_entity:
					is_in_entity = false
					resource.entities.append(current_entity)
				continue
		# Parse patch
		if is_in_patch: pass
		# Parse face
		elif is_in_brush:
			var face := QEntity.Face.new()
			var matches := face_regex.search_all(line)
			if matches.size() == 9:
				face.has_surface_flags = false
			elif matches.size() == 12:
				face.has_surface_flags = true
			else: continue
			face.texturename = matches[3].get_string().trim_prefix('"').trim_suffix('"')
			for n in 3:
				var vector_string := matches[n].get_string().trim_prefix("(").trim_suffix(")").strip_edges()
				var vector_contents := vector_string.split(" ", false)
				face.points.append(Vector3(
					vector_contents[0].to_float(),
					vector_contents[1].to_float(),
					vector_contents[2].to_float())
					)
			face.plane = Plane(face.points[0], face.points[1], face.points[2])
			if matches[4].get_string().begins_with("["):
				face.format = QEntity.FaceFormat.VALVE_220
			else: face.format = QEntity.FaceFormat.STANDARD
			if face.format == QEntity.FaceFormat.VALVE_220:
				var vector_string := matches[4].get_string().trim_prefix("[").trim_suffix("]").strip_edges()
				var vector_contents := vector_string.split(" ", false)
				face.u_offset = Vector4(
					vector_contents[0].to_float(),
					vector_contents[1].to_float(),
					vector_contents[2].to_float(),
					vector_contents[3].to_float()
					)
				vector_string = matches[5].get_string().trim_prefix("[").trim_suffix("]").strip_edges()
				vector_contents = vector_string.split(" ", false)
				face.v_offset = Vector4(
					vector_contents[0].to_float(),
					vector_contents[1].to_float(),
					vector_contents[2].to_float(),
					vector_contents[3].to_float()
					)
			else:
				face.u_offset = Vector4(0,0,0,matches[4].get_string().to_float())
				face.v_offset = Vector4(0,0,0,matches[5].get_string().to_float())
			face.rotation = matches[6].get_string().to_float()
			face.uv_scale = Vector2(
				matches[7].get_string().to_float(),
				matches[8].get_string().to_float()
			)
			face.uv = Transform2D.IDENTITY
			face.uv.origin = Vector2(face.u_offset.w, face.v_offset.w)
			if face.format == QEntity.FaceFormat.STANDARD:
				var r := deg_to_rad(face.rotation)
				face.uv.x = Vector2(cos(r), -sin(r)) * face.uv_scale.x
				face.uv.y = Vector2(sin(r), cos(r)) * face.uv_scale.y
			else:
				face.uv.x = Vector2.RIGHT * face.uv_scale.x
				face.uv.y = Vector2.DOWN * face.uv_scale.y
			if face.has_surface_flags:
				face.surface_flag = matches[9].get_string().to_int()
				face.contents_flag = matches[10].get_string().to_int()
				face.value = matches[11].get_string().to_int()
			current_brush.faces.append(face)
		# Parse property
		elif is_in_entity:
			if line.split('"', false).size() < 3: continue
			var key: StringName = line.split('"', false)[0]
			var contents: String = line.split('"', false)[2]
			current_entity.properties.set(key, contents)
	file.close()
	return resource
