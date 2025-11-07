@tool
@icon("../../icons/qmap.svg")
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
@export var textures: Dictionary[StringName, Texture2D]
## WAD2 Palette
@export var palettes: Dictionary[StringName, QPalette]
## WAD directory entries
var dir_entries: Array[Dictionary]
## Raw data for textures
var mipmap_data: Dictionary[StringName, Array]
## Mip offsets for textures
var mip_offsets: Dictionary[StringName, PackedInt32Array]
## Offset of directories
var dir_offset: int
