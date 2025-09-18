@tool
@icon("../icons/qmap.svg")
## .map file resource
class_name QMap extends Resource

## Header comments
@export_multiline var header: String
## Entities to generate
@export var entities: Array[QEntity]
