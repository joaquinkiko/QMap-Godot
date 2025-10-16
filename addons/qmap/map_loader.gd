## Loads [QMap] as a child of this node
##
## [url]https://1666186240-files.gitbook.io/~/files/v0/b/gitbook-x-prod.appspot.com/o/spaces%2F-LtVT8pJjInrrHVCovzy%2Fuploads%2FEukkFYJLwfafFXUMpsI2%2FMAPFiles_2001_StefanHajnoczi.pdf?alt=media&token=51471685-bf69-42ae-a015-a474c0b95165[/url]
class_name MapLoader extends Node3D

## Data used for building geometry
class SolidData extends RefCounted:
	class BrushData extends RefCounted:
		var faces: Array[FaceData]
		var planes: Array[Plane]
		var is_origin: bool
		var is_trigger: bool
	class FaceData extends RefCounted:
		var plane: Plane
		var uv: Transform2D
		var u_axis: Vector3
		var v_axis: Vector3
		var uv_format: QEntity.FaceFormat
		var vertices: PackedVector3Array
		var normals: PackedVector3Array
		var tangents: PackedFloat32Array
		var colors: PackedColorArray
		var uvs: PackedVector2Array
		var indices: PackedInt32Array
		var texture: StringName
		var is_trigger: bool
		var surface_flag: int
		var content_flag: int
	var brushes: Array[BrushData]
	var origin: Vector3
	var render_mesh: ArrayMesh
	var collision_mesh: ArrayMesh
	var convex_meshes: Array[ArrayMesh]
	var occluder: ArrayOccluder3D
	var sorted_faces: Dictionary[StringName, Array]

## Emitted at map loading stages (value from 0.0-1.0)
signal progress(percentage: float, task: String)

## [QMap] to load on [method load_map]
@export var map: QMap
## Settings to use for generation
@export var settings: QMapSettings = preload("res://addons/qmap/default_resources/default_settings.tres")
@export_group("Additional Settings")
## If true, will automatically call [method load_map] during [method _ready]
@export var auto_load_map: bool = true
## When true will load any [WAD] listed in [QMap] properties under the key "wads"
@export var auto_load_internal_wads: bool = true
## While true main thread will be paused during loading (may improve loading speed)
@export var pause_main_thread_while_loading: bool = true
@export_group("Debug Settings")
## When true will print debug info while map loads
@export var verbose: bool = true
## Will render non-rendered (skip/clip/trigger/etc...) textures
@export var show_non_rendered_textures: bool = false

var _current_wad_paths: PackedStringArray
var _wads: Array[WAD]
var _materials: Dictionary[StringName, Material]
var _textures: Dictionary[StringName, Texture2D]
var _texture_sizes: Dictionary[StringName, Vector2]
var _entities: Dictionary[QEntity, Node]
var _solid_data: Dictionary[QEntity, SolidData]
var _target_destinations: Dictionary[StringName, Node]
var _alphatests: Dictionary[StringName, bool]

func _ready() -> void:
	if auto_load_map: load_map()

func _thread_group_task(task: Callable, elements: int, task_debug: String) -> void:
	if verbose: print("\t-%s..."%task_debug)
	var interval_time := Time.get_ticks_msec()
	var task_id := WorkerThreadPool.add_group_task(task, elements, -1, false, task_debug)
	if !pause_main_thread_while_loading: while !WorkerThreadPool.is_group_task_completed(task_id):
		await get_tree().process_frame
	WorkerThreadPool.wait_for_group_task_completion(task_id)
	if verbose: print("\t\t-Done in %sms"%(Time.get_ticks_msec() - interval_time))

func _thread_individual_taks(tasks: Array[Callable], task_debug: String) -> void:
	if verbose: print("\t-%s..."%task_debug)
	var interval_time := Time.get_ticks_msec()
	var task_ids: PackedInt32Array
	task_ids.resize(tasks.size())
	for n in tasks.size():
		task_ids[n] = WorkerThreadPool.add_task(tasks[n], false, "%s (%s)"%[task_debug, n])
	if !pause_main_thread_while_loading:
		var is_completed: bool
		while !is_completed:
			is_completed = true
			for n in task_ids:
				if !WorkerThreadPool.is_task_completed(n):
					is_completed = false
					break
			await get_tree().process_frame
	for n in task_ids: WorkerThreadPool.wait_for_task_completion(n)
	if verbose: print("\t\t-Done in %sms"%(Time.get_ticks_msec() - interval_time))

## Convert YZX coordinates to XYZ coordinates
func _convert_coordinates(vector: Vector3) -> Vector3:
	return Vector3(vector.y, vector.z, vector.x)

func load_map() -> Error:
	if map == null:
		printerr("Missing map to generate!")
		return ERR_FILE_NOT_FOUND
	if settings == null:
		printerr("Missing MapSettings to generate with!")
		return ERR_FILE_NOT_FOUND
	var start_time := Time.get_ticks_msec()
	if verbose: print("Generating map '%s'..."%map.resource_path)
	progress.emit(0, "Initializing")
	clear_children()
	await _thread_individual_taks([
		_create_texture_map,
		_create_entity_maps,
		_include_preloaded_wads],
		"Initializing")
	progress.emit(0.1, "Loading wads")
	await _thread_group_task(_load_wads, map.wad_paths.size(), "Loading wads")
	progress.emit(0.4, "Generating materials")
	await _thread_group_task(_generate_materials, _materials.size(), "Generating materials")
	if verbose: print("\t-Detecting Alphatest materials...")
	var interval_time := Time.get_ticks_msec()
	progress.emit(0.48, "Detecting Alphatest materials")
	for n in _textures.size():
		_detect_alphatest(n)
	if verbose: print("\t\t-Done in %sms"%(Time.get_ticks_msec() - interval_time))
	progress.emit(0.50, "Generating entities")
	await _thread_group_task(_generate_entities, _entities.size(), "Generating entities")
	progress.emit(0.55, "Generating Solid Data")
	await _thread_group_task(_generate_solid_data, _solid_data.size(), "Generating Solid Data")
	progress.emit(0.65, "Calculating origins")
	await _thread_group_task(_calculate_origins, _solid_data.size(), "Calculating origins")
	progress.emit(0.67, "Indexing faces")
	await _thread_group_task(_index_faces, _solid_data.size(), "Indexing faces")
	progress.emit(0.69, "Smoothing normals")
	await _thread_group_task(_smooth_normals, _solid_data.size(), "Smoothing normals")
	progress.emit(0.71, "Sorting brushes")
	await _thread_group_task(_sort_brushes, _solid_data.size(), "Sorting brushes")
	progress.emit(0.73, "Sorting faces")
	await _thread_group_task(_sort_faces, _solid_data.size(), "Sorting faces")
	progress.emit(0.75, "Generating meshes")
	await _thread_group_task(_generate_meshes, _solid_data.size(), "Generating meshes")
	progress.emit(0.95, "Spawning entities")
	if verbose: print("\t-Spawning entities...")
	interval_time = Time.get_ticks_msec()
	_pass_to_scene_tree()
	if verbose: print("\t\t-Done in %sms"%(Time.get_ticks_msec() - interval_time))
	if settings.unwrap_uvs:
		if verbose: print("\t-Unwrapping UVs...")
		interval_time = Time.get_ticks_msec()
		progress.emit(0.97, "Unwrapping UVs")
		for n in _solid_data.size():
			_unwrap_uvs(n)
		if verbose: print("\t\t-Done in %sms"%(Time.get_ticks_msec() - interval_time))
	progress.emit(0.99, "Cleaning-up")
	_current_wad_paths.clear()
	_wads.clear()
	_materials.clear()
	_textures.clear()
	_texture_sizes.clear()
	_entities.clear()
	_solid_data.clear()
	_alphatests.clear()
	_target_destinations.clear()
	if verbose: print("Finished generating map in %sms"%(Time.get_ticks_msec() - start_time))
	progress.emit(1, "Finished")
	return OK

## Clears all children node for reloading map
func clear_children() -> void:
	for child in get_children(): child.queue_free()

## Fill [member _materials]
func _create_texture_map() -> void:
	var placeholder := PlaceholderMaterial.new()
	for texturename in map.texturenames:
		_materials[texturename] = placeholder
		_textures[texturename] = null
		_texture_sizes[texturename] = Vector2.ONE * settings.scaling
		_alphatests[texturename] = false

## Fill [member _entities] and [member _solid_data]
func _create_entity_maps() -> void:
	var brush_count: int
	for entity in map.entities: brush_count += entity.brushes.size()
	if verbose: print("\t\t-Initializing %s entities and %s brushes..."%[map.entities.size(),brush_count])
	for entity in map.entities:
		entity.add_base_properties(settings.fgd)
		_entities[entity] = null
		if entity.brushes.size() > 0:
			var data := SolidData.new()
			data.origin = entity.origin
			for brush in entity.brushes:
				var brush_data := SolidData.BrushData.new()
				brush_data.is_origin = true
				brush_data.is_trigger = true
				brush_data.planes = brush.planes
				for face in brush.faces:
					var face_data := SolidData.FaceData.new()
					face_data.texture = face.texturename
					if face.texturename.to_lower() != settings.texture_origin.to_lower(): brush_data.is_origin = false
					face_data.plane = face.plane
					face_data.uv = face.uv
					face_data.uv_format = face.format
					if face.format == QEntity.FaceFormat.VALVE_220:
						face_data.u_axis = Vector3(
							face.u_offset.x, face.u_offset.y, face.u_offset.z
						).normalized()
						face_data.v_axis = Vector3(
							face.v_offset.x, face.v_offset.y, face.v_offset.z
						).normalized()
					face_data.surface_flag = face.surface_flag
					face_data.content_flag = face.contents_flag
					brush_data.faces.append(face_data)
				for face_data in brush_data.faces: face_data.is_trigger = brush_data.is_trigger
				data.brushes.append(brush_data)
			_solid_data[entity] = data
		else: _solid_data[entity] = null

## Fill [member _wads] with preloaded wads
func _include_preloaded_wads() -> void:
	_wads = settings.extra_wads
	for wad in settings.extra_wads:
		if verbose: print("\t\t-Including WAD: %s"%wad.resource_path)
		_current_wad_paths.append(wad.resource_path)

## Fill [member _wads] with map specific wads
func _load_wads(index: int) -> void:
	for base_path in settings.get_paths_wads(map.mods):
		if _current_wad_paths.has("%s/%s"%[base_path, map.wad_paths[index]]): continue
		if ResourceLoader.exists("%s/%s"%[base_path, map.wad_paths[index]]):
			if verbose: print("\t\t-Loading WAD: %s"%map.wad_paths[index])
			var wad: WAD = ResourceLoader.load("%s/%s"%[base_path, map.wad_paths[index]])
			if wad != null:
				_wads.append(wad)
				return
	printerr("\t\t-Missing WAD: %s"%map.wad_paths[index])

## Create materials for [member _materials]
func _generate_materials(index: int) -> void:
	var texturename: StringName = _materials.keys()[index]
	## Ignore generation if empty or non-rendered texture
	for texture in settings.empty_textures:
		if texturename.to_lower() == texture.to_lower(): return
	if !show_non_rendered_textures && !_is_render_texture(texturename): return
	## Find texture and material
	var texture := _find_texture_or_animated(texturename)
	var material := _find_material(texturename)
	## Apply texture to material if not null
	if texture != null:
		material.set(settings.default_material_texture_path, texture)
		_textures[texturename] = texture
		_texture_sizes[texturename] = texture.get_size()
	## Generate PBR (Will not generate for animated textures)
	if settings.use_pbr:
		var pbr_texture: Texture2D
		pbr_texture = _find_texture_or_animated("%s%s"%[texturename, settings.suffix_normal])
		if pbr_texture != null:
			material.set("normal_enabled", true)
			material.set("normal_texture", pbr_texture)
		var normal_texture := _find_texture_or_animated("%s%s"%[texturename, settings.suffix_metallic])
		if pbr_texture != null: material.set("metallic_texture", pbr_texture)
		pbr_texture = _find_texture_or_animated("%s%s"%[texturename, settings.suffix_roughness])
		if pbr_texture != null: material.set("roughness_texture", pbr_texture)
		pbr_texture = _find_texture_or_animated("%s%s"%[texturename, settings.suffix_emission])
		if pbr_texture != null:
			material.set("emission_enabled", true)
			material.set("emission_texture", pbr_texture)
		pbr_texture = _find_texture_or_animated("%s%s"%[texturename, settings.suffix_ao])
		if pbr_texture != null:
			material.set("ao_enabled", true)
			material.set("ao_texture", pbr_texture)
		pbr_texture = _find_texture_or_animated("%s%s"%[texturename, settings.suffix_height])
		if pbr_texture != null:
			material.set("heightmap_enabled", true)
			material.set("heightmap_texture", pbr_texture)
	## Set material
	_materials[texturename] = material

## Find either texture or animated texture
func _find_texture_or_animated(texturename: StringName) -> Texture2D:
	var is_animated: bool = false
	var base_prefix: String
	var base_num: int
	var base_char: String
	var trim: String
	if settings.allow_animated_textures:
		for prefix in settings.animated_texture_prefixes: for num in 10:
			if texturename.begins_with("%s%s"%[prefix,num]):
				is_animated = true
				base_prefix = prefix
				base_num = num
				trim = "%s%s"%[base_prefix,base_num]
				break
		for prefix in settings.animated_texture_prefixes: for char in "ABCDEFGHIJKLMNOPQRSTUVWXYZ":
			if texturename.begins_with("%s%s"%[prefix,char]):
				is_animated = true
				base_prefix = prefix
				base_char = char
				trim = "%s%s"%[base_prefix,base_char]
				break
	if is_animated:
		var animated_texture := AnimatedTexture.new()
		var textures: Array[Texture2D]
		for num in 10:
			var texture := _find_texture("%s%s%s"%[
				base_prefix,
				num,
				texturename.trim_prefix(trim)
			])
			if texture != null: textures.append(texture)
		var alt_textures: Array[Texture2D]
		var alt_dictionary: Dictionary[String, int]
		for char in "ABCDEFGHIJKLMNOPQRSTUVWXYZ":
			var texture := _find_texture("%s%s%s"%[
				base_prefix,
				char,
				texturename.trim_prefix(trim)
			])
			if texture != null:
				textures.append(texture)
				alt_dictionary[char] = textures.size()
		if textures.size() + alt_textures.size() < 1: return _find_texture(texturename)
		animated_texture.frames = textures.size() + alt_textures.size()
		if base_num < textures.size(): animated_texture.current_frame = base_num
		for n in textures.size():
			animated_texture.set_frame_texture(n, textures[n])
		for n in alt_textures.size():
			animated_texture.set_frame_texture(n + textures.size(), alt_textures[n])
			animated_texture.set_frame_duration(n + textures.size(), 0)
			alt_dictionary[alt_dictionary.keys()[n]] = n + textures.size()
		animated_texture.speed_scale = textures.size() * settings.animated_texture_speed_scale
		animated_texture.set_meta(&"alt_tex_indices", alt_dictionary)
		if base_char != "":
			animated_texture.current_frame = alt_dictionary.get(base_char, 0)
			animated_texture.pause = true
		return animated_texture
	else: return _find_texture(texturename)

## Find relevant texture
func _find_texture(texturename: StringName) -> Texture2D:
	var texture_filename: String = texturename.to_lower().validate_filename() # Filesystem safe name
	var texture_wad_name: String = texturename.to_lower() # Wad safe name
	## Search filesystem first
	for path in settings.get_paths_textures(map.mods): for extension in settings.texture_extensions:
		if ResourceLoader.exists("%s/%s.%s"%[path, texture_filename, extension]):
			return ResourceLoader.load("%s/%s.%s"%[path, texture_filename, extension])
	## Search wads second
	for wad in _wads:
		if !wad.textures.has(texture_wad_name): continue
		return wad.textures[texture_wad_name]
	return null

## Find relevant material
func _find_material(texturename: StringName) -> Material:
	var texture_filename: String = texturename.to_lower().validate_filename() # Filesystem safe name
	for path in settings.get_paths_materials(map.mods): for extension in settings.material_extensions:
		if ResourceLoader.exists("%s/%s.%s"%[path, texture_filename, extension]):
			return ResourceLoader.load("%s/%s.%s"%[path, texture_filename, extension])
	if settings.default_material != null:
		return settings.default_material.duplicate()
	return StandardMaterial3D.new()

## Detect Alphatest textures in [member _materials] (not thread safe)
func _detect_alphatest(index: int) -> void:
	var texturename: StringName = _textures.keys()[index]
	var texture: Texture2D = _textures[texturename]
	if texture == null: return
	var image := texture.get_image()
	for x in image.get_width(): for y in image.get_height():
		if image.get_pixel(x, y).a < 1:
			_alphatests[texturename] = true
			var material := _materials[texturename]
			if material != null:
				material.set(settings.default_material_transparency_path, settings.transparency_alphatest_value)
			return

## Generate nodes for entities
func _generate_entities(index: int) -> void:
	var entity: QEntity = _entities.keys()[index]
	if !settings.fgd.classes.has(entity.classname):
		if entity.brushes.size() > 0:
			_entities[entity] = StaticBody3D.new()
		else:
			_entities[entity] = Node.new()
		return
	for path in settings.get_paths_scenes(map.mods): for extension in ["tscn","scn"]:
		if ResourceLoader.exists("%s/%s.%s"%[path, entity.classname.replace(".", "/"), extension]):
			var scene: PackedScene = ResourceLoader.load("%s/%s.%s"%[path, entity.classname.replace(".", "/"), extension])
			if scene != null:
				_entities[entity] = scene.instantiate()
				_get_target_destinations(entity, _entities[entity])
				return
	if entity.brushes.size() > 0:
		_entities[entity] = StaticBody3D.new()
	else:
		_entities[entity] = Node3D.new()
	_get_target_destinations(entity, _entities[entity])
	return

## Checks if node should be added to [member _target_destinations]
func _get_target_destinations(entity: QEntity, node: Node) -> void:
	if settings.fgd.classes.has(entity.classname):
		for key in entity.properties.keys():
			if settings.fgd.classes[entity.classname].properties.has(key):
				if settings.fgd.classes[entity.classname].properties[key].type == FGDEntityProperty.PropertyType.TARGET_DESTINATION:
					_target_destinations[entity.properties[key]] = node

## Find vertices, normals, and tangents
func _generate_solid_data(index: int) -> void:
	var entity: QEntity = _solid_data.keys()[index]
	var data: SolidData = _solid_data[entity]
	if data == null: return
	for brush in data.brushes:
		# Find all brush vertices
		var vertices := Geometry3D.compute_convex_mesh_points(brush.planes)
		# Find vertices
		for face in brush.faces:
			for vertex in vertices:
				if face.plane.has_point(vertex, 1e-04):
					face.vertices.append(vertex)
			# Sort vertices
			if face.vertices.size() < 3: continue
			var center: Vector3
			for vertex in face.vertices: center += vertex
			center /= face.vertices.size()
			var u_axis: Vector3
			if face.vertices.size() >= 2:
				u_axis = (face.vertices[1] - face.vertices[0]).normalized()
			var v_axis: Vector3 = u_axis.cross(face.plane.normal).normalized()
			var cmp_winding_angle: Callable = (
				func(a: Vector3, b: Vector3) -> bool:
					var dir_a: Vector3 = a - center
					var dir_b: Vector3 = b - center
					var angle_a: float = atan2(dir_a.dot(v_axis), dir_a.dot(u_axis))
					var angle_b: float = atan2(dir_b.dot(v_axis), dir_b.dot(u_axis))
					return angle_a < angle_b
			)
			var _vertices: Array[Vector3]
			_vertices.assign(face.vertices)
			_vertices.sort_custom(cmp_winding_angle)
			face.vertices = _vertices
		# Generate normals
		for face in brush.faces:
			face.normals.resize(face.vertices.size())
			face.normals.fill(face.plane.normal)
		# Generate tangents
		for face in brush.faces:
			var tangent: PackedFloat32Array
			if face.uv_format == QEntity.FaceFormat.VALVE_220:
				var v_sign: float = -signf(face.plane.normal.cross(face.u_axis).dot(face.v_axis))
				tangent = [face.u_axis.x, face.u_axis.y, face.u_axis.z, v_sign]
			else: # Standard
				var dx := face.plane.normal.dot(Vector3.BACK)
				var dy := face.plane.normal.dot(Vector3.UP)
				var dz := face.plane.normal.dot(Vector3.RIGHT)
				var dxa := absf(dx)
				var dya := absf(dy)
				var dza := absf(dz)
				var u_axis: Vector3
				var v_sign: float = 0.0
				if dya >= dxa and dya >= dza:
					u_axis = Vector3.RIGHT
					v_sign = signf(dy)
				elif dxa >= dya and dxa >= dza:
					u_axis = Vector3.RIGHT
					v_sign = -signf(dx)
				elif dza >= dya and dza >= dxa:
					u_axis = Vector3.UP
					v_sign = signf(dz)
				v_sign *= signf(face.uv.get_scale().y)
				u_axis = u_axis.rotated(face.plane.normal, deg_to_rad(-face.uv.get_rotation()) * v_sign)
				tangent = [u_axis.x, u_axis.y, u_axis.z, v_sign]
			# Translate to Y Z X W coordinates
			for vertex in face.vertices:
				face.tangents.append(tangent[1])
				face.tangents.append(tangent[2])
				face.tangents.append(tangent[0])
				face.tangents.append(tangent[3])
			

## Calculate solid entity origins
func _calculate_origins(index: int) -> void:
	var entity: QEntity = _solid_data.keys()[index]
	var data: SolidData = _solid_data[entity]
	if data == null: return
	# "origin" property will take priority
	if entity.properties.has(&"origin"): return
	# Otherwise use entity center bounds as origin
	var entity_mins: Vector3 = Vector3.INF
	var entity_maxs: Vector3 = Vector3.INF
	var origin_mins: Vector3 = Vector3.INF
	var origin_maxs: Vector3 = -Vector3.INF
	for brush in data.brushes:
		for face in brush.faces:
			for vertex in face.vertices:
				if entity_mins != Vector3.INF:
					entity_mins = entity_mins.min(vertex)
				else:
					entity_mins = vertex
				if entity_maxs != Vector3.INF:
					entity_maxs = entity_maxs.max(vertex)
				else:
					entity_maxs = vertex
				if brush.is_origin:
					if origin_mins != Vector3.INF:
						origin_mins = origin_mins.min(vertex)
					else:
						origin_mins = vertex
					if origin_maxs != Vector3.INF:
						origin_maxs = origin_maxs.max(vertex)
					else:
						origin_maxs = vertex
	if entity_maxs != Vector3.INF and entity_mins != Vector3.INF:
		data.origin = entity_maxs - ((entity_maxs - entity_mins) * 0.5)

## Create triangle indices
func _index_faces(index: int) -> void:
	var entity: QEntity = _solid_data.keys()[index]
	var data: SolidData = _solid_data[entity]
	if data == null: return
	for brush in data.brushes: for face in brush.faces:
		var triangle_count := face.vertices.size() - 2
		if triangle_count < 1: continue
		face.indices.resize(triangle_count * 3)
		var i := 0
		for n in triangle_count:
			face.indices[i] = 0
			face.indices[i + 1] = n + 1
			face.indices[i + 2] = n + 2
			i += 3

## Apply "_phong" to normals
func _smooth_normals(index: int) -> void:
	var entity: QEntity = _solid_data.keys()[index]
	var data: SolidData = _solid_data[entity]
	if !entity.phong: return
	if data == null: return
	for brush in data.brushes: for face in brush.faces: for other_face in brush.faces:
		if face == other_face: continue
		var intersection: PackedInt32Array
		intersection.resize(face.normals.size())
		intersection.fill(1)
		var normals: PackedVector3Array = face.normals.duplicate()
		for n in face.vertices.size(): if other_face.vertices.has(face.vertices[n]):
			if normals[n].angle_to(other_face.plane.normal) > deg_to_rad(entity.phong_angle):
				continue
			normals[n] += other_face.plane.normal
			intersection[n] += 1
			break
		for n in normals.size():
			normals[n] /= intersection[n]
		face.normals = normals

func _sort_brushes(index: int) -> void:
	var entity: QEntity = _solid_data.keys()[index]
	var data: SolidData = _solid_data[entity]
	if data == null: return
	var sorted_brushes: Array[SolidData.BrushData]

## Sort faces in order of matching textures
func _sort_faces(index: int) -> void:
	var entity: QEntity = _solid_data.keys()[index]
	var data: SolidData = _solid_data[entity]
	if data == null: return
	for brush in data.brushes:
		if brush.is_origin: continue
		var texture_faces: Dictionary[StringName, Array]
		for face in brush.faces:
			if !texture_faces.has(face.texture): texture_faces[face.texture] = []
			texture_faces[face.texture].append(face)
		for key in texture_faces.keys():
			if data.sorted_faces.has(key): data.sorted_faces[key].append_array(texture_faces[key])
			else: data.sorted_faces[key] = texture_faces[key]

## Generate meshes
func _generate_meshes(index: int) -> void:
	var entity: QEntity = _solid_data.keys()[index]
	var data: SolidData = _solid_data[entity]
	var use_occlusion_culling: bool = ProjectSettings.get_setting("rendering/occlusion_culling/use_occlusion_culling", false)
	if data == null: return
	var arrays: Array
	arrays.resize(Mesh.ARRAY_MAX)
	var arrays_collision: Array
	var arrays_shadow: Array
	arrays_collision.resize(Mesh.ARRAY_MAX)
	arrays_shadow.resize(Mesh.ARRAY_MAX)
	data.render_mesh = ArrayMesh.new()
	data.collision_mesh = ArrayMesh.new()
	var shadow_mesh = ArrayMesh.new()
	var occluder_vertices: PackedVector3Array
	var occluder_indices: PackedInt32Array
	arrays_collision[Mesh.ARRAY_VERTEX] = PackedVector3Array()
	arrays_shadow[Mesh.ARRAY_VERTEX] = PackedVector3Array()
	var texturenames: Array[StringName] = data.sorted_faces.keys()
	texturenames.sort()
	for texture in texturenames:
		if _is_render_texture(texture) && _is_render_class(entity.classname):
			var render_surface := data.render_mesh.get_surface_count()
			if render_surface == RenderingServer.MAX_MESH_SURFACES:
				printerr("Cannot render additional mesh surfaces on %s!"%entity.classname)
				continue
			arrays[Mesh.ARRAY_VERTEX] = PackedVector3Array()
			arrays[Mesh.ARRAY_NORMAL] = PackedVector3Array()
			arrays[Mesh.ARRAY_TANGENT] = PackedFloat32Array()
			arrays[Mesh.ARRAY_TEX_UV] = PackedVector2Array()
			#arrays[Mesh.ARRAY_COLOR] = PackedColorArray()
			for face in data.sorted_faces[texture]:
				if !_is_render_content_flag(face.content_flag) || !_is_render_surface_flag(face.surface_flag): continue
				for i in face.indices:
					arrays[Mesh.ARRAY_VERTEX].append(
						_convert_coordinates(face.vertices[i] - data.origin) * settings._scale_factor
						)
					arrays[Mesh.ARRAY_NORMAL].append(_convert_coordinates(face.normals[i]))
					arrays[Mesh.ARRAY_TANGENT].append(face.tangents[i * 4])
					arrays[Mesh.ARRAY_TANGENT].append(face.tangents[i * 4 + 1])
					arrays[Mesh.ARRAY_TANGENT].append(face.tangents[i * 4 + 2])
					arrays[Mesh.ARRAY_TANGENT].append(face.tangents[i * 4 + 3])
					arrays[Mesh.ARRAY_TEX_UV].append(_get_tex_uv(face, face.vertices[i]))
					if use_occlusion_culling && !_alphatests.get(texture, false):
						var vertex: Vector3 = arrays[Mesh.ARRAY_VERTEX][arrays[Mesh.ARRAY_VERTEX].size() - 1]
						var occluder_index := occluder_vertices.find(vertex)
						if occluder_index == -1:
							occluder_index = occluder_vertices.size()
							occluder_vertices.append(vertex)
						occluder_indices.append(occluder_index)
			if arrays[Mesh.ARRAY_VERTEX].size() > 0:
				data.render_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
				data.render_mesh.surface_set_material(render_surface, _materials[texture])
				data.render_mesh.surface_set_name(render_surface, texture)
				arrays_shadow[Mesh.ARRAY_VERTEX] = arrays[Mesh.ARRAY_VERTEX]
				shadow_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays_shadow)
		for face in data.sorted_faces[texture]:
			for i in face.indices:
				arrays_collision[Mesh.ARRAY_VERTEX].append(
					_convert_coordinates(face.vertices[i] - data.origin) * settings._scale_factor
					)
	if arrays_collision[Mesh.ARRAY_VERTEX].size() > 0:
		data.collision_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays_collision)
	else:
		data.collision_mesh = null
	if data.render_mesh.get_surface_count() > 0:
		data.render_mesh.shadow_mesh = shadow_mesh
	else:
		data.render_mesh = null
	if use_occlusion_culling && occluder_vertices.size() > 0:
		data.occluder = ArrayOccluder3D.new()
		data.occluder.set_arrays(occluder_vertices, occluder_indices)
	else:
		data.occluder == null
	# Generate convex trigger meshes
	for brush in data.brushes:
		var convex_mesh := ArrayMesh.new()
		var convex_arrays: Array
		convex_arrays.resize(Mesh.ARRAY_MAX)
		convex_arrays[Mesh.ARRAY_VERTEX] = PackedVector3Array()
		for face in brush.faces:
			for i in face.indices:
				convex_arrays[Mesh.ARRAY_VERTEX].append(
					_convert_coordinates(face.vertices[i] - data.origin) * settings._scale_factor
					)
		if convex_arrays[Mesh.ARRAY_VERTEX].size() > 0:
			convex_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, convex_arrays)
			data.convex_meshes.append(convex_mesh)

## Unrwaps render mesh UV for lightmapping
func _unwrap_uvs(index: int) -> void:
	var entity: QEntity = _solid_data.keys()[index]
	var data: SolidData = _solid_data[entity]
	if data == null || data.render_mesh == null: return
	data.render_mesh.lightmap_unwrap(Transform3D.IDENTITY, 1.0 / settings.uv_unwrap_texel_ratio)

## Returns true if texture should be rendered
func _is_render_texture(texture: StringName) -> bool:
	if show_non_rendered_textures: return true
	for pattern in settings.get_non_rendered_textures():
		if texture.to_lower().match(pattern.to_lower()): return false
	return true

## Returns true if classname should be rendered
func _is_render_class(classname: String) -> bool:
	if show_non_rendered_textures: return true
	for pattern in settings.get_non_rendered_entities():
		if classname.to_lower().match(pattern.to_lower()): return false
	return true

## Returns true if surface flag should be rendered
func _is_render_surface_flag(flag: int) -> bool:
	if show_non_rendered_textures: return true
	for pattern in settings.get_non_rendered_surfaces():
		if pattern == 0: continue
		if flag & pattern: return false
	return true

## Returns true if content flag should be rendered
func _is_render_content_flag(flag: int) -> bool:
	if show_non_rendered_textures: return true
	for pattern in settings.get_non_rendered_content():
		if pattern == 0: continue
		if flag & pattern: return false
	return true

func _get_tex_uv(face: SolidData.FaceData, vertex: Vector3) -> Vector2:
	var tex_uv := Vector2.ONE
	var texture_size: Vector2 = _texture_sizes[face.texture]
	if face.uv_format == QEntity.FaceFormat.VALVE_220:
		tex_uv = Vector2(face.u_axis.dot(vertex), face.v_axis.dot(vertex))
		tex_uv += (face.uv.origin * face.uv.get_scale())
		tex_uv.x /= face.uv.x.x
		tex_uv.y /= face.uv.y.y
		tex_uv.x /= texture_size.x
		tex_uv.y /= texture_size.y
	else: # Standard
		var nx := absf(face.plane.normal.dot(Vector3.RIGHT))
		var ny := absf(face.plane.normal.dot(Vector3.UP))
		var nz := absf(face.plane.normal.dot(Vector3.FORWARD))
		if ny >= nx and ny >= nz:
			tex_uv = Vector2(vertex.x, -vertex.z)
		elif nx >= ny and nx >= nz:
			tex_uv = Vector2(vertex.y, -vertex.z)
		else:
			tex_uv = Vector2(vertex.x, vertex.y)
		tex_uv = tex_uv.rotated(face.uv.get_rotation())
		tex_uv /= face.uv.get_scale()
		tex_uv += face.uv.origin
		tex_uv /= texture_size
	return tex_uv

func _pass_to_scene_tree() -> void:
	# Find worldspawn and apply special properties
	for entity: QEntity in _entities.keys():
		if entity.classname == "worldspawn":
			_worldspawn_generation(entity.properties, _entities[entity])
			break
	# Pass entities to SceneTree
	for entity: QEntity in _entities.keys():
		var data: SolidData = _solid_data[entity]
		var node := _entities[entity]
		node.name = entity.classname.capitalize().replace(" ", "")
		# Apply position, rotation, and scale modifications
		if data != null:
			node.set(&"position", _convert_coordinates(data.origin) * settings._scale_factor)
		else:
			node.set(&"position", _convert_coordinates(entity.origin) * settings._scale_factor)
			node.set(&"rotation_degrees", entity.angle)
			var current_scale = node.get(&"scale")
			if current_scale != null: node.set(&"scale", current_scale * entity.scale)
		var parsed_properties := entity.get_parsed_properties(settings, map.mods)
		for key in parsed_properties.keys():
			# Set properties on node if they are present in FGD as well
			if settings.fgd.classes.has(entity.classname) && settings.fgd.classes[entity.classname].properties.has(key):
				if settings.fgd.classes[entity.classname].properties[key].type == FGDEntityProperty.PropertyType.TARGET_SOURCE:
					# Update target_destination properties to Node references
					if _target_destinations.has(parsed_properties[key]):
						parsed_properties[key] = _target_destinations[parsed_properties[key]]
					else: parsed_properties[key] = null
				node.set(key, parsed_properties[key])
		# Pass parsed_properties to node via _apply_map_properties method
		if node.has_method(&"_apply_map_properties"):
			node.call(&"_apply_map_properties", parsed_properties)
		# Add mesh
		if data != null:
			if data.render_mesh != null && entity.geometry_flags & QEntity.GeometryFlags.RENDER:
				var mesh_instance := MeshInstance3D.new()
				mesh_instance.mesh = data.render_mesh
				mesh_instance.name = "RenderMesh"
				_entities[entity].add_child(mesh_instance)
			if data.convex_meshes.size() > 0  && entity.geometry_flags & QEntity.GeometryFlags.CONVEX_COLLISIONS:
				var count: int = 0
				for convex_mesh in data.convex_meshes:
					var collision_instance := CollisionShape3D.new()
					collision_instance.shape = convex_mesh.create_convex_shape()
					collision_instance.name = "CConvex%s"%count
					_entities[entity].add_child(collision_instance)
					count += 1
			elif data.collision_mesh != null && entity.geometry_flags & QEntity.GeometryFlags.CONCAVE_COLLISIONS:
				var collision_instance := CollisionShape3D.new()
				collision_instance.shape = data.collision_mesh.create_trimesh_shape()
				collision_instance.name = "CTrimesh"
				_entities[entity].add_child(collision_instance)
			if data.occluder != null && entity.geometry_flags & QEntity.GeometryFlags.OCCLUSION:
				var occluder_instance := OccluderInstance3D.new()
				occluder_instance.occluder = data.occluder
				occluder_instance.name = "Occluder"
				_entities[entity].add_child(occluder_instance)
		add_child(node, true)

## Generate special worldspawn node properties
func _worldspawn_generation(properties: Dictionary[StringName, String], node: Node) -> void:
	# World Enviroment generation
	if settings.worldspawn_generate_enviroment:
		var world_env: WorldEnvironment
		var already_has_node: bool
		# Use child [WorldEnvironment] if present
		for child in node.get_children():
			if child is WorldEnvironment:
				world_env = child
				already_has_node = true
				break
		if !already_has_node:
			world_env = WorldEnvironment.new()
			world_env.name = "Enviroment"
			node.add_child(world_env)
		# Create [Environment] if none present
		if world_env.environment == null: world_env.environment = Environment.new()
		# Ambient light
		world_env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		world_env.environment.ambient_light_energy = properties.get(settings.worldspawn_ambient_light, settings.default_ambient_light).to_float()
		var color_raw: PackedStringArray = properties.get(settings.worldspawn_ambient_color, settings.default_ambient_color).split(" ", false)
		if color_raw.size() >= 3:
			world_env.environment.ambient_light_color = Color8(
				color_raw[0].to_float(),
				color_raw[1].to_float(),
				color_raw[2].to_float()
			)
		# SSAO (could we ever bake AO into mesh during loading?)
		world_env.environment.ssao_enabled = bool(properties.get(settings.worldspawn_ao_enabled, settings.default_ao_enabled).to_int())
		world_env.environment.ssao_intensity = properties.get(settings.worldspawn_ao_intensity, settings.default_ao_intensity).to_float()
		world_env.environment.ssao_radius = properties.get(settings.worldspawn_ao_radius, settings.default_ao_radius).to_float()
		# Sky material
		var skyname: String = properties.get(settings.worldspawn_skyname, settings.default_skyname)
		var sky_texture: Texture2D
		if skyname != "":
			for path in settings.get_paths_textures(map.mods): for extension in settings.texture_extensions:
				if ResourceLoader.exists("%s/%s.%s"%[path, skyname, extension]):
					sky_texture= ResourceLoader.load("%s/%s.%s"%[path, skyname, extension])
		if sky_texture != null:
			world_env.environment.background_mode = Environment.BG_SKY
			world_env.environment.sky = Sky.new()
			if settings.custom_sky_material != null:
				world_env.environment.sky.sky_material = settings.custom_sky_material
			else:
				world_env.environment.sky.sky_material = PanoramaSkyMaterial.new()
			for path in settings.get_paths_textures(map.mods): for extension in settings.texture_extensions:
				if ResourceLoader.exists("%s/%s.%s"%[path, skyname, extension]):
					if settings.custom_sky_material != null:
						world_env.environment.sky.sky_material.set(settings.custom_sky_texture_path, sky_texture)
					else:
						world_env.environment.sky.sky_material.panorama = sky_texture
			if !properties.has(settings.worldspawn_ambient_color):
				world_env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	# Sunlight generation
	if settings.worldspawn_generate_sunlight:
		var dir_light: DirectionalLight3D
		var already_has_node: bool
		# Use child [DirectionalLight3D] if present
		for child in node.get_children():
			if child is DirectionalLight3D:
				dir_light = child
				already_has_node = true
				break
		if !already_has_node:
			dir_light = DirectionalLight3D.new()
			dir_light.name = "Sunlight"
			node.add_child(dir_light)
		dir_light.light_bake_mode = Light3D.BAKE_STATIC
		dir_light.light_energy = properties.get(settings.worldspawn_sunlight, settings.default_sunlight).to_float()
		dir_light.shadow_enabled = bool(properties.get(settings.worldspawn_sun_shadows, settings.default_sun_shadows).to_int())
		dir_light.light_angular_distance = properties.get(settings.worldspawn_sun_penumbra, settings.default_sun_penumbra).to_float()
		var raw_angle: PackedStringArray = properties.get(settings.worldspawn_sun_angle, settings.default_sun_angle).split(" ", false)
		if raw_angle.size() >= 3:
			dir_light.rotation_degrees = Vector3(
				raw_angle[0].to_float(),
				raw_angle[1].to_float(),
				raw_angle[2].to_float()
			)
		var raw_color: PackedStringArray = properties.get(settings.worldspawn_sun_color, settings.default_sun_color).split(" ", false)
		if raw_color.size() >= 3:
			dir_light.light_color = Color8(
				raw_color[0].to_float(),
				raw_color[1].to_float(),
				raw_color[2].to_float()
			)
