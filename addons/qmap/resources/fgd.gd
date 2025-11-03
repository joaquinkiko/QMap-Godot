@tool
@icon("../icons/qmap.svg")
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
## Base [FGD] resources to inheret from (they must be in same directory)
@export var base_fgds: PackedStringArray
## Optional max map size in q-units
@export var max_map_size : Vector2i

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
