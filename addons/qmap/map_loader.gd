## Loads [QMap] as a child of this node
##
## [url]https://1666186240-files.gitbook.io/~/files/v0/b/gitbook-x-prod.appspot.com/o/spaces%2F-LtVT8pJjInrrHVCovzy%2Fuploads%2FEukkFYJLwfafFXUMpsI2%2FMAPFiles_2001_StefanHajnoczi.pdf?alt=media&token=51471685-bf69-42ae-a015-a474c0b95165[/url]
class_name MapLoader extends Node3D

## Data used for building geometry
class SolidData extends RefCounted:
	class BrushData extends RefCounted:
		var faces: Array[FaceData]
		var is_origin: bool
	class FaceData extends RefCounted:
		var vertices: PackedVector3Array
		var normals: PackedVector3Array
		var tangents: PackedFloat32Array
		var colors: PackedColorArray
		var uvs: PackedVector2Array
		var indices: PackedInt32Array
		var texture: StringName
	var brushes: Array[BrushData]
	var origin: Vector3
	var mesh: ArrayMesh

## Emitted at map loading stages (value from 0.0-1.0)
signal progress(percentage: float)

## [QMap] to load on [method load_map]
@export var map: QMap
## Settings to use for generation
@export var settings: QMapSettings
@export_group("Additional Settings")
## If true, will automatically call [method load_map] during [method _ready]
@export var auto_load_map: bool = true
## When true will load any [WAD] listed in [QMap] properties under the key "wads"
@export var auto_load_internal_wads: bool = true
## When true will print debug info while map loads
@export var verbose: bool = true

var _current_wad_paths: PackedStringArray
var _wads: Array[WAD]
var _materials: Dictionary[StringName, Material]
var _entities: Dictionary[QEntity, Node]
var _solid_data: Dictionary[QEntity, SolidData]

func _ready() -> void:
	if auto_load_map: load_map()

func _thread_group_task(task: Callable, elements: int, task_debug: String) -> void:
	if verbose: print("\t-%s..."%task_debug)
	var interval_time := Time.get_ticks_msec()
	var task_id := WorkerThreadPool.add_group_task(task, elements, -1, false, task_debug)
	WorkerThreadPool.wait_for_group_task_completion(task_id)
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
	progress.emit(0)
	if verbose: print("\t-Initializing...")
	_create_texture_map()
	_create_entity_maps()
	_wads = settings.extra_wads
	for wad in settings.extra_wads:
		if verbose: print("\t\t-Including WAD: %s"%wad.resource_path)
		_current_wad_paths.append(wad.resource_path)
	if verbose: print("\t\t-Done in %sms"%(Time.get_ticks_msec() - start_time))
	progress.emit(0.05)
	_thread_group_task(_load_wads, map.wad_paths.size(), "Loading wads")
	progress.emit(0.1)
	_thread_group_task(_generate_materials, _materials.size(), "Generating materials")
	progress.emit(0.15)
	_thread_group_task(_generate_entities, _entities.size(), "Generating entities")
	progress.emit(0.2)
	_thread_group_task(_generate_solid_data, _solid_data.size(), "Generating Solid Data")
	progress.emit(0.4)
	_thread_group_task(_calculate_origins, _solid_data.size(), "Calculating origins")
	progress.emit(0.45)
	_thread_group_task(_wind_faces, _solid_data.size(), "Winding faces")
	progress.emit(0.5)
	_thread_group_task(_index_faces, _solid_data.size(), "Indexing faces")
	progress.emit(0.65)
	_thread_group_task(_smooth_normals, _solid_data.size(), "Smoothing normals")
	progress.emit(0.75)
	_thread_group_task(_generate_meshes, _solid_data.size(), "Generating meshes")
	progress.emit(0.9)
	if verbose: print("\t-Adding to SceneTree...")
	var interval_time := Time.get_ticks_msec()
	_pass_to_scene_tree()
	if verbose: print("\t\t-Done in %sms"%(Time.get_ticks_msec() - interval_time))
	progress.emit(0.99)
	_current_wad_paths.clear()
	_wads.clear()
	_materials.clear()
	_entities.clear()
	_solid_data.clear()
	if verbose: print("Finished generating map in %sms"%(Time.get_ticks_msec() - start_time))
	progress.emit(1)
	return OK

## Fill [member _materials]
func _create_texture_map() -> void:
	var placeholder := PlaceholderMaterial.new()
	for texturename in map.texturenames:
		_materials[texturename] = placeholder

## Fill [member _entities] and [member _solid_data]
func _create_entity_maps() -> void:
	if verbose: print("\t\t-Initializing %s entities..."%map.entities.size())
	for entity in map.entities:
		_entities[entity] = null
		if entity.brushes.size() > 0:
			var data := SolidData.new()
			data.origin = entity.origin
			for brush in entity.brushes:
				var brush_data := SolidData.BrushData.new()
				brush_data.is_origin = true
				for face in brush.faces:
					var face_data := SolidData.FaceData.new()
					face_data.texture = face.texturename
					if face.texturename != settings.texture_origin: brush_data.is_origin = false
					brush_data.faces.append(face_data)
				data.brushes.append(brush_data)
			_solid_data[entity] = data
		else: _solid_data[entity] = null

## Fill [member _wads]
func _load_wads(index: int) -> void:
	for base_path in settings.paths_wads:
		if _current_wad_paths.has("%s/%s"%[base_path, map.wad_paths[index]]): continue
		if ResourceLoader.exists("%s/%s"%[base_path, map.wad_paths[index]]):
			if verbose: print("\t\t-Loading WAD: %s"%map.wad_paths[index])
			var wad: WAD = ResourceLoader.load("%s/%s"%[base_path, map.wad_paths[index]])
			if wad != null:
				_wads.append(wad)
				return
	printerr("\t\t-Missing WAD: %s"%map.wad_paths[index])

## Create materials for [member _materials] and optionally cache materials
func _generate_materials(index: int) -> void:
	var texturename: StringName = _materials.keys()[index]
	if texturename == settings.texture_empty: return
	if texturename == settings.texture_clip: return
	if texturename == settings.texture_skip: return
	if texturename == settings.texture_origin: return
	var texture: Texture2D
	var material: Material
	if settings.cache_materials:
		for extension in settings.material_extensions:
			if ResourceLoader.exists("%s/%s.%s"%[settings.cache_materials, texturename, extension]):
				material = ResourceLoader.load("%s/%s.%s"%[settings.cache_materials, texturename, extension])
				_materials[texturename] = material
				return
	for path in settings.paths_materials: for extension in settings.material_extensions:
		if ResourceLoader.exists("%s/%s.%s"%[path, texturename, extension]):
			material = ResourceLoader.load("%s/%s.%s"%[path, texturename, extension])
	if material == null:
		if settings.default_material != null:
			material = settings.default_material.duplicate()
		else: material = StandardMaterial3D.new()
	for path in settings.paths_textures: for extension in settings.texture_extensions:
		if ResourceLoader.exists("%s/%s.%s"%[path, texturename, extension]):
			texture = ResourceLoader.load("%s/%s.%s"%[path, texturename, extension])
	if texture == null: for wad in _wads:
		if !wad.textures.has(texturename): continue
		texture = wad.textures[texturename]
	if texture != null:
		material.set(settings.default_material_texture_path, texture)
	_materials[texturename] = material
	if settings.cache_materials:
		var is_cached: bool
		for extension in settings.material_extensions:
			if ResourceLoader.exists("%s/%s.%s"%[settings.cache_materials, texturename, extension]):
				is_cached = true
				break
		if !is_cached && settings.material_extensions.size() > 0:
			if !DirAccess.dir_exists_absolute(settings.cache_path):
				DirAccess.make_dir_absolute(settings.cache_path)
			ResourceSaver.save(material, "%s/%s.%s"%[settings.cache_path, texturename, settings.material_extensions[0]])

func _generate_entities(index: int) -> void:
	var entity: QEntity = _entities.keys()[index]

func _generate_solid_data(index: int) -> void:
	var entity: QEntity = _solid_data.keys()[index]
	var data: SolidData = _solid_data[entity]
	if data == null: return

func _calculate_origins(index: int) -> void:
	var entity: QEntity = _solid_data.keys()[index]
	var data: SolidData = _solid_data[entity]
	if data == null: return

func _wind_faces(index: int) -> void:
	var entity: QEntity = _solid_data.keys()[index]
	var data: SolidData = _solid_data[entity]
	if data == null: return

func _index_faces(index: int) -> void:
	var entity: QEntity = _solid_data.keys()[index]
	var data: SolidData = _solid_data[entity]
	if data == null: return

func _smooth_normals(index: int) -> void:
	var entity: QEntity = _solid_data.keys()[index]
	var data: SolidData = _solid_data[entity]
	if data == null: return

func _generate_meshes(index: int) -> void:
	var entity: QEntity = _solid_data.keys()[index]
	var data: SolidData = _solid_data[entity]
	if data == null: return

func _pass_to_scene_tree() -> void:
	for entity in _entities.keys():
		var node := _entities[entity]
