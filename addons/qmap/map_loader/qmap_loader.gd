class_name QMapLoader extends Node3D

## Default QUnit to Godot scaling
const DEFAULT_SCALE := 32

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
	# Generate entities
	for entity in map.entities:
		if !fgd.classes.has(entity.classname):
			continue
		var fgd_class := fgd.classes.get(entity.classname)
		# Determine node scene
		# Apply properties
		# Generate brushes
		# Finish baking brush geometry
		# Add to SceneTree
	
	print("Finished generating map in %smsec!"%(start_time - Time.get_ticks_msec()))
	return OK
