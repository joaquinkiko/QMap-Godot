@tool
## Saver for [QMap]
class_name QMapResourceSaver extends ResourceFormatSaver

func _get_recognized_extensions(resource: Resource) -> PackedStringArray:
	return ["map", "MAP"]

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
	# Write header if present
	if !map.header.is_empty():
		for line in map.header.split("\n", false):
			file.store_string("// %s\n"%line)
	# Write entities
	for e in map.entities.size():
		if map.entities[e].classname.is_empty(): continue
		if map.use_entity_headers: file.store_string("// entity %s\n"%e)
		file.store_string("{\n")
		# Write mapversion, message, and wad before classname for consistency
		if map.entities[e].properties.has("mapversion"):
			file.store_string('"mapversion" "%s"\n'%map.entities[e].properties["mapversion"])
		if map.entities[e].properties.has("message"):
			file.store_string('"message" "%s"\n'%map.entities[e].properties["message"])
		if map.entities[e].properties.has("wad"):
			file.store_string('"wad" "%s"\n'%map.entities[e].properties["wad"])
		# Write classname
		file.store_string('"classname" "%s"\n'%map.entities[e].classname)
		# Write properties
		for p in map.entities[e].properties.keys():
			match p:
				"classname": continue
				"mapversion": continue
				"message": continue
				"wad": continue
				_: file.store_string('"%s" "%s"\n'%[p, map.entities[e].properties[p]])
		# Write brushes if any
		if map.entities[e].brushes.size() > 0: for b in map.entities[e].brushes.size():
			if map.use_entity_headers: file.store_string("// brush %s\n"%b)
			file.store_string("{\n")
			for plane in map.entities[e].brushes[b]:
				file.store_string("( ")
				if plane[&"p1"].x == floor(plane[&"p1"].x):
					file.store_string("%s "%int(plane[&"p1"].x))
				else:
					file.store_string("%s "%plane[&"p1"].x)
				if plane[&"p1"].y == floor(plane[&"p1"].y):
					file.store_string("%s "%int(plane[&"p1"].y))
				else:
					file.store_string("%s "%plane[&"p1"].y)
				if plane[&"p1"].z == floor(plane[&"p1"].z):
					file.store_string("%s "%int(plane[&"p1"].z))
				else:
					file.store_string("%s "%plane[&"p1"].z)
				file.store_string(") ")
				file.store_string("( ")
				if plane[&"p2"].x == floor(plane[&"p2"].x):
					file.store_string("%s "%int(plane[&"p2"].x))
				else:
					file.store_string("%s "%plane[&"p2"].x)
				if plane[&"p2"].y == floor(plane[&"p2"].y):
					file.store_string("%s "%int(plane[&"p2"].y))
				else:
					file.store_string("%s "%plane[&"p2"].y)
				if plane[&"p2"].z == floor(plane[&"p2"].z):
					file.store_string("%s "%int(plane[&"p2"].z))
				else:
					file.store_string("%s "%plane[&"p2"].z)
				file.store_string(") ")
				file.store_string("( ")
				if plane[&"p3"].x == floor(plane[&"p3"].x):
					file.store_string("%s "%int(plane[&"p3"].x))
				else:
					file.store_string("%s "%plane[&"p3"].x)
				if plane[&"p3"].y == floor(plane[&"p3"].y):
					file.store_string("%s "%int(plane[&"p3"].y))
				else:
					file.store_string("%s "%plane[&"p3"].y)
				if plane[&"p3"].z == floor(plane[&"p3"].z):
					file.store_string("%s "%int(plane[&"p3"].z))
				else:
					file.store_string("%s "%plane[&"p3"].z)
				file.store_string(") ")
				file.store_string("%s "%plane[&"texture"])
				if plane[&"u_offset"] is Vector4 || plane[&"u_offset"] is Vector4i:
					file.store_string("[ ")
					if plane[&"u_offset"].x == floor(plane[&"u_offset"].x):
						file.store_string("%s "%int(plane[&"u_offset"].x))
					else:
						file.store_string("%s "%plane[&"u_offset"].x)
					if plane[&"u_offset"].y == floor(plane[&"u_offset"].y):
						file.store_string("%s "%int(plane[&"u_offset"].y))
					else:
						file.store_string("%s "%plane[&"u_offset"].y)
					if plane[&"u_offset"].z == floor(plane[&"u_offset"].z):
						file.store_string("%s "%int(plane[&"u_offset"].z))
					else:
						file.store_string("%s "%plane[&"u_offset"].z)
					if plane[&"u_offset"].w == floor(plane[&"u_offset"].w):
						file.store_string("%s "%int(plane[&"u_offset"].w))
					else:
						file.store_string("%s "%plane[&"u_offset"].w)
					file.store_string("] ")
				else:
					if plane[&"u_offset"] == floor(plane[&"u_offset"]):
						file.store_string("%s "%int(plane[&"u_offset"]))
					else:
						file.store_string("%s "%plane[&"u_offset"])
				if plane[&"v_offset"] is Vector4 || plane[&"v_offset"] is Vector4i:
					file.store_string("[ ")
					if plane[&"v_offset"].x == floor(plane[&"v_offset"].x):
						file.store_string("%s "%int(plane[&"v_offset"].x))
					else:
						file.store_string("%s "%plane[&"v_offset"].x)
					if plane[&"v_offset"].y == floor(plane[&"v_offset"].y):
						file.store_string("%s "%int(plane[&"v_offset"].y))
					else:
						file.store_string("%s "%plane[&"v_offset"].y)
					if plane[&"v_offset"].z == floor(plane[&"v_offset"].z):
						file.store_string("%s "%int(plane[&"v_offset"].z))
					else:
						file.store_string("%s "%plane[&"v_offset"].z)
					if plane[&"v_offset"].w == floor(plane[&"v_offset"].w):
						file.store_string("%s "%int(plane[&"v_offset"].w))
					else:
						file.store_string("%s "%plane[&"v_offset"].w)
					file.store_string("] ")
				else:
					if plane[&"v_offset"] == floor(plane[&"v_offset"]):
						file.store_string("%s "%int(plane[&"v_offset"]))
					else:
						file.store_string("%s "%plane[&"v_offset"])
				if plane[&"rotation"] == floor(plane[&"rotation"]):
					file.store_string("%s "%int(plane[&"rotation"]))
				else:
					file.store_string("%s "%plane[&"rotation"])
				if plane[&"u_scale"] == floor(plane[&"u_scale"]):
					file.store_string("%s "%int(plane[&"u_scale"]))
				else:
					file.store_string("%s "%plane[&"u_scale"])
				if plane[&"v_scale"] == floor(plane[&"v_scale"]):
					file.store_string("%s"%int(plane[&"v_scale"]))
				else:
					file.store_string("%s"%plane[&"v_scale"])
				if plane.has(&"surface_flag") && plane.has(&"contents_flag") && plane.has(&"value"):
					file.store_string(" %s %s %s"%[
						plane[&"surface_flag"],
						plane[&"contents_flag"],
						plane[&"value"],
					])
				file.store_string("\n")
			file.store_string("}\n")
		file.store_string("}\n")
	file.close()
	return OK
