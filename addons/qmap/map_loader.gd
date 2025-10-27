## Loads [QMap] as a child of this node
##
## [url]https://1666186240-files.gitbook.io/~/files/v0/b/gitbook-x-prod.appspot.com/o/spaces%2F-LtVT8pJjInrrHVCovzy%2Fuploads%2FEukkFYJLwfafFXUMpsI2%2FMAPFiles_2001_StefanHajnoczi.pdf?alt=media&token=51471685-bf69-42ae-a015-a474c0b95165[/url]
class_name MapLoader extends Node3D

const VERTEX_MERGE_DISTANCE := 3e-03
const HYPERPLANE_SIZE := 512.0
## Replaces "*" in texturename and "/*" in glob patterns for for texturenames
const ASTRSK_ALT_CHAR := "|"

## Data used for building geometry
class SolidData extends RefCounted:
	class BrushData extends RefCounted:
		var faces: Array[FaceData]
		var planes: Array[Plane]
		var is_origin: bool
		var is_trigger: bool
		var mesh: ArrayMesh
		var collision_mesh: ArrayMesh
		var occlusion_mesh: ArrayMesh
		var pathfinding_mesh: ArrayMesh
		var sorted_faces: Dictionary[StringName, Array]
		func _to_string() -> String: return "BrushData(F: %s)"%faces.size()
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
		var override_texture: StringName
		var is_trigger: bool
		var surface_flag: int
		var content_flag: int
		var value: int
		func _to_string() -> String: return "%s(V:%s F:(%s %s))"%[texture, vertices.size(), surface_flag, content_flag]
	var brushes: Array[BrushData]
	var origin: Vector3
	var render_mesh: ArrayMesh
	var collision_mesh: ArrayMesh
	var convex_meshes: Array[ArrayMesh]
	var occluder: ArrayOccluder3D
	var sorted_faces: Dictionary[StringName, Array]
	var expected_surface_count: int
	func _to_string() -> String: return "SolidData(B: %s)"%brushes.size()

## Emitted at map loading stages (value from 0.0-1.0)
signal progress(percentage: float, task: String)

## Static reference to last [MapLoader] added to [SceneTree]. May return null
static var current: MapLoader

## Path to [QMap] to load on [method load_map]
@export_file("*.map") var map_path: String
## [QMap] to load on [method load_map]
var map: QMap
## Settings to use for generation
@export var settings: QMapSettings = preload("res://addons/qmap/default_resources/default_settings.tres")
@export_group("Additional Settings")
## If true, will automatically call [method load_map] during [method _ready]
@export var auto_load_map: bool = true
## When true will load any [WAD] listed in [QMap] properties under the key "wads"
@export var auto_load_internal_wads: bool = true
## While true main thread will be paused during loading (may improve loading speed)
@export var pause_main_thread_while_loading: bool = true
## While true, groups and layers will be grouped together under a [Node3D]
@export var group_nodes: bool = true
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
var _nav_regions: Array[NavigationRegion3D]

## Spawns a new entity with specified [param properties] and [param classname]
func spawn_entity(classname: String, properties: Dictionary[StringName, String] = {}, origin := Vector3.ZERO) -> Node:
	var entity := QEntity.new()
	var node: Node
	entity.properties.assign(properties)
	entity.classname = classname
	origin *= settings.scaling
	entity.properties.set(&"origin", "%s %s %s"%[origin.z, origin.x, origin.y])
	entity.add_base_properties(settings.fgd)
	if !settings.fgd.classes.has(entity.classname): node = Node.new()
	else:
		for path in settings.get_paths_scenes(map.mods): for extension in ["tscn","scn"]:
			if ResourceLoader.exists("%s/%s.%s"%[path, entity.classname.replace(".", "/"), extension]):
				var scene: PackedScene = ResourceLoader.load("%s/%s.%s"%[path, entity.classname.replace(".", "/"), extension])
				if scene != null:
					node = scene.instantiate()
	if node == null: node = Node3D.new()
	node.name = entity.classname.capitalize().replace(" ", "")
	node.set(&"position", _convert_coordinates(entity.origin * settings._scale_factor))
	node.set(&"rotation_degrees", entity.angle)
	var current_scale = node.get(&"scale")
	if current_scale != null: node.set(&"scale", current_scale * entity.scale)
	var parsed_properties := entity.get_parsed_properties(settings, map.mods)
	for key in parsed_properties.keys():
		if settings.fgd.classes.has(entity.classname) && settings.fgd.classes[entity.classname].properties.has(key):
			if settings.fgd.classes[entity.classname].properties[key].type == FGDEntityProperty.PropertyType.TARGET_SOURCE:
				parsed_properties[key] = find_target_destination(parsed_properties[key])
			node.set(key, parsed_properties[key])
	if node.has_method(&"_apply_map_properties"):
		node.call(&"_apply_map_properties", parsed_properties)
	add_child(node)
	return node

## Allows a node to be discovered via [method find_target_destination]
func set_target_destination(target_name: String, node: Node) -> void:
	if node == null: printerr("Cannot set target destination on NULL node")
	node.add_to_group(&"target_destination")
	node.set_meta(&"target_destination", target_name)

## Attempts to find a target destination (NOTE: node must be child of this [MapLoader])
func find_target_destination(target_name: String) -> Node:
	for node in get_tree().get_nodes_in_group(&"target_destination"):
		if node.get_parent() == self || node.get_parent().get_parent() == self:
			if node.get_meta(&"target_destination", "") == target_name: return node
	return null

## Returns list of spawned entities, use [param filter] with * and ? wildcards
## to filter by node name (typically this is entity classname)
## (NOTE: Only returns nodes that are children of this [MapLoader])
func get_entities(filter: String) -> Array[Node]:
	var output: Array[Node]
	for node in get_tree().get_nodes_in_group(&"entity"):
		if node.get_parent() == self || node.get_parent().get_parent() == self:
			if node.name.match(filter): output.append(node)
	return output

func _enter_tree() -> void:
	current = self

func _exit_tree() -> void:
	if current == self: current = null

func _ready() -> void:
	if auto_load_map: await load_map()

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
	if !ResourceLoader.exists(map_path):
		if map_path.begins_with("uid://"):
			printerr("Cannot find map to parse: %s"%ResourceUID.get_id_path(ResourceUID.text_to_id(map_path)))
		else:
			printerr("Cannot find map to parse: %s"%map_path)
		return ERR_FILE_NOT_FOUND
	if settings == null:
		printerr("Missing MapSettings to generate with!")
		return ERR_FILE_NOT_FOUND
	var start_time := Time.get_ticks_msec()
	if verbose:
		if map_path.begins_with("uid://"):
			print("Generating map '%s'..."%ResourceUID.get_id_path(ResourceUID.text_to_id(map_path)))
		else:
			print("Generating map '%s'..."%map_path)
	progress.emit(0, "Parsing map")
	await _thread_individual_taks([
			func():
				map = ResourceLoader.load(map_path) as QMap
				],
			"Parsing map")
	if map == null:
		printerr("Unable to parse map!")
		progress.emit(1, "Failed")
		return ERR_FILE_NOT_FOUND
	progress.emit(0.05, "Initializing")
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
	await _pass_to_scene_tree()
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
	_nav_regions.clear()
	if verbose: print("Finished generating map in %sms"%(Time.get_ticks_msec() - start_time))
	progress.emit(1, "Finished")
	return OK

## Clears all children node for reloading map
func clear_children() -> void:
	for child in get_children(): child.queue_free()

## Fill [member _materials]
func _create_texture_map() -> void:
	var placeholder := PlaceholderMaterial.new()
	var registered_materials: PackedStringArray
	for texturename in map.texturenames:
		_materials[texturename] = placeholder
		_textures[texturename] = null
		_texture_sizes[texturename] = settings.default_uv_scale * settings.scaling
		_alphatests[texturename] = false
		registered_materials.append(texturename)
	for tag in settings.smart_tags:
		if tag.override_material == null: continue
		for entity in map.entities: for brush in entity.brushes: for face in brush.faces:
			var mat_name: String = ""
			match tag.match_type:
				QMapSmartTag.MatchType.CLASSNAME:
					if entity.classname.to_lower().match(tag.pattern.to_lower()):
						mat_name = "%s|%s|%s"%[tag.name, face.texturename, entity.classname]
				QMapSmartTag.MatchType.SURFACE_FLAG:
					if tag.pattern.to_int() != 0 && face.surface_flag & tag.pattern.to_int():
						var value: float = face.value / (pow(10.0, tag.value_places))
						mat_name = "%s|%s|%s"%[tag.name, face.texturename, value]
				QMapSmartTag.MatchType.CONTENT_FLAG:
					if tag.pattern.to_int() != 0 && face.contents_flag & tag.pattern.to_int():
						var value: float = face.value / (pow(10.0, tag.value_places))
						mat_name = "%s|%s|%s"%[tag.name, face.texturename, value]
			if mat_name.is_empty(): continue
			face.set_meta(&"override", mat_name)
			if registered_materials.has(mat_name): continue
			_materials[mat_name] = placeholder
			_textures[mat_name] = null
			_texture_sizes[mat_name] = settings.default_uv_scale * settings.scaling
			_alphatests[mat_name] = false
			registered_materials.append(mat_name)

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
			data.origin = entity.origin * settings._scale_factor
			for brush in entity.brushes:
				var brush_data := SolidData.BrushData.new()
				brush_data.is_origin = true
				brush_data.is_trigger = true
				for face in brush.faces:
					var face_data := SolidData.FaceData.new()
					face_data.texture = face.texturename
					if face.texturename.to_lower() != settings.texture_origin.to_lower(): brush_data.is_origin = false
					face_data.plane = Plane(
						face.points[0] * settings._scale_factor,
						face.points[1] * settings._scale_factor,
						face.points[2] * settings._scale_factor
						)
					face_data.uv = Transform2D.IDENTITY
					face_data.uv.origin = Vector2(face.u_offset.w, face.v_offset.w)
					if face.format == QEntity.FaceFormat.STANDARD:
						var r := deg_to_rad(face.rotation)
						face_data.uv.x = Vector2(cos(r), -sin(r)) * face.uv_scale.x * settings._scale_factor
						face_data.uv.y = Vector2(sin(r), cos(r)) * face.uv_scale.y * settings._scale_factor
					else:
						face_data.uv.x = Vector2.RIGHT * face.uv_scale.x * settings._scale_factor
						face_data.uv.y = Vector2.DOWN * face.uv_scale.y * settings._scale_factor
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
					face_data.value = face.value
					if face.has_meta(&"override"):
						face_data.override_texture = face.get_meta(&"override", "")
						face.remove_meta(&"override")
					brush_data.faces.append(face_data)
				for face_data in brush_data.faces: brush_data.planes.append(face_data.plane)
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
	if _current_wad_paths.has("res://%s"%map.wad_paths[index]): return
	if ResourceLoader.exists("res://%s"%map.wad_paths[index]):
		if verbose: print("\t\t-Loading WAD: %s"%map.wad_paths[index])
		var wad: WAD = ResourceLoader.load("res://%s"%map.wad_paths[index])
		if wad != null:
			_wads.append(wad)
			return
	printerr("\t\t-Missing WAD: %s"%map.wad_paths[index])

## Create materials for [member _materials]
func _generate_materials(index: int) -> void:
	var texturename: String = _materials.keys()[index]
	var is_override: bool = texturename.contains("|")
	var tag: String
	var info: String
	var smart_tag: QMapSmartTag
	if is_override:
		var contents := texturename.split("|", true)
		tag = contents[0]
		texturename = contents[1]
		info = contents[2]
		for n in settings.smart_tags.size():
			if settings.smart_tags[n].name == tag:
				smart_tag = settings.smart_tags[n]
				break
		if smart_tag == null || smart_tag.override_material == null: is_override = false
	## Ignore generation if empty or non-rendered texture
	for texture in settings.empty_textures:
		if texturename.to_lower() == texture.to_lower(): return
	if !show_non_rendered_textures && !_is_render_texture(texturename): return
	## Find texture and material
	var texture := _find_texture_or_animated(texturename)
	var material: Material
	if is_override:
		material = smart_tag.override_material.duplicate()
		material.set_meta(&"tag", tag)
		if !info.is_empty() && info.is_valid_float():
			material.set_meta(&"value", info.to_float())
			material.set(smart_tag.value_property_path, info.to_float())
	else:
		for s_tag in settings.smart_tags: if s_tag.match_type == QMapSmartTag.MatchType.MATERIAL:
			if s_tag.override_material == null: continue
			var pattern: String = s_tag.pattern.replace("\\*", ASTRSK_ALT_CHAR)
			var test_texture: String = texturename.replace("*", ASTRSK_ALT_CHAR).to_lower()
			if test_texture.match(pattern): material = s_tag.override_material.duplicate()
		if material == null: material = _find_material(texturename)
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
	material.set_meta(&"texturename", texturename)
	if is_override: _materials["%s|%s|%s"%[tag, texturename, info]] = material
	else: _materials[texturename] = material

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
	var fallback_material := StandardMaterial3D.new()
	fallback_material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
	return fallback_material

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
		_entities[entity].add_to_group(&"entity")
		return
	for path in settings.get_paths_scenes(map.mods): for extension in ["tscn","scn"]:
		if ResourceLoader.exists("%s/%s.%s"%[path, entity.classname.replace(".", "/"), extension]):
			var scene: PackedScene = ResourceLoader.load("%s/%s.%s"%[path, entity.classname.replace(".", "/"), extension])
			if scene != null:
				_entities[entity] = scene.instantiate()
				_get_target_destinations(entity, _entities[entity])
				_entities[entity].add_to_group(&"entity")
				return
	if entity.brushes.size() > 0:
		_entities[entity] = StaticBody3D.new()
	else:
		_entities[entity] = Node3D.new()
	_get_target_destinations(entity, _entities[entity])
	_entities[entity].add_to_group(&"entity")
	return

## Checks if node should be added to [member _target_destinations]
func _get_target_destinations(entity: QEntity, node: Node) -> void:
	if settings.fgd.classes.has(entity.classname):
		for key in entity.properties.keys():
			if settings.fgd.classes[entity.classname].properties.has(key):
				if settings.fgd.classes[entity.classname].properties[key].type == FGDEntityProperty.PropertyType.TARGET_DESTINATION:
					_target_destinations[entity.properties[key]] = node
					node.add_to_group(&"target_destination")
					node.set_meta(&"target_destination", entity.properties[key])

## Find vertices, normals, and tangents
func _generate_solid_data(index: int) -> void:
	var entity: QEntity = _solid_data.keys()[index]
	var data: SolidData = _solid_data[entity]
	if data == null: return
	for brush in data.brushes: for face in brush.faces:
		# Find vertices
		var v_up := Vector3.UP
		if abs(face.plane.normal.dot(v_up)) > 0.9: v_up = Vector3.RIGHT
		var right := face.plane.normal.cross(v_up).normalized()
		var forward := right.cross(face.plane.normal).normalized()
		var centroid := face.plane.get_center()
		face.vertices.append(centroid + (right *  HYPERPLANE_SIZE) + (forward *  HYPERPLANE_SIZE))
		face.vertices.append(centroid + (right * -HYPERPLANE_SIZE) + (forward *  HYPERPLANE_SIZE))
		face.vertices.append(centroid + (right * -HYPERPLANE_SIZE) + (forward * -HYPERPLANE_SIZE))
		face.vertices.append(centroid + (right *  HYPERPLANE_SIZE) + (forward * -HYPERPLANE_SIZE))
		for other_face in brush.faces:
			if other_face == face: continue
			face.vertices = Geometry3D.clip_polygon(face.vertices, other_face.plane)
			if face.vertices.is_empty(): break
		# Merge adjacent vertices
		if face.vertices.size() > 1:
			var merged_vertices: PackedVector3Array
			var prev_vertex := face.vertices[0].snappedf(VERTEX_MERGE_DISTANCE)
			merged_vertices.append(prev_vertex)
			for i in range(1, face.vertices.size()):
				var vertex := face.vertices[i].snappedf(VERTEX_MERGE_DISTANCE)
				if prev_vertex != vertex: merged_vertices.append(vertex)
				prev_vertex = vertex
			face.vertices = merged_vertices
		# Sort vertices
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
		face.normals.resize(face.vertices.size())
		face.normals.fill(face.plane.normal)

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
	if !_is_render_class(entity.classname): return
	var unique_surfaces: PackedStringArray
	for brush in data.brushes:
		if brush.is_origin: continue
		var texture_faces: Dictionary[StringName, Array]
		for face in brush.faces:
			if !_is_render_texture(face.texture): continue
			if face.override_texture.is_empty():
				if !texture_faces.has(face.texture): texture_faces[face.texture] = []
				texture_faces[face.texture].append(face)
				if !unique_surfaces.has(face.texture): unique_surfaces.append(face.texture)
			else:
				if !texture_faces.has(face.override_texture): texture_faces[face.override_texture] = []
				texture_faces[face.override_texture].append(face)
				if !unique_surfaces.has(face.override_texture): unique_surfaces.append(face.override_texture)
		brush.sorted_faces = texture_faces
	data.expected_surface_count = unique_surfaces.size()

## Generate meshes
func _generate_meshes(index: int) -> void:
	var entity: QEntity = _solid_data.keys()[index]
	var data: SolidData = _solid_data[entity]
	var use_occlusion_culling: bool = ProjectSettings.get_setting("rendering/occlusion_culling/use_occlusion_culling", false)
	if data == null: return
	var arrays: Array
	var convex_arrays: Array
	var occlusion_arrays: Array
	var path_arrays: Array
	arrays.resize(Mesh.ARRAY_MAX)
	convex_arrays.resize(Mesh.ARRAY_MAX)
	occlusion_arrays.resize(Mesh.ARRAY_MAX)
	path_arrays.resize(Mesh.ARRAY_MAX)
	for brush in data.brushes:
		brush.mesh = ArrayMesh.new()
		convex_arrays[Mesh.ARRAY_VERTEX] = PackedVector3Array()
		path_arrays[Mesh.ARRAY_VERTEX] = PackedVector3Array()
		occlusion_arrays[Mesh.ARRAY_VERTEX] = PackedVector3Array()
		for key in brush.sorted_faces:
			var surface_index := brush.mesh.get_surface_count()
			if surface_index == RenderingServer.MAX_MESH_SURFACES:
				print("\t\t-ERROR: Cannot render brush in %s: too many surfaces (over %s)!"%[entity.classname, RenderingServer.MAX_MESH_SURFACES])
				break
			arrays[Mesh.ARRAY_VERTEX] = PackedVector3Array()
			arrays[Mesh.ARRAY_NORMAL] = PackedVector3Array()
			arrays[Mesh.ARRAY_TEX_UV] = PackedVector2Array()
			for face: SolidData.FaceData in brush.sorted_faces[key]:
				if _should_render(face.texture, entity.classname, face.surface_flag, face.content_flag):
					for i in face.indices:
						arrays[Mesh.ARRAY_VERTEX].append(_convert_coordinates(face.vertices[i] - data.origin))
						arrays[Mesh.ARRAY_NORMAL].append(_convert_coordinates(face.normals[i]))
						arrays[Mesh.ARRAY_TEX_UV].append(_get_tex_uv(face, face.vertices[i]))
			if arrays[Mesh.ARRAY_VERTEX].size() > 0:
				brush.mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
				brush.mesh.surface_set_material(surface_index, _materials[key])
				brush.mesh.surface_set_name(surface_index, key)
		for face in brush.faces:
			if _should_collide(face.texture, entity.classname, face.surface_flag, face.content_flag):
				for i in face.indices:
					convex_arrays[Mesh.ARRAY_VERTEX].append(_convert_coordinates(face.vertices[i] - data.origin))
			if _should_pathfind(face.texture, entity.classname, face.surface_flag, face.content_flag):
				for i in face.indices:
					path_arrays[Mesh.ARRAY_VERTEX].append(_convert_coordinates(face.vertices[i] - data.origin))
			if _should_occlude(face.texture, entity.classname, face.surface_flag, face.content_flag):
				if !_alphatests[face.texture] && use_occlusion_culling:
					for i in face.indices:
						occlusion_arrays[Mesh.ARRAY_VERTEX].append(_convert_coordinates(face.vertices[i] - data.origin))
		if brush.mesh.get_surface_count() == 0: brush.mesh = null
		if convex_arrays[Mesh.ARRAY_VERTEX].size() > 0:
			brush.collision_mesh = ArrayMesh.new()
			brush.collision_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, convex_arrays)
		if path_arrays[Mesh.ARRAY_VERTEX].size() > 0:
			brush.pathfinding_mesh = ArrayMesh.new()
			brush.pathfinding_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, convex_arrays)
		if occlusion_arrays[Mesh.ARRAY_VERTEX].size() > 0:
			brush.occlusion_mesh = ArrayMesh.new()
			brush.occlusion_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, occlusion_arrays)

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
		pattern = pattern.replace("\\*", ASTRSK_ALT_CHAR)
		if texture.to_lower().replace("*", ASTRSK_ALT_CHAR).match(pattern.to_lower()): return false
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

## Returns true if should be rendered based on texture, class, and flags
func _should_render(texture: StringName, classname: String, surface: int, content: int) -> bool:
	return _is_render_texture(texture) && _is_render_class(classname) && _is_render_surface_flag(surface) && _is_render_content_flag(content)

## Returns true if texture should have collision
func _is_collision_texture(texture: StringName) -> bool:
	for pattern in settings.get_non_colliding_textures():
		pattern = pattern.replace("\\*", ASTRSK_ALT_CHAR)
		if texture.to_lower().replace("*", ASTRSK_ALT_CHAR).match(pattern.to_lower()): return false
	return true

## Returns true if classname should have collision
func _is_collision_class(classname: String) -> bool:
	for pattern in settings.get_non_colliding_entities():
		if classname.to_lower().match(pattern.to_lower()): return false
	return true

## Returns true if surface flag should have collision
func _is_collision_surface_flag(flag: int) -> bool:
	for pattern in settings.get_non_colliding_surfaces():
		if pattern == 0: continue
		if flag & pattern: return false
	return true

## Returns true if content flag should have collision
func _is_collision_content_flag(flag: int) -> bool:
	for pattern in settings.get_non_colliding_content():
		if pattern == 0: continue
		if flag & pattern: return false
	return true

## Returns true if should have collision based on texture, class, and flags
func _should_collide(texture: StringName, classname: String, surface: int, content: int) -> bool:
	return _is_collision_texture(texture) && _is_collision_class(classname) && _is_collision_surface_flag(surface) && _is_collision_content_flag(content)

## Returns true if texture should have occlusion
func _is_occluding_texture(texture: StringName) -> bool:
	for pattern in settings.get_non_occluding_textures():
		pattern = pattern.replace("\\*", ASTRSK_ALT_CHAR)
		if texture.to_lower().replace("*", ASTRSK_ALT_CHAR).match(pattern.to_lower()): return false
	return true

## Returns true if classname should have occlusion
func _is_occluding_class(classname: String) -> bool:
	for pattern in settings.get_non_occluding_entities():
		if classname.to_lower().match(pattern.to_lower()): return false
	return true

## Returns true if surface flag should have occlusion
func _is_occluding_surface_flag(flag: int) -> bool:
	for pattern in settings.get_non_occluding_surfaces():
		if pattern == 0: continue
		if flag & pattern: return false
	return true

## Returns true if content flag should have occlusion
func _is_occluding_content_flag(flag: int) -> bool:
	for pattern in settings.get_non_occluding_content():
		if pattern == 0: continue
		if flag & pattern: return false
	return true

## Returns true if should have occlusion based on texture, class, and flags
func _should_occlude(texture: StringName, classname: String, surface: int, content: int) -> bool:
	return _is_occluding_texture(texture) && _is_occluding_class(classname) && _is_occluding_surface_flag(surface) && _is_occluding_content_flag(content)

## Returns true if classname should generate convex collisions
func _is_convex_class(classname: String) -> bool:
	for pattern in settings.get_convex_entities():
		if classname.to_lower().match(pattern.to_lower()): return true
	return false

## Returns true if texture should have pathfinding
func _is_pathfinding_texture(texture: StringName) -> bool:
	for pattern in settings.get_non_pathfinding_textures():
		pattern = pattern.replace("\\*", ASTRSK_ALT_CHAR)
		if texture.to_lower().replace("*", ASTRSK_ALT_CHAR).match(pattern.to_lower()): return false
	return true

## Returns true if classname should have pathfinding
func _is_pathfinding_class(classname: String) -> bool:
	for pattern in settings.get_non_pathfinding_entities():
		if classname.to_lower().match(pattern.to_lower()): return false
	return true

## Returns true if surface flag should have pathfinding
func _is_pathfinding_surface_flag(flag: int) -> bool:
	for pattern in settings.get_non_pathfinding_surfaces():
		if pattern == 0: continue
		if flag & pattern: return false
	return true

## Returns true if content flag should have pathfinding
func _is_pathfinding_content_flag(flag: int) -> bool:
	for pattern in settings.get_non_pathfinding_content():
		if pattern == 0: continue
		if flag & pattern: return false
	return true

## Returns true if should have pathfinding based on texture, class, and flags
func _should_pathfind(texture: StringName, classname: String, surface: int, content: int) -> bool:
	return _is_pathfinding_texture(texture) && _is_pathfinding_class(classname) && _is_pathfinding_surface_flag(surface) && _is_pathfinding_content_flag(content)

func _get_tex_uv(face: SolidData.FaceData, vertex: Vector3) -> Vector2:
	var tex_uv := settings.default_uv_scale
	var texture_size: Vector2 = _texture_sizes[face.texture]
	if face.uv_format == QEntity.FaceFormat.VALVE_220:
		tex_uv *= Vector2(face.u_axis.dot(vertex), face.v_axis.dot(vertex))
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
			tex_uv *= Vector2(vertex.x, -vertex.z)
		elif nx >= ny and nx >= nz:
			tex_uv *= Vector2(vertex.y, -vertex.z)
		else:
			tex_uv *= Vector2(vertex.x, vertex.y)
		tex_uv = tex_uv.rotated(face.uv.get_rotation())
		tex_uv /= face.uv.get_scale()
		tex_uv += face.uv.origin
		tex_uv /= texture_size
	return tex_uv

func _pass_to_scene_tree() -> void:
	var original_process_mode := process_mode
	process_mode = Node.PROCESS_MODE_DISABLED
	var csg_to_compile: Dictionary[Node, CSGCombiner3D]
	var collision_csg_to_compile: Dictionary[Node, CSGCombiner3D]
	var occlusion_csg_to_compile: Dictionary[Node, CSGCombiner3D]
	var path_csg_to_compile: Dictionary[Node, CSGCombiner3D]
	var node_entities: Dictionary[Node, QEntity]
	# Find worldspawn and apply special properties
	for entity: QEntity in _entities.keys():
		if entity.classname == "worldspawn":
			_worldspawn_generation(entity.properties, _entities[entity])
			break
	# Prepare entities for SceneTree
	for entity: QEntity in _entities.keys():
		var data: SolidData = _solid_data[entity]
		var node := _entities[entity]
		node_entities[node] = entity
		node.name = entity.classname.capitalize().replace(" ", "")
		# Apply position, rotation, and scale modifications
		if data != null:
			node.set(&"position", _convert_coordinates(data.origin))
		else:
			node.set(&"position", _convert_coordinates(entity.origin * settings._scale_factor))
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
			# Render
			if entity.geometry_flags & QEntity.GeometryFlags.RENDER:
				if data.expected_surface_count >= RenderingServer.MAX_MESH_SURFACES:
					print("\t\t-ERROR: Cannot render %s: too many surfaces (%s/%s)!"%[entity.classname, data.expected_surface_count, RenderingServer.MAX_MESH_SURFACES])
				else:
					var csg_combiner := CSGCombiner3D.new()
					for brush in data.brushes:
						if brush.mesh == null: continue
						var csg_mesh := CSGMesh3D.new()
						csg_mesh.mesh = brush.mesh
						csg_combiner.add_child(csg_mesh)
					if csg_combiner.get_child_count() > 0:
						node.add_child(csg_combiner)
						csg_to_compile.set(node, csg_combiner)
					else: csg_combiner.queue_free()
			# Collision
			if entity.geometry_flags & QEntity.GeometryFlags.CONVEX_COLLISIONS || _is_convex_class(entity.classname):
				var brush_id: int
				for brush in data.brushes:
					if brush.collision_mesh == null: continue
					var collision_shape := CollisionShape3D.new()
					collision_shape.debug_color = node_entities[node].get_debug_color(settings.fgd)
					collision_shape.shape = brush.collision_mesh.create_convex_shape()
					collision_shape.name = "ConvexCollision%s"%brush_id
					node.add_child(collision_shape)
					brush_id += 1
			elif entity.geometry_flags & QEntity.GeometryFlags.CONCAVE_COLLISIONS:
				var csg_combiner := CSGCombiner3D.new()
				for brush in data.brushes:
					if brush.collision_mesh == null: continue
					var csg_mesh := CSGMesh3D.new()
					csg_mesh.mesh = brush.collision_mesh
					csg_combiner.add_child(csg_mesh)
				if csg_combiner.get_child_count() > 0:
					node.add_child(csg_combiner)
					collision_csg_to_compile.set(node, csg_combiner)
				else: csg_combiner.queue_free()
			# Occlusion
			if entity.geometry_flags & QEntity.GeometryFlags.OCCLUSION:
				var csg_combiner := CSGCombiner3D.new()
				for brush in data.brushes:
					if brush.occlusion_mesh == null: continue
					var csg_mesh := CSGMesh3D.new()
					csg_mesh.mesh = brush.occlusion_mesh
					csg_combiner.add_child(csg_mesh)
				if csg_combiner.get_child_count() > 0:
					node.add_child(csg_combiner)
					occlusion_csg_to_compile.set(node, csg_combiner)
				else: csg_combiner.queue_free()
			# Pathfinding
			if entity.geometry_flags & QEntity.GeometryFlags.OCCLUSION:
				var csg_combiner := CSGCombiner3D.new()
				for brush in data.brushes:
					if brush.pathfinding_mesh == null: continue
					var csg_mesh := CSGMesh3D.new()
					csg_mesh.mesh = brush.pathfinding_mesh
					csg_combiner.add_child(csg_mesh)
				if csg_combiner.get_child_count() > 0:
					node.add_child(csg_combiner)
					path_csg_to_compile.set(node, csg_combiner)
				else: csg_combiner.queue_free()
	# Compile CSG after allowing a frame for it to calculate
	await get_tree().process_frame
	# Render
	for node in csg_to_compile.keys():
		var mesh_instance := MeshInstance3D.new()
		mesh_instance.name = "Mesh"
		mesh_instance.mesh = csg_to_compile[node].bake_static_mesh()
		var shadow_mesh := ArrayMesh.new()
		var shadow_arrays: Array
		shadow_arrays.resize(Mesh.ARRAY_MAX)
		for n in mesh_instance.mesh.get_surface_count():
			shadow_arrays[Mesh.ARRAY_VERTEX] = mesh_instance.mesh.surface_get_arrays(n)[Mesh.ARRAY_VERTEX]
			shadow_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, shadow_arrays)
			var texturename: String = mesh_instance.mesh.surface_get_material(n).get_meta(&"texturename", "")
			mesh_instance.mesh.surface_set_name(n, texturename)
		mesh_instance.mesh.shadow_mesh = shadow_mesh
		node.add_child(mesh_instance)
		csg_to_compile[node].queue_free()
	# Collision
	for node in collision_csg_to_compile.keys():
		var collision_shape := CollisionShape3D.new()
		collision_shape.debug_color = node_entities[node].get_debug_color(settings.fgd)
		collision_shape.debug_fill = false
		collision_shape.name = "TrimeshCollision"
		collision_shape.shape = collision_csg_to_compile[node].bake_static_mesh().create_trimesh_shape()
		node.add_child(collision_shape)
		collision_csg_to_compile[node].queue_free()
	# Occlusion
	for node in occlusion_csg_to_compile.keys():
		var occluder_instance := OccluderInstance3D.new()
		occluder_instance.name = "Occluder"
		var array_occluder := ArrayOccluder3D.new()
		var array_mesh := occlusion_csg_to_compile[node].bake_static_mesh()
		var vertices := array_mesh.get_faces()
		var indices: PackedInt32Array
		indices.resize(vertices.size())
		for v in vertices.size(): indices[v] = v
		array_occluder.set_arrays(vertices, indices)
		occluder_instance.occluder = array_occluder
		node.add_child(occluder_instance)
		occlusion_csg_to_compile[node].queue_free()
	# Pathfinding
	if settings.generate_pathfinding: for node in path_csg_to_compile.keys():
		var entity: QEntity = _entities.find_key(node)
		var nav_region := NavigationRegion3D.new()
		nav_region.name = "NavRegion"
		if settings.default_nav_mesh != null:
			nav_region.navigation_mesh = settings.default_nav_mesh
		else:
			nav_region.navigation_mesh = NavigationMesh.new()
			nav_region.navigation_mesh.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
		var nav_collider := CollisionShape3D.new()
		nav_collider.shape = collision_csg_to_compile[node].bake_static_mesh().create_trimesh_shape()
		var nav_static := StaticBody3D.new()
		nav_static.add_child(nav_collider)
		nav_region.add_child(nav_static)
		node.add_child(nav_region)
		nav_region.enter_cost = entity.properties.get(settings.property_nav_enter_cost, "0").to_float()
		nav_region.travel_cost = entity.properties.get(settings.property_nav_travel_cost, "1").to_float()
		_nav_regions.append(nav_region)
		path_csg_to_compile[node].queue_free()
	# Define groups and layers
	var func_groups: Dictionary[int, Node]
	var func_group_names: Dictionary[int, StringName]
	var omitted_indices: PackedInt32Array
	for entity: QEntity in _entities.keys():
		match entity.group_type:
			QEntity.GroupingType.LAYER, QEntity.GroupingType.GROUP:
				if entity.omit_from_export: omitted_indices.append(entity.group_id)
				elif group_nodes:
					var group_node := Node.new()
					group_node.name = entity.group_name
					func_groups.set(entity.group_id, group_node)
				func_group_names.set(entity.group_id, entity.group_name)
	# Move entities to Scene Tree
	for entity: QEntity in _entities.keys():
		var node := _entities[entity]
		if entity.group_type == QEntity.GroupingType.GROUP:
			node.queue_free()
		elif omitted_indices.has(entity.group_id):
			node.queue_free()
		else:
			if entity.group_id != -1 && group_nodes && func_groups.has(entity.group_id):
				func_groups[entity.group_id].add_child(node, true)
			else:
				add_child(node, true)
			if func_group_names.has(entity.group_id):
				node.add_to_group(func_group_names[entity.group_id])
	if group_nodes: for group_node in func_groups.values(): add_child(group_node, true)
	# Bake pathfinding
	for nav_region in _nav_regions:
		if nav_region == null || nav_region.is_queued_for_deletion(): continue
		nav_region.bake_navigation_mesh()
		while nav_region.is_baking(): await get_tree().process_frame
		for child in nav_region.get_children(): child.queue_free()
	process_mode = original_process_mode

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
			for path in settings.get_paths_skies(map.mods): for extension in settings.texture_extensions:
				if ResourceLoader.exists("%s/%s.%s"%[path, skyname, extension]):
					sky_texture= ResourceLoader.load("%s/%s.%s"%[path, skyname, extension])
		if sky_texture != null:
			world_env.environment.background_mode = Environment.BG_SKY
			world_env.environment.sky = Sky.new()
			if settings.custom_sky_material != null:
				world_env.environment.sky.sky_material = settings.custom_sky_material
			else:
				world_env.environment.sky.sky_material = PanoramaSkyMaterial.new()
			for path in settings.get_paths_skies(map.mods): for extension in settings.texture_extensions:
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
