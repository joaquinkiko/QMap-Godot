class_name QMapLoader extends Node3D

const _VERTEX_EPSILON := 0.008
const _VERTEX_EPSILON2 := _VERTEX_EPSILON * _VERTEX_EPSILON
const _SCALE_FACTOR: float = 1.0 / DEFAULT_SCALE
const _HYPERPLANE_SIZE: float = 512.0

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
@export var map: QMap
## [FGD] to initialize entities with
@export var fgd: FGD
## [WAD] files to read textures from
@export var wads: Array[WAD]
@export_group("Additional Settings")
## When true will load any [WAD] listed in [QMap] properties under the key "wads"
@export var auto_load_map_wads: bool = true

var _entities: Array[Node]
var _materials: Dictionary[StringName, Material]

## Temporary for testing, normally map loading should be called by user
func _ready() -> void:
	generate_map()

## Generates the [QMap]
func generate_map() -> Error:
	var start_time := Time.get_ticks_msec()
	var interval_time := start_time
	print("Generating map '%s'..."%map.resource_path)
	if map == null || fgd == null:
		printerr("Must have both Map and FGD to generate map")
		return ERR_INVALID_DATA
	var task_id: int
	# Load internal wads
	task_id = WorkerThreadPool.add_group_task(
		_load_internal_wads, map.entities.size(), -1, false, "Load internal wads")
	#while !WorkerThreadPool.is_group_task_completed(task_id): await get_tree().process_frame
	WorkerThreadPool.wait_for_group_task_completion(task_id)
	print("\t-Loaded wads in %smsec..."%(Time.get_ticks_msec() - interval_time))
	interval_time = Time.get_ticks_msec()
	# Generate entities
	task_id = WorkerThreadPool.add_group_task(
		_generate_entity, map.entities.size(), -1, false, "Generate entities")
	#while !WorkerThreadPool.is_group_task_completed(task_id): await get_tree().process_frame
	WorkerThreadPool.wait_for_group_task_completion(task_id)
	print("\t-Generated entities in %smsec..."%(Time.get_ticks_msec() - interval_time))
	interval_time = Time.get_ticks_msec()
	# Generate Materials
	task_id = WorkerThreadPool.add_group_task(
		_generate_materials, _entities.size(), -1, false, "Generate Materials")
	#while !WorkerThreadPool.is_group_task_completed(task_id): await get_tree().process_frame
	WorkerThreadPool.wait_for_group_task_completion(task_id)
	print("\t-Generated entities in %smsec..."%(Time.get_ticks_msec() - interval_time))
	interval_time = Time.get_ticks_msec()
	# Generate brush vertices
	task_id = WorkerThreadPool.add_group_task(
		_generate_vertices, _entities.size(), -1, false, "Generate brush vertices")
	#while !WorkerThreadPool.is_group_task_completed(task_id): await get_tree().process_frame
	WorkerThreadPool.wait_for_group_task_completion(task_id)
	print("\t-Generated vertices in %smsec..."%(Time.get_ticks_msec() - interval_time))
	interval_time = Time.get_ticks_msec()
	# Determine entity origins
	task_id = WorkerThreadPool.add_group_task(
		_apply_origins, _entities.size(), -1, false, "Determine entity origins")
	#while !WorkerThreadPool.is_group_task_completed(task_id): await get_tree().process_frame
	WorkerThreadPool.wait_for_group_task_completion(task_id)
	print("\t-Applied origins in %smsec..."%(Time.get_ticks_msec() - interval_time))
	interval_time = Time.get_ticks_msec()
	# Wind faces
	task_id = WorkerThreadPool.add_group_task(
		_wind_faces, _entities.size(), -1, false, "Wind faces")
	#while !WorkerThreadPool.is_group_task_completed(task_id): await get_tree().process_frame
	WorkerThreadPool.wait_for_group_task_completion(task_id)
	print("\t-Wound faces in %smsec..."%(Time.get_ticks_msec() - interval_time))
	interval_time = Time.get_ticks_msec()
	# Generate geometry
	task_id = WorkerThreadPool.add_group_task(
		_generate_geometry, _entities.size(), -1, false, "Generate geometry")
	#while !WorkerThreadPool.is_group_task_completed(task_id): await get_tree().process_frame
	WorkerThreadPool.wait_for_group_task_completion(task_id)
	print("\t-Generated geometry in %smsec..."%(Time.get_ticks_msec() - interval_time))
	interval_time = Time.get_ticks_msec()
	# Generate occlusion
	task_id = WorkerThreadPool.add_group_task(
		_generate_occlusion, _entities.size(), -1, false, "Generate occlusion")
	#while !WorkerThreadPool.is_group_task_completed(task_id): await get_tree().process_frame
	WorkerThreadPool.wait_for_group_task_completion(task_id)
	print("\t-Generated occlusion in %smsec..."%(Time.get_ticks_msec() - interval_time))
	interval_time = Time.get_ticks_msec()
	# Generate collisions
	task_id = WorkerThreadPool.add_group_task(
		_generate_collisions, _entities.size(), -1, false, "Generate collisions")
	#while !WorkerThreadPool.is_group_task_completed(task_id): await get_tree().process_frame
	WorkerThreadPool.wait_for_group_task_completion(task_id)
	print("\t-Generated collisions in %smsec..."%(Time.get_ticks_msec() - interval_time))
	interval_time = Time.get_ticks_msec()
	# Generate pathfinding
	task_id = WorkerThreadPool.add_group_task(
		_generate_pathfinding, _entities.size(), -1, false, "Generate pathfinding")
	#while !WorkerThreadPool.is_group_task_completed(task_id): await get_tree().process_frame
	WorkerThreadPool.wait_for_group_task_completion(task_id)
	print("\t-Generated pathfinding in %smsec..."%(Time.get_ticks_msec() - interval_time))
	interval_time = Time.get_ticks_msec()
	# Unwrap UV2s
	task_id = WorkerThreadPool.add_group_task(
		_unwrap_uv2, _entities.size(), -1, false, "Unwrap UV2s")
	#while !WorkerThreadPool.is_group_task_completed(task_id): await get_tree().process_frame
	WorkerThreadPool.wait_for_group_task_completion(task_id)
	print("\t-Unwrapped UV2s in %smsec..."%(Time.get_ticks_msec() - interval_time))
	interval_time = Time.get_ticks_msec()
	# Apply smoothing
	task_id = WorkerThreadPool.add_group_task(
		_apply_smoothing, _entities.size(), -1, false, "Apply smoothing")
	#while !WorkerThreadPool.is_group_task_completed(task_id): await get_tree().process_frame
	WorkerThreadPool.wait_for_group_task_completion(task_id)
	print("\t-Applied smoothing in %smsec..."%(Time.get_ticks_msec() - interval_time))
	interval_time = Time.get_ticks_msec()
	# Generate lighting
	task_id = WorkerThreadPool.add_group_task(
		_generate_lighting, _entities.size(), -1, false, "Generate lighting")
	#while !WorkerThreadPool.is_group_task_completed(task_id): await get_tree().process_frame
	WorkerThreadPool.wait_for_group_task_completion(task_id)
	print("\t-Generated lighting in %smsec..."%(Time.get_ticks_msec() - interval_time))
	interval_time = Time.get_ticks_msec()
	# Clean-up Meta
	task_id = WorkerThreadPool.add_group_task(
		_clean_up_meta, _entities.size(), -1, false, "Clean-up Meta")
	#while !WorkerThreadPool.is_group_task_completed(task_id): await get_tree().process_frame
	WorkerThreadPool.wait_for_group_task_completion(task_id)
	print("\t-Cleaned-up metadata in %smsec..."%(Time.get_ticks_msec() - interval_time))
	interval_time = Time.get_ticks_msec()
	# Add nodes to scene tree
	for n in _entities.size(): _add_to_scene_tree(n)
	print("\t-Added nodes to SceneTree %smsec..."%(Time.get_ticks_msec() - interval_time))
	interval_time = Time.get_ticks_msec()
	print("Finished generating map in %smsec!"%(Time.get_ticks_msec() - start_time))
	return OK

## Loads wads from entites with "wad" property
func _load_internal_wads(entity_index: int) -> void:
	var entity: QEntity = map.entities[entity_index]
	if entity.properties.has("wad"):
		if ResourceLoader.exists("%s/%s"%[DEFAULT_PATH_WADS, entity.properties["wad"]]):
			var has_wad: bool
			for wad in wads:
				if wad.resource_path == "%s/%s"%[DEFAULT_PATH_WADS, entity.properties["wad"]]:
					has_wad = true
					continue
			if !has_wad:
				wads.append(ResourceLoader.load("%s/%s"%[DEFAULT_PATH_WADS, entity.properties["wad"]]))

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

func _generate_materials(entity_index: int) -> void:
	var node: Node = _entities[entity_index]
	var brushes: Array[Array] = node.get_meta(&"entity_brushes")
	var materials: Dictionary[StringName, Material]
	for brush in brushes: for plane in brush: materials[plane[&"texture"]] = null
	for texture_name in materials.keys():
		if _materials.has(texture_name): continue
		materials[texture_name] = PlaceholderMaterial.new()
		
		_materials[texture_name] = materials[texture_name]

## Generate vertices for each brush
func _generate_vertices(entity_index: int) -> void:
	var node: Node = _entities[entity_index]
	var brushes: Array[Array] = node.get_meta(&"entity_brushes")
	var properties: Dictionary[StringName, Variant] = node.get_meta(&"entity_properties")
	var vertex_merge_distance: float = 0
	if properties.has("_vertex_merge_distance"):
		vertex_merge_distance = properties["_vertex_merge_distance"]
	var planes: Array[Plane]
	var uvs: Array[Transform2D]
	var uv_axes_array: Array[PackedVector3Array]
	for i in brushes.size():
		for n in brushes[i].size():
			var points := PackedVector3Array([
				brushes[i][n][&"p1"] * _SCALE_FACTOR,
				brushes[i][n][&"p2"] * _SCALE_FACTOR,
				brushes[i][n][&"p3"] * _SCALE_FACTOR
				])
			var plane := Plane(points[0], points[1], points[2])
			planes.append(plane)
			var uv := Transform2D.IDENTITY
			var uv_axes: PackedVector3Array
			if brushes[i][n][&"u_offset"] is int || brushes[i][n][&"u_offset"] is float:
				uv.origin = Vector2(brushes[i][n][&"u_offset"],brushes[i][n][&"v_offset"])
				var _rotation := deg_to_rad(brushes[i][n][&"rotation"])
				uv.x = Vector2(cos(_rotation), -sin(_rotation)) * brushes[i][n][&"u_scale"] * _SCALE_FACTOR
				uv.y = Vector2(sin(_rotation), cos(_rotation)) * brushes[i][n][&"v_scale"] * _SCALE_FACTOR
			else:
				uv.origin.x = brushes[i][n][&"u_offset"].w
				uv.origin.y = brushes[i][n][&"v_offset"].w
				uv_axes.append(Vector3(brushes[i][n][&"u_offset"].x,brushes[i][n][&"u_offset"].y,brushes[i][n][&"u_offset"].z))
				uv_axes.append(Vector3(brushes[i][n][&"v_offset"].x,brushes[i][n][&"v_offset"].y,brushes[i][n][&"v_offset"].z))
				uv.x = Vector2(brushes[i][n][&"u_scale"], 0.0) * _SCALE_FACTOR
				uv.y = Vector2(0.0, brushes[i][n][&"v_scale"]) * _SCALE_FACTOR
			uvs.append(uv)
			uv_axes_array.append(uv_axes)
		for n in brushes[i].size():
			var vertices: PackedVector3Array
			var winding: PackedVector3Array
			var up := Vector3.UP
			if abs(planes[n].normal.dot(up)) > 0.9:
				up = Vector3.RIGHT
			var right: Vector3 = planes[n].normal.cross(up).normalized()
			var forward: Vector3 = right.cross(planes[n].normal).normalized()
			var centroid: Vector3 = planes[n].get_center()
			winding.append(centroid + (right *  _HYPERPLANE_SIZE) + (forward *  _HYPERPLANE_SIZE))
			winding.append(centroid + (right * -_HYPERPLANE_SIZE) + (forward *  _HYPERPLANE_SIZE))
			winding.append(centroid + (right * -_HYPERPLANE_SIZE) + (forward * -_HYPERPLANE_SIZE))
			winding.append(centroid + (right *  _HYPERPLANE_SIZE) + (forward * -_HYPERPLANE_SIZE))
			for other_n in brushes[i].size():
				if other_n == n: continue
				winding = Geometry3D.clip_polygon(winding, planes[other_n])
				if winding.is_empty(): break
			if vertex_merge_distance > 0:
				var merged_winding : PackedVector3Array
				var prev_vtx: Vector3 = winding[0].snappedf(vertex_merge_distance)
				merged_winding.append(prev_vtx)
				for j in range(1, winding.size()):
					var cur_vtx : Vector3 = winding[j].snappedf(vertex_merge_distance)
					if prev_vtx != cur_vtx:
						merged_winding.append(cur_vtx)
					prev_vtx = cur_vtx
				winding = merged_winding
			vertices = winding
			var normals: PackedVector3Array
			normals.resize(vertices.size())
			normals.fill(planes[n].normal)
			var tangents_raw: PackedFloat32Array
			if uv_axes_array[n].size() >= 2:
				var u_axis: Vector3 = uv_axes_array[n][0].normalized()
				var v_axis: Vector3 = uv_axes_array[n][1].normalized()
				var v_sign: float = -signf(normals[n].cross(u_axis).dot(v_axis))
				tangents_raw = [u_axis.x, u_axis.y, u_axis.z, v_sign]
			else:
				var dx := planes[n].normal.dot(Vector3.UP)
				var dy := planes[n].normal.dot(Vector3.BACK)
				var dz := planes[n].normal.dot(Vector3.RIGHT)
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
				v_sign *= signf(uvs[n].get_scale().y)
				if !planes[n].normal == Vector3.ZERO:
					u_axis = u_axis.rotated(planes[n].normal, deg_to_rad(-uvs[n].get_rotation()) * v_sign)
				tangents_raw = [u_axis.x, u_axis.y, u_axis.z, v_sign]
			var tangents: PackedFloat32Array
			for j in vertices.size():
				tangents.append(tangents_raw[1]) # Y
				tangents.append(tangents_raw[2]) # Z
				tangents.append(tangents_raw[0]) # X
				tangents.append(tangents_raw[3]) # W
	node.set_meta(&"brush_planes", planes)
	node.set_meta(&"brush_uvs", uvs)
	node.set_meta(&"brush_uv_axes", uv_axes_array)

func _apply_origins(entity_index: int) -> void:
	var node: Node = _entities[entity_index]
	var brushes: Array[Array] = node.get_meta(&"entity_brushes")
	if brushes.size() == 0: return
	var properties: Dictionary[StringName, Variant] = node.get_meta(&"entity_properties")
	if brushes.size() == 0: return
	var origin := Vector3.ZERO
	if properties.has("origin"): origin = properties["origin"]

func _wind_faces(entity_index: int) -> void:
	var node: Node = _entities[entity_index]
	var brushes: Array[Array] = node.get_meta(&"entity_brushes")
	for i in brushes.size(): for n in brushes[i].size():
		pass

func _generate_geometry(entity_index: int) -> void:
	var node: Node = _entities[entity_index]
	var brushes: Array[Array] = node.get_meta(&"entity_brushes")
	if brushes.size() == 0: return

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
	_entities[entity_index].remove_meta(&"brush_planes")
	_entities[entity_index].remove_meta(&"brush_uvs")
	_entities[entity_index].remove_meta(&"brush_uv_axes")

## Adds nodes into [SceneTree]. MUST call from main thread
func _add_to_scene_tree(entity_index: int) -> void:
	var node: Node = _entities[entity_index]
	add_child(node, true)
