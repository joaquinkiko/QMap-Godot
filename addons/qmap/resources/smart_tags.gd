## For applying special properties to certain surfaces and entities
class_name QMapSmartTag extends Resource
enum MatchType{
	## Match against texturename (May use ? * wildcards)
	MATERIAL = 0,
	## Match against content flag (use member FaceAttribute.name)
	CONTENT_FLAG = 1,
	## Match against surface flag (use member FaceAttribute.name)
	SURFACE_FLAG = 2,
	## Match against entity classname (May use ? * wildcards)
	CLASSNAME = 3
}
enum SmartProperties{
	## Don't generate occlusion
	TRANSPARENT = 		0b00001,
	## Don't generate collision
	NON_COLLIDING = 	0b00010,
	## Don't generate pathfinding (Will also not generate with [enum SmartProperties.NON_COLLIDING])
	NON_PATHFINDING = 	0b00100,
	## Don't generate mesh (Make sure to also set [enum SmartProperties.TRANSPARENT])
	NON_RENDERED = 		0b01000,
	## Enforces convex collisions (Only effective on [enum MatchType.CLASSNAME])
	ENFORCE_CONVEX = 	0b10000
}
## Editor tag name
@export var name: StringName
## What to match against
@export var match_type: MatchType
## Search pattern (May use ? * wildcards) to match against
@export var pattern: String
## For [enum MatchType.CLASSNAME] only. Default texture to apply in editor
@export var default_texture: StringName
## Tag flags for generation
@export_flags(
	"Transparent:%s"%SmartProperties.TRANSPARENT,
	"Non-colliding:%s"%SmartProperties.NON_COLLIDING,
	"Non-pathfinding:%s"%SmartProperties.NON_PATHFINDING,
	"Non-rendered:%s"%SmartProperties.NON_RENDERED,
	"Enforce Convex:%s"%SmartProperties.ENFORCE_CONVEX
	)
var properties: int
## Overriders [member default_material] for this surface or entity
@export var override_material: Material
func _init(_name := &"", _match := 0, _pattern := "", _texture := &"", _properties := 0) -> void:
	name = _name
	match_type = _match
	pattern = _pattern
	default_texture = _texture
	properties = _properties

func _to_string() -> String: return "%s(T:%s P:'%s' F:%s)"%[name, match_type, pattern, properties]
