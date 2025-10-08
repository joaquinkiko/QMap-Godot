@tool
@icon("../icons/qmap.svg")
## .map file resource
##
## [url]https://quakewiki.org/wiki/Quake_Map_Format[/url]
## [url]https://developer.valvesoftware.com/wiki/MAP_(file_format)[/url]
class_name QMap extends Resource

## Game name (for use with Trenchbroom)
@export var game_name: String
## Format name (for use with Trenchbroom)
@export var format_name: String
## Header comments
@export_multiline var header: String
## Entities to generate
@export var entities: Array[QEntity]
## Add headers like "// entity 0" before each entity
@export var use_entity_headers: bool
## Property value of "message" from "worldspawn" entity
var message: String:
	get:
		for entity in entities:
			if !entity.classname == "worldspawn": continue
			return entity.properties.get(&"message", "")
		return ""
## Array of wad paths from entities (typically "wad" in "worldspawn")
var wad_paths: PackedStringArray:
	get:
		var output: PackedStringArray
		for entity in entities: output.append_array(entity.wad_paths)
		return output
## Array of mods defined by "_tb_mod" from "worldspawn" entity
var mods: PackedStringArray:
	get:
		for entity in entities: 
			if entity.mods.size() > 0: return entity.mods
		return []
## Array of unique texturenames used throughout entity brushes
var texturenames: PackedStringArray:
	get:
		var output: PackedStringArray
		for entity in entities: for texturename in entity.texturenames:
			if !output.has(texturename): output.append(texturename)
		return output
