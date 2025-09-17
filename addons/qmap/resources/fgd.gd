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
## Optional max map size in q-units
@export var max_map_size : Vector2i
