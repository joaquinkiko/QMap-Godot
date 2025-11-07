@tool
@icon("../../icons/qmap.svg")
## .fgd (Forge Game Data) file defining entity classes for maps.
##
## [url]https://developer.valvesoftware.com/wiki/FGD[/url]
class_name FGD extends Resource

## Header comments
@export_multiline var header: String
## [FGDClass] sorted by classname (typically limit to 63 characters)
## (white space will be removed)
@export var classes: Dictionary[String, FGDClass]
@export_group("Optional")
## Filenames of [FGD] resources to inheret from
## (they must be in same directory or root directory unless using "base.fgd")
@export var base_fgds: PackedStringArray
## Optional max map size in q-units
@export var max_map_size : Vector2i
## True if [member base_fgds] have been loaded with [method load_base_fgds]
var _has_loaded_base: bool = false

## Recursively returns default property of entity and it's bases. Keep [param _depth_check] at 0.
func get_default_properties(classname: String, _depth_check: int = 0) -> Dictionary[StringName, String]:
	if _depth_check > 999: return {}
	var output: Dictionary[StringName, String]
	if classes.has(classname):
		for base in classes[classname].base_classes:
			output.assign(get_default_properties(base, _depth_check + 1))
		for key in classes[classname].properties.keys():
			match classes[classname].properties[key].type: 
				FGDEntityProperty.PropertyType.FLAGS:
					var default_value: int
					for flag in classes[classname].properties[key].default_flags:
						default_value += flag
					output.set(key, "%s"%default_value)
				_:
					output.set(key, classes[classname].properties[key].default_value)
	return output

## Adds base classes from base_fgds to this FGD. Keep [param _depth_check] at 0
func load_base_fgds(_depth_check: int = 0) -> void:
	if _has_loaded_base || _depth_check > 999 || resource_path.is_empty(): return
	for base_fgd in base_fgds:
		if base_fgd.is_empty(): continue
		var path := "%s/%s"%[resource_path.get_base_dir(), base_fgd]
		if !ResourceLoader.exists(path) && base_fgd == "base.fgd":
			path = "res://addons/qmap/default_resources/base.fgd"
		if !ResourceLoader.exists(path):
			path = "res://%s"%base_fgd
		if !ResourceLoader.exists(path):
			printerr("Missing @include %s for %s"%[base_fgds, resource_path])
			continue
		var base: FGD = ResourceLoader.load(path)
		if base == null:
			printerr("Error loading @include %s for %s"%[base_fgds, resource_path])
			continue
		base.load_base_fgds(_depth_check + 1)
		if max_map_size == Vector2i.ZERO: max_map_size = base.max_map_size
		for key in base.classes.keys():
			if classes.has(key):
				for prop_key in base.classes[key].properties:
					if !classes[key].properties.has(prop_key):
						classes[key].properties[prop_key] = base.classes[key].properties[prop_key]
			else:
				classes[key] = base.classes[key]
	_has_loaded_base = true

## Returns resource paths base fgds recursively. Don't modify params
func get_base_fgd_paths(_is_root: bool = true, _depth_check: int = 0) -> PackedStringArray:
	var output: PackedStringArray
	if _depth_check > 999 || resource_path.is_empty(): return []
	for base_fgd in base_fgds:
		if base_fgd.is_empty(): continue
		if !ResourceLoader.exists("%s/%s"%[resource_path.get_base_dir(), base_fgd]):
			continue
		var base: FGD = ResourceLoader.load("%s/%s"%[resource_path.get_base_dir(), base_fgd])
		if base == null: continue
		output = base.get_base_fgd_paths(false)
	if !_is_root: output.append(resource_path)
	return output
