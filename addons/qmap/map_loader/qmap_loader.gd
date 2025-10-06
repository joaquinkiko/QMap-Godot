class_name QMapLoader extends Node3D

class EntityBrush extends RefCounted:
	var faces: Array[BrushFace]

class BrushFace extends RefCounted:
	var points: PackedVector3Array
	var uv_scale: Vector2
	var plane: Plane
	var rot: float
	var texturename: StringName
	var vertices: PackedVector3Array
	var triangle_indices: PackedInt32Array

const _VERTEX_EPSILON := 0.008
const _VERTEX_EPSILON2 := _VERTEX_EPSILON * _VERTEX_EPSILON
const _SCALE_FACTOR: float = 1.0 / DEFAULT_SCALE
const _HYPERPLANE_SIZE: float = 512.0
const _DEFAULT_MATERIAL := preload("res://addons/qmap/default_resources/default_material.tres")

## Default QUnit to Godot scaling
const DEFAULT_SCALE := 32
## Default path for scenes
const DEFAULT_PATH_SCENES := "res://scenes"
## Default path for textures
const DEFAULT_PATH_TEXTURES := "res://textures"
## Default path for materials
const DEFAULT_PATH_MATERIALS := "res://materials"
## Default path for audio
const DEFAULT_PATH_AUDIO := "res://audio"
## Default path for wads
const DEFAULT_PATH_WADS := "res://wads"
## Default path for models
const DEFAULT_PATH_MODELS := "res://models"
## Name of Skip texture
const TEXTURENAME_SKIP := "skip"
## Name of clip texture
const TEXTURENAME_CLIP := "clip"
## Name of origin texture
const TEXTURENAME_ORIGIN := "origin"

## [QMap] to load
@export_file("*.map", "*.MAP") var map_path: String
var map: QMap
## [FGD] to load on startup
@export_file("*.fgd", "*.FGD") var fgd_path: String
## [FGD] to initialize entities with
var fgd: FGD
## [WAD] file paths to auto load on startup
@export_file("*.wad","*.WAD") var wad_paths: PackedStringArray
## [WAD] files to read textures from
var wads: Array[WAD]
@export_group("Additional Settings")
## When true will load any [WAD] listed in [QMap] properties under the key "wads"
@export var auto_load_map_wads: bool = true

var _entities: Array[Node]
var _materials: Dictionary[StringName, Material]
var _texturepaths: PackedStringArray

## Temporary for testing, normally map loading should be called by user
func _ready() -> void:
	generate_map()

## Generates the [QMap]
func generate_map() -> Error:
	var start_time := Time.get_ticks_msec()
	var interval_time := start_time
	print("Generating map '%s'..."%ResourceUID.get_id_path(ResourceUID.text_to_id(map_path)))
	var task_id: int
	var map_task_id: int
	var fgd_task_id: int
	# Load Map and FGD
	fgd_task_id = WorkerThreadPool.add_task(_load_fgd, false, "Load FGD")
	map_task_id = WorkerThreadPool.add_task(_load_map, false, "Load map")
	WorkerThreadPool.wait_for_task_completion(fgd_task_id)
	print("\t-Loaded FGD in %smsec..."%(Time.get_ticks_msec() - interval_time))
	interval_time = Time.get_ticks_msec()
	WorkerThreadPool.wait_for_task_completion(map_task_id)
	print("\t-Loaded MAP in %smsec..."%(Time.get_ticks_msec() - interval_time))
	interval_time = Time.get_ticks_msec()
	if fgd == null:
		printerr("Missing FGD to load map")
		return ERR_INVALID_DATA
	if map == null:
		printerr("Missing MAP to load")
		return ERR_INVALID_DATA
	# Load internal wads
	task_id = WorkerThreadPool.add_group_task(
		_load_internal_wads, map.entities.size(), -1, false, "Load internal wads")
	WorkerThreadPool.wait_for_group_task_completion(task_id)
	print("\t-Loaded wads in %smsec..."%(Time.get_ticks_msec() - interval_time))
	interval_time = Time.get_ticks_msec()
	# Generate Materials
	for i in _entities.size(): _get_texture_list(i)
	task_id = WorkerThreadPool.add_group_task(
		_generate_materials, _texturepaths.size(), -1, false, "Generate Materials")
	WorkerThreadPool.wait_for_group_task_completion(task_id)
	print("\t-Generated materials in %smsec..."%(Time.get_ticks_msec() - interval_time))
	interval_time = Time.get_ticks_msec()
	# Generate entities
	task_id = WorkerThreadPool.add_group_task(
		_generate_entity, map.entities.size(), -1, false, "Generate entities")
	WorkerThreadPool.wait_for_group_task_completion(task_id)
	print("\t-Generated entities in %smsec..."%(Time.get_ticks_msec() - interval_time))
	interval_time = Time.get_ticks_msec()
	# Generate brush vertices
	task_id = WorkerThreadPool.add_group_task(
		_generate_vertices, _entities.size(), -1, false, "Generate brush vertices")
	WorkerThreadPool.wait_for_group_task_completion(task_id)
	print("\t-Generated vertices in %smsec..."%(Time.get_ticks_msec() - interval_time))
	interval_time = Time.get_ticks_msec()
	# Determine entity origins
	task_id = WorkerThreadPool.add_group_task(
		_apply_origins, _entities.size(), -1, false, "Determine entity origins")
	WorkerThreadPool.wait_for_group_task_completion(task_id)
	print("\t-Applied origins in %smsec..."%(Time.get_ticks_msec() - interval_time))
	interval_time = Time.get_ticks_msec()
	# Wind faces
	task_id = WorkerThreadPool.add_group_task(
		_wind_faces, _entities.size(), -1, false, "Wind faces")
	WorkerThreadPool.wait_for_group_task_completion(task_id)
	print("\t-Wound faces in %smsec..."%(Time.get_ticks_msec() - interval_time))
	interval_time = Time.get_ticks_msec()
	# Generate geometry
	task_id = WorkerThreadPool.add_group_task(
		_generate_geometry, _entities.size(), -1, false, "Generate geometry")
	WorkerThreadPool.wait_for_group_task_completion(task_id)
	print("\t-Generated geometry in %smsec..."%(Time.get_ticks_msec() - interval_time))
	interval_time = Time.get_ticks_msec()
	# Generate occlusion
	task_id = WorkerThreadPool.add_group_task(
		_generate_occlusion, _entities.size(), -1, false, "Generate occlusion")
	WorkerThreadPool.wait_for_group_task_completion(task_id)
	print("\t-Generated occlusion in %smsec..."%(Time.get_ticks_msec() - interval_time))
	interval_time = Time.get_ticks_msec()
	# Generate collisions
	task_id = WorkerThreadPool.add_group_task(
		_generate_collisions, _entities.size(), -1, false, "Generate collisions")
	WorkerThreadPool.wait_for_group_task_completion(task_id)
	print("\t-Generated collisions in %smsec..."%(Time.get_ticks_msec() - interval_time))
	interval_time = Time.get_ticks_msec()
	# Generate pathfinding
	task_id = WorkerThreadPool.add_group_task(
		_generate_pathfinding, _entities.size(), -1, false, "Generate pathfinding")
	WorkerThreadPool.wait_for_group_task_completion(task_id)
	print("\t-Generated pathfinding in %smsec..."%(Time.get_ticks_msec() - interval_time))
	interval_time = Time.get_ticks_msec()
	# Unwrap UV2s
	task_id = WorkerThreadPool.add_group_task(
		_unwrap_uv2, _entities.size(), -1, false, "Unwrap UV2s")
	WorkerThreadPool.wait_for_group_task_completion(task_id)
	print("\t-Unwrapped UV2s in %smsec..."%(Time.get_ticks_msec() - interval_time))
	interval_time = Time.get_ticks_msec()
	# Apply smoothing
	task_id = WorkerThreadPool.add_group_task(
		_apply_smoothing, _entities.size(), -1, false, "Apply smoothing")
	WorkerThreadPool.wait_for_group_task_completion(task_id)
	print("\t-Applied smoothing in %smsec..."%(Time.get_ticks_msec() - interval_time))
	interval_time = Time.get_ticks_msec()
	# Generate lighting
	task_id = WorkerThreadPool.add_group_task(
		_generate_lighting, _entities.size(), -1, false, "Generate lighting")
	WorkerThreadPool.wait_for_group_task_completion(task_id)
	print("\t-Generated lighting in %smsec..."%(Time.get_ticks_msec() - interval_time))
	interval_time = Time.get_ticks_msec()
	# Clean-up Meta
	task_id = WorkerThreadPool.add_group_task(
		_clean_up_meta, _entities.size(), -1, false, "Clean-up Meta")
	WorkerThreadPool.wait_for_group_task_completion(task_id)
	print("\t-Cleaned-up metadata in %smsec..."%(Time.get_ticks_msec() - interval_time))
	interval_time = Time.get_ticks_msec()
	# Add nodes to scene tree
	for n in _entities.size(): _add_to_scene_tree(n)
	print("\t-Added nodes to SceneTree %smsec..."%(Time.get_ticks_msec() - interval_time))
	interval_time = Time.get_ticks_msec()
	print("Finished generating map in %smsec!"%(Time.get_ticks_msec() - start_time))
	return OK

## Loads Map
func _load_map() -> void:
	if ResourceLoader.exists(map_path): map = ResourceLoader.load(map_path)

## Loads FGD
func _load_fgd() -> void:
	print("\t\t-Loading FGD: '%s'..."%ResourceUID.get_id_path(ResourceUID.text_to_id(fgd_path)))
	if ResourceLoader.exists(fgd_path): fgd = ResourceLoader.load(fgd_path)

## Loads wads from entites with "wad" property
func _load_internal_wads(entity_index: int) -> void:
	wads.clear()
	for path in wad_paths:
		if ResourceLoader.exists(path):
			print("\t\t-Loading wad: '%s'..."%ResourceUID.get_id_path(ResourceUID.text_to_id(path)))
			wads.append(ResourceLoader.load(path))
		else: print("\t\t-Missing wad: '%s'!"%ResourceUID.get_id_path(ResourceUID.text_to_id(path)))
	var entity: QEntity = map.entities[entity_index]
	if entity.properties.has("wad"):
		for path in entity.properties["wad"].split(";", false):
			if ResourceLoader.exists("%s/%s"%[DEFAULT_PATH_WADS, path]):
				var has_wad: bool
				for wad in wads:
					if wad.resource_path == "%s/%s"%[DEFAULT_PATH_WADS, path]:
						has_wad = true
						break
				if !has_wad:
					print("\t\t-Loading wad: '%s'..."%path)
					wads.append(ResourceLoader.load("%s/%s"%[DEFAULT_PATH_WADS, path]))
			else: print("\t\t-Missing wad: '%s'!"%path)

## Generate nodes for entities and adds them to the scene tree
func _generate_entity(entity_index: int) -> void:
	var entity: QEntity = map.entities[entity_index]
	if !fgd.classes.has(entity.classname): return
	var fgd_class: FGDClass = fgd.classes.get(entity.classname)
	var node: Node
	# Determine node scene
	var scene: PackedScene
	if ResourceLoader.exists("%s/%s.tscn"%[DEFAULT_PATH_SCENES, entity.classname]):
		scene = ResourceLoader.load("%s/%s.tscn"%[DEFAULT_PATH_SCENES, entity.classname])
	elif ResourceLoader.exists("%s/%s.scn"%[DEFAULT_PATH_SCENES, entity.classname]):
		scene = ResourceLoader.load("%s/%s.scn"%[DEFAULT_PATH_SCENES, entity.classname])
	if scene == null:
		match fgd_class.class_type:
			FGDClass.ClassType.SOLID: node = StaticBody3D.new()
			FGDClass.ClassType.POINT: node = Node3D.new()
			_: node = Node.new()
	else: node = scene.instantiate()
	# Apply properties
	for key in fgd_class.properties.keys():
		if !entity.properties.has(key):
			entity.properties[key] = fgd_class.properties[key].default_value
	var parsed_properties: Dictionary[StringName, Variant]
	for key in fgd_class.properties.keys(): 
		var raw_value := entity.properties[key]
		var value: Variant
		match fgd_class.properties[key].type:
			FGDEntityProperty.PropertyType.INTEGER: 
				value = raw_value.to_int()
			FGDEntityProperty.PropertyType.FLOAT: 
				value = raw_value.to_float()
			FGDEntityProperty.PropertyType.FLAGS: 
				value = raw_value.to_int()
			FGDEntityProperty.PropertyType.CHOICES: 
				FGDEntityProperty.PropertyType
			FGDEntityProperty.PropertyType.ANGLE:
				var nums: PackedFloat64Array
				for num in raw_value.split(" ", false):
					nums.append(num.to_float())
				value = Vector3(nums[0], nums[1], nums[2])
			FGDEntityProperty.PropertyType.VECTOR: 
				var nums: PackedFloat64Array
				for num in raw_value.split(" ", false):
					nums.append(num.to_float())
				value = Vector3(nums[0], nums[1], nums[2])
			FGDEntityProperty.PropertyType.COLOR_255: 
				var nums: PackedFloat64Array
				for num in raw_value.split(" ", false):
					nums.append(num.to_int())
				value = Color8(nums[0], nums[1], nums[2])
			FGDEntityProperty.PropertyType.COLOR_1: 
				var nums: PackedFloat64Array
				for num in raw_value.split(" ", false):
					nums.append(num.to_float())
				value = Color(nums[0], nums[1], nums[2])
			FGDEntityProperty.PropertyType.DECAL:
				if ResourceLoader.exists("%s/%s"%[DEFAULT_PATH_TEXTURES, raw_value]):
					value = ResourceLoader.load("%s/%s"%[DEFAULT_PATH_TEXTURES, raw_value])
				else: value = null
			FGDEntityProperty.PropertyType.STUDIO:
				if ResourceLoader.exists("%s/%s"%[DEFAULT_PATH_MODELS, raw_value]):
					value = ResourceLoader.load("%s/%s"%[DEFAULT_PATH_MODELS, raw_value])
				else: value = null
			FGDEntityProperty.PropertyType.SPRITE:
				if ResourceLoader.exists("%s/%s"%[DEFAULT_PATH_TEXTURES, raw_value]):
					value = ResourceLoader.load("%s/%s"%[DEFAULT_PATH_TEXTURES, raw_value])
				else: value = null
			FGDEntityProperty.PropertyType.SOUND:
				if ResourceLoader.exists("%s/%s"%[DEFAULT_PATH_AUDIO, raw_value]):
					value = ResourceLoader.load("%s/%s"%[DEFAULT_PATH_AUDIO, raw_value])
				else: value = null
			FGDEntityProperty.PropertyType.SCALE:
				if key == "scale":
					value = Vector3.ONE * raw_value.to_float()
				else: value = raw_value.to_float()
			_: value = raw_value
		node.set(key, value)
	node.set_meta(&"entity_properties", parsed_properties)
	node.set_meta(&"entity_classname", entity.classname)
	node.set_meta(&"entity_brushes", entity.brushes)
	if node.has_method("_load_properties"):
		node.call("_load_properties", parsed_properties)
	node.name = entity.classname
	_entities.append(node)

## Get list of textures to generate
func _get_texture_list(entity_index: int) -> void:
	var node: Node = _entities[entity_index]
	var brushes: Array[Array] = node.get_meta(&"entity_brushes")
	for brush in brushes: for plane in brush:
		if _texturepaths.has(plane[&"texture"].to_lower()): continue
		_texturepaths.append(plane[&"texture"].to_lower())

## Generate materials for textures
func _generate_materials(texture_index: int) -> void:
	var texture_name := _texturepaths[texture_index]
	if texture_name == TEXTURENAME_CLIP || texture_name == TEXTURENAME_SKIP || texture_name == TEXTURENAME_ORIGIN:
		var transparent := _DEFAULT_MATERIAL.duplicate()
		transparent.set("albedo_color", Color(1,1,1,0))
		transparent.set("transparency", 1)
		_materials[texture_name] = transparent
		return
	for wad in wads: if wad.textures.has(StringName(texture_name)):
		_materials[texture_name] = _DEFAULT_MATERIAL.duplicate()
		_materials[texture_name].set("albedo_texture", wad.textures[StringName(texture_name)])
		return
	# Add in loading Textures and Materials without Wads
	
	print("\t\t-Missing texture: %s"%texture_name)
	_materials[texture_name] = PlaceholderMaterial.new()

## Generate vertices for each brush
func _generate_vertices(entity_index: int) -> void:
	var node: Node = _entities[entity_index]
	var brushes: Array[Array] = node.get_meta(&"entity_brushes")
	var properties: Dictionary[StringName, Variant] = node.get_meta(&"entity_properties")
	var solid_brushes: Array[EntityBrush]
	# Parse data
	for i in brushes.size():
		var brush := EntityBrush.new()
		for j in brushes[i].size():
			var face := BrushFace.new()
			face.texturename = brushes[i][j][&"texture"]
			face.uv_scale = Vector2(
				brushes[i][j][&"u_scale"] * _SCALE_FACTOR,
				brushes[i][j][&"v_scale"] * _SCALE_FACTOR
				)
			face.points = [
				brushes[i][j][&"p1"] * _SCALE_FACTOR,
				brushes[i][j][&"p2"] * _SCALE_FACTOR,
				brushes[i][j][&"p3"] * _SCALE_FACTOR
				]
			face.rot = deg_to_rad(brushes[i][j][&"rotation"])
			face.plane = Plane(face.points[0], face.points[1], face.points[2])
			brush.faces.append(face)
		solid_brushes.append(brush)
	for brush in solid_brushes:
		# find vertices
		for x in brush.faces.size() - 2: for y in brush.faces.size() - 1: for z in brush.faces.size():
			if x == y || y == z || x == z: continue
			# Get Intersection
			var n: PackedVector3Array
			var d: PackedFloat64Array
			n.resize(3)
			d.resize(3)
			n[0] = brush.faces[x].plane.normal
			n[1] = brush.faces[y].plane.normal
			n[2] = brush.faces[z].plane.normal
			d[0] = brush.faces[x].plane.d
			d[1] = brush.faces[y].plane.d
			d[2] = brush.faces[z].plane.d
			var denom := n[0].dot(n[1].cross(n[2]))
			if denom == 0: continue
			var vertex := (
				-d[0]*n[1].cross(n[2])
				-d[1]*n[2].cross(n[0])
				-d[2]*n[0].cross(n[1])
				)/denom
			# Test if outside brush
			var legal := true
			for w in brush.faces.size():
				if brush.faces[w].plane.normal.dot(vertex) + brush.faces[w].plane.d > 0:
					legal = false
					break
			if legal:
				# Assign vertex to each plane
				brush.faces[x].vertices.append(vertex)
				brush.faces[y].vertices.append(vertex)
				brush.faces[z].vertices.append(vertex)
		# Sort vertices
		for face in brush.faces:
			if face.vertices.size() < 2: continue
			var sorted_vertices: PackedVector3Array
			var center: Vector3
			for vertex in face.vertices: center += vertex
			center /= face.vertices.size()
			for n in face.vertices.size() - 2:
				var a := (face.vertices[n] - center).normalized()
				var p := Plane(face.vertices[n], center, center + face.plane.normal)
				var smallest_angle: float = -1
				var smallest: int = -1
				for m in range(n+1, face.vertices.size()):
					if face.vertices[m] != Vector3.UP:
						var b := (face.vertices[m] - center).normalized()
						var angle := a.dot(b)
						if angle > smallest_angle:
							smallest_angle = angle
							smallest = m
				sorted_vertices.append(face.vertices[smallest])
				sorted_vertices.append(face.vertices[n+1])
			sorted_vertices.append(face.vertices[face.vertices.size() - 2])
			sorted_vertices.append(face.vertices[face.vertices.size() - 1])
			face.vertices = sorted_vertices
	node.set_meta(&"solid_brushes", solid_brushes)

## Get entity origin
func _apply_origins(entity_index: int) -> void:
	var node: Node = _entities[entity_index]
	var brushes: Array[EntityBrush] = node.get_meta(&"solid_brushes")
	var properties: Dictionary[StringName, Variant] = node.get_meta(&"entity_properties")
	if brushes.size() == 0: return
	var origin := Vector3.ZERO
	if properties.has("origin"): origin = properties["origin"] * _SCALE_FACTOR
	node.set_meta(&"entity_origin", origin)

## Sort and wind faces for generation
func _wind_faces(entity_index: int) -> void:
	var node: Node = _entities[entity_index]
	var brushes: Array[EntityBrush] = node.get_meta(&"solid_brushes")
	for brush in brushes: for face in brush.faces:
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
		_vertices.append_array(face.vertices)
		_vertices.assign(face.vertices)
		_vertices.sort_custom(cmp_winding_angle)
		face.vertices = _vertices
		var triangle_count: int = _vertices.size() - 2
		face.triangle_indices.resize(triangle_count * 3)
		var index := 0
		for i in triangle_count:
			face.triangle_indices[index] = 0
			face.triangle_indices[index + 1] = i + 1
			face.triangle_indices[index + 2] = i + 2
			index += 3

func _generate_geometry(entity_index: int) -> void:
	var node: Node = _entities[entity_index]
	var brushes: Array[EntityBrush] = node.get_meta(&"solid_brushes")
	var origin: Vector3 = node.get_meta(&"entity_origin")
	if brushes.size() == 0: return
	for brush in brushes:
		var mesh := ArrayMesh.new()
		for face in brush.faces:
			if face.vertices.size() < 2: continue
			var arrays: Array = []
			arrays.resize(Mesh.ARRAY_MAX)
			arrays[Mesh.ARRAY_VERTEX] = face.vertices
			if face.vertices.size() % 2 != 0: arrays[Mesh.ARRAY_VERTEX].remove_at(arrays[Mesh.ARRAY_VERTEX].size() - 1)
			mesh.add_surface_from_arrays(Mesh.PRIMITIVE_LINES, arrays)
		var instance := MeshInstance3D.new()
		instance.mesh = mesh
		node.add_child(instance)

func _generate_occlusion(entity_index: int) -> void:
	var node: Node = _entities[entity_index]
	var brushes: Array[Array] = node.get_meta(&"entity_brushes")
	if brushes.size() == 0: return

func _generate_collisions(entity_index: int) -> void:
	var node: Node = _entities[entity_index]
	var brushes: Array[Array] = node.get_meta(&"entity_brushes")
	if brushes.size() == 0: return

func _generate_pathfinding(entity_index: int) -> void:
	var node: Node = _entities[entity_index]
	var brushes: Array[Array] = node.get_meta(&"entity_brushes")
	if brushes.size() == 0: return

func _apply_smoothing(entity_index: int) -> void:
	var node: Node = _entities[entity_index]
	var brushes: Array[Array] = node.get_meta(&"entity_brushes")
	if brushes.size() == 0: return

func _unwrap_uv2(entity_index: int) -> void:
	var node: Node = _entities[entity_index]
	var brushes: Array[Array] = node.get_meta(&"entity_brushes")
	if brushes.size() == 0: return

func _generate_lighting(entity_index: int) -> void:
	var node: Node = _entities[entity_index]

## Cleans-up meta data from enttiy nodes that was only being used for generation
func _clean_up_meta(entity_index: int) -> void:
	_entities[entity_index].remove_meta(&"entity_properties")
	_entities[entity_index].remove_meta(&"entity_classname")
	_entities[entity_index].remove_meta(&"entity_brushes")
	_entities[entity_index].remove_meta(&"solid_brushes")
	_entities[entity_index].remove_meta(&"entity_origin")

## Adds nodes into [SceneTree]. MUST call from main thread
func _add_to_scene_tree(entity_index: int) -> void:
	var node: Node = _entities[entity_index]
	add_child(node, true)
