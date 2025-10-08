@tool
@icon("../icons/qmap.svg")
## .map file resource
##
## [url]https://quakewiki.org/wiki/Quake_Map_Format[/url]
## [url]https://developer.valvesoftware.com/wiki/MAP_(file_format)[/url]
class_name QMap extends Resource

const TEXTURE_ORIGIN := &"origin"
const TEXTURE_SKIP := &"skip"
const TEXTURE_CLIP := &"clip"

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
