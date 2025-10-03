class_name QMapLoader extends Node3D

const _VERTEX_EPSILON := 0.008
const _VERTEX_EPSILON2 := _VERTEX_EPSILON * _VERTEX_EPSILON

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

## Temporary for testing, normally map loading should be called by user
func _ready() -> void:
	generate_map()

## Generates the [QMap]
func generate_map() -> Error:
	var start_time := Time.get_ticks_msec()
	print("Generating map '%s'..."%map.resource_path)
	if map == null || fgd == null:
		printerr("Must have both Map and FGD to generate map")
		return ERR_INVALID_DATA
	# Load internal wads
	for entity in map.entities:
		if entity.properties.has("wad"):
			if ResourceLoader.exists("%s/%s"%[DEFAULT_PATH_WADS, entity.properties["wad"]]):
				var has_wad: bool
				for wad in wads:
					if wad.resource_path == "%s/%s"%[DEFAULT_PATH_WADS, entity.properties["wad"]]:
						has_wad = true
						continue
				if !has_wad:
					wads.append(ResourceLoader.load("%s/%s"%[DEFAULT_PATH_WADS, entity.properties["wad"]]))
	# Generate entities
	for entity in map.entities:
		if !fgd.classes.has(entity.classname): continue
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
		if node.has_method("_load_properties"):
			node.call("_load_properties", entity.properties)
		# Generate brushes
		if fgd_class.class_type == FGDClass.ClassType.SOLID && entity.brushes.size() > 0:
			pass
		# Add to SceneTree
		node.name = entity.classname
		add_child(node, true)
	
	print("Finished generating map in %smsec!"%(Time.get_ticks_msec() - start_time))
	return OK
