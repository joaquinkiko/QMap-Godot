## Represent a [QMap] entity for parsing
class_name QEntity extends Resource

## Classname to find in [FGD]
@export var classname: String
## Property key values to apply when spawned
@export var properties: Dictionary[String, String]
## Arrays of Dictionaries representing brush planes, with the keys:
## [br]p1 p2 p3 texture u_offset v_offset rotation u_scale v_scale
## [br](may also include: surface_flag contents_flag value)
@export var brushes: Array[Array]
