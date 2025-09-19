@tool
@icon("../icons/qmap.svg")
## .wad file resource
##
## [url]https://developer.valvesoftware.com/wiki/WAD[/url]
## [url]https://www.gamers.org/dEngine/quake/spec/quake-spec34/qkspec_7.htm[/url]
class_name WAD extends Resource

enum WadFormat {
	WAD2,
	WAD3
}

var format := WadFormat.WAD3
## Textures sorted by name
@export var textures: Dictionary[String, Texture2D]
## WAD2 Palettes
@export var palettes: Array[QPalette]
