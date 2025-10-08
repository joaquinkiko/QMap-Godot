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

func load_map() -> Error:
	if map == null:
		printerr("Missing map to generate!")
		return ERR_FILE_NOT_FOUND
	if settings == null:
		printerr("Missing MapSettings to generate with!")
		return ERR_FILE_NOT_FOUND
	var start_time := Time.get_ticks_msec()
	if verbose: print("Generating map '%s'..."%map.resource_path)
	_create_texture_map()
	_create_entity_maps()
	_thread_group_task(_generate_materials, _materials.size(), "Generating materials")
	_thread_group_task(_generate_entities, _entities.size(), "Generating entities")
	_thread_group_task(_generate_solid_data, _solid_data.size(), "Generating Solid Data")
	_thread_group_task(_calculate_origins, _solid_data.size(), "Calculating origins")
	_thread_group_task(_wind_faces, _solid_data.size(), "Winding faces")
	_thread_group_task(_index_faces, _solid_data.size(), "Indexing faces")
	_thread_group_task(_smooth_normals, _solid_data.size(), "Smoothing normals")
	_thread_group_task(_generate_meshes, _solid_data.size(), "Generating meshes")
	if verbose: print("\t-Adding to SceneTree...")
	var interval_time := Time.get_ticks_msec()
	_pass_to_scene_tree()
	if verbose: print("\t\t-Done in %sms"%(Time.get_ticks_msec() - interval_time))
	if verbose: print("Finished generating map in %sms"%(Time.get_ticks_msec() - start_time))
	_wads.clear()
	_materials.clear()
	_entities.clear()
	_solid_data.clear()
	return OK

func _create_texture_map() -> void:
	pass

func _create_entity_maps() -> void:
	pass

func _generate_materials(index: int) -> void:
	pass

func _generate_entities(index: int) -> void:
	pass

func _generate_solid_data(index: int) -> void:
	pass

func _calculate_origins(index: int) -> void:
	pass

func _wind_faces(index: int) -> void:
	pass

func _index_faces(index: int) -> void:
	pass

func _smooth_normals(index: int) -> void:
	pass

func _generate_meshes(index: int) -> void:
	pass

func _pass_to_scene_tree() -> void:
	pass
