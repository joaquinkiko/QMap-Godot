@tool
@icon("../icons/qmap.svg")
## .map file resource
class_name QMap extends Resource

## Header comments
@export_multiline var header: String
## @deprecated
@export var game_name: String
## @deprecated
@export var format: String
@export var entities: Array[QEntity]

## @deprecated
func parse_file(data: String) -> void:
	entities.clear()
	game_name = ""
	format = ""
	var in_entity := false
	var in_brush := false
	var current_entity: QEntity
	var property_data: PackedStringArray
	var current_brush: QBrush
	for line in data.split("\n", false):
		line = line.strip_edges()
		if line.begins_with("//"):
			if line.begins_with("// Game:"):
				game_name = line.trim_prefix("// Game:").strip_edges()
			elif line.begins_with("// Format:"):
				format = line.trim_prefix("// Format:").strip_edges()
			continue
		var position := 0
		while position < line.length():
			if line[position] == "/":
				if position + 1 < line.length() && line[position + 1]: continue
			if line[position] == "{":
				if in_entity:
					if in_brush:
						printerr("Cannot parse %s"%resource_path)
						return
					else: 
						in_brush = true
						current_brush = QBrush.new()
				else: 
					in_entity = true
					current_entity = QEntity.new()
					property_data = PackedStringArray([])
			elif line[position] == "}":
				if in_entity:
					if in_brush: 
						in_brush = false
						current_entity.brushes.append(current_brush)
					else: 
						in_entity = false
						var last_key: String
						for value in property_data:
							if last_key.is_empty():
								last_key = value
							else:
								if last_key == "classname":
									current_entity.classname = value
								else:
									current_entity.properties[last_key] = value
								last_key = ""
						entities.append(current_entity)
				else: 
					printerr("Cannot parse %s"%resource_path)
					return
			elif line[position] == '"':
				if in_entity:
					if in_brush:
						printerr("Cannot parse %s"%resource_path)
						return
					var new_data: String
					while position < line.length():
						position += 1
						if line[position] == '"': break
						else: new_data += line[position]
					position += 1
					property_data.append(new_data)
				else:
					printerr("Cannot parse %s"%resource_path)
					return
			elif line[position] == '(':
				if in_entity:
					if in_brush:
						var regex := RegEx.new()
						# Match anything inside () or [] OR individual sequences
						regex.compile(r'(\(.*?\)|\[.*?\]|\S+)')
						var data_parts := PackedStringArray([])
						var data_count: int
						for match in regex.search_all(line):
							data_parts.append(match.get_string())
							data_count += 1
							position = match.get_end() + 1
							if data_count == 9: break
						if data_parts.size() >= 9:
							var plane := QPlane.new()
							var points : PackedStringArray
							data_parts[0] = data_parts[0].trim_prefix("(").trim_suffix(")").strip_edges()
							points = data_parts[0].split(" ")
							if points.size() >= 1 && points[0].is_valid_float(): 
								plane.point1.x = points[0].to_float()
							if points.size() >= 2 && points[1].is_valid_float(): 
								plane.point1.y = points[1].to_float()
							if points.size() >= 3 && points[2].is_valid_float(): 
								plane.point1.z = points[2].to_float()
							points = data_parts[1].split(" ")
							if points.size() >= 1 && points[0].is_valid_float(): 
								plane.point2.x = points[0].to_float()
							if points.size() >= 2 && points[1].is_valid_float(): 
								plane.point2.y = points[1].to_float()
							if points.size() >= 3 && points[2].is_valid_float(): 
								plane.point2.z = points[2].to_float()
							points = data_parts[2].split(" ")
							if points.size() >= 1 && points[0].is_valid_float(): 
								plane.point3.x = points[0].to_float()
							if points.size() >= 2 && points[1].is_valid_float(): 
								plane.point3.y = points[1].to_float()
							if points.size() >= 3 && points[2].is_valid_float(): 
								plane.point3.z = points[2].to_float()
							plane.texture_name = data_parts[3]
							if data_parts[4].begins_with("["):
								data_parts[4] = data_parts[4].trim_prefix("[").trim_suffix("]").strip_edges()
								points = data_parts[4].split(" ")
								if points.size() >= 1 && points[0].is_valid_float(): 
									plane.u_offset.x = points[0].to_float()
								if points.size() >= 2 && points[1].is_valid_float(): 
									plane.u_offset.y = points[1].to_float()
								if points.size() >= 3 && points[2].is_valid_float(): 
									plane.u_offset.z = points[2].to_float()
								if points.size() >= 4 && points[3].is_valid_float(): 
									plane.u_offset.w = points[3].to_float()
							else:
								if data_parts[4].is_valid_float(): plane.u_offset.w = data_parts[4].to_float()
							if data_parts[5].begins_with("["):
								data_parts[5] = data_parts[5].trim_prefix("[").trim_suffix("]").strip_edges()
								points = data_parts[5].split(" ")
								if points.size() >= 1 && points[0].is_valid_float(): 
									plane.v_offset.x = points[0].to_float()
								if points.size() >= 2 && points[1].is_valid_float(): 
									plane.v_offset.y = points[1].to_float()
								if points.size() >= 3 && points[2].is_valid_float(): 
									plane.v_offset.z = points[2].to_float()
								if points.size() >= 4 && points[3].is_valid_float(): 
									plane.v_offset.w = points[3].to_float()
							else:
								if data_parts[4].is_valid_float(): plane.v_offset.w = data_parts[4].to_float()
							if data_parts[6].is_valid_float(): plane.rotation = data_parts[6].to_float()
							if data_parts[7].is_valid_float(): plane.u_scale = data_parts[7].to_float()
							if data_parts[8].is_valid_float(): plane.v_scale = data_parts[8].to_float()
							current_brush.planes.append(plane)
						else:
							printerr("Cannot parse %s"%resource_path)
							return
						break
					else:
						printerr("Cannot parse %s"%resource_path)
						return
				else:
					printerr("Cannot parse %s"%resource_path)
					return
			position += 1
