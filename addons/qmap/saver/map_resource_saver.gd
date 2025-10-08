@tool
## Saver for [QMap]
class_name QMapResourceSaver extends ResourceFormatSaver

func _get_recognized_extensions(resource: Resource) -> PackedStringArray:
	return ["map"]

func _recognize(resource: Resource) -> bool:
	return resource is QMap

func _save(resource: Resource, path: String, flags: int) -> Error:
	if !(resource is QMap): return ERR_INVALID_DATA
	if FileAccess.file_exists(path) && FileAccess.get_read_only_attribute(path): 
		printerr("'%s' is readonly and cannot be saved"%path)
		return ERR_FILE_CANT_OPEN
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null: return ERR_FILE_CANT_OPEN
	var map := resource as QMap
	# Write Trenchbroom header info
	if !map.game_name.is_empty():
		file.store_string("// Game: %s\n"%map.game_name)
	if !map.format_name.is_empty():
		file.store_string("// Format: %s\n"%map.format_name)
	# Write header if present
	if !map.header.is_empty():
		for line in map.header.split("\n", false):
			file.store_string("// %s\n"%line)
	# Write entities
	for e in map.entities.size():
		if map.entities[e].classname.is_empty(): continue
		if map.use_entity_headers: file.store_string("// entity %s\n"%e)
		file.store_string("{\n")
		# Write properties
		for p in map.entities[e].properties.keys():
			file.store_string('"%s" "%s"\n'%[p, map.entities[e].properties[p]])
		# Write brushes
		for b in map.entities[e].brushes.size():
			if map.use_entity_headers: file.store_string("// brush %s\n"%b)
			file.store_string("{\n")
			for face in map.entities[e].brushes[b].faces:
				for n in 3:
					file.store_string("( ")
					if face.points[n].x == floor(face.points[n].x):
						file.store_string("%s "%int(face.points[n].x))
					else:
						file.store_string("%s "%face.points[n].x)
					if face.points[n].y == floor(face.points[n].y):
						file.store_string("%s "%int(face.points[0].y))
					else:
						file.store_string("%s "%face.points[n].y)
					if face.points[n].z == floor(face.points[n].z):
						file.store_string("%s "%int(face.points[n].z))
					else:
						file.store_string("%s "%face.points[n].z)
					file.store_string(") ")
				if face.texturename.contains(" "):
					file.store_string('"%s" '%face.texturename)
				else:
					file.store_string("%s "%face.texturename)
				if face.format == QEntity.FaceFormat.VALVE_220:
					file.store_string("[ ")
					if face.u_offset.x == floor(face.u_offset.x):
						file.store_string("%s "%int(face.u_offset.x))
					else:
						file.store_string("%s "%face.u_offset.x)
					if face.u_offset.y == floor(face.u_offset.y):
						file.store_string("%s "%int(face.u_offset.y))
					else:
						file.store_string("%s "%face.u_offset.y)
					if face.u_offset.z == floor(face.u_offset.z):
						file.store_string("%s "%int(face.u_offset.z))
					else:
						file.store_string("%s "%face.u_offset.z)
					if face.u_offset.w == floor(face.u_offset.w):
						file.store_string("%s "%int(face.u_offset.w))
					else:
						file.store_string("%s "%face.u_offset.w)
					file.store_string("] ")
				else:
					if face.u_offset.w == floor(face.u_offset.w):
						file.store_string("%s "%int(face.u_offset.w))
					else:
						file.store_string("%s "%face.u_offset.w)
				if face.format == QEntity.FaceFormat.VALVE_220:
					file.store_string("[ ")
					if face.v_offset.x == floor(face.v_offset.x):
						file.store_string("%s "%int(face.v_offset.x))
					else:
						file.store_string("%s "%face.v_offset.x)
					if face.v_offset.y == floor(face.v_offset.y):
						file.store_string("%s "%int(face.v_offset.y))
					else:
						file.store_string("%s "%face.v_offset.y)
					if face.v_offset.z == floor(face.v_offset.z):
						file.store_string("%s "%int(face.v_offset.z))
					else:
						file.store_string("%s "%face.v_offset.z)
					if face.v_offset.w == floor(face.v_offset.w):
						file.store_string("%s "%int(face.v_offset.w))
					else:
						file.store_string("%s "%face.v_offset.w)
					file.store_string("] ")
				else:
					if face.v_offset.w == floor(face.v_offset.w):
						file.store_string("%s "%face.v_offset.w)
					else:
						file.store_string("%s "%face.v_offset.w)
				if face.rotation == floor(face.rotation):
					file.store_string("%s "%int(face.rotation))
				else:
					file.store_string("%s "%face.rotation)
				if face.uv_scale.x == floor(face.uv_scale.x):
					file.store_string("%s "%int(face.uv_scale.x))
				else:
					file.store_string("%s "%face.uv_scale.x)
				if face.uv_scale.y == face.uv_scale.y:
					file.store_string("%s"%face.uv_scale.y)
				else:
					file.store_string("%s"%face.uv_scale.y)
				if face.has_surface_flags:
					file.store_string(" %s %s %s"%[
						face.surface_flag,
						face.contents_flag,
						face.value,
					])
				file.store_string("\n")
			file.store_string("}\n")
		file.store_string("}\n")
	file.close()
	return OK
