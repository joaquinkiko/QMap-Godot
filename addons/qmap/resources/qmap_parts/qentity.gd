## Represent a [QMap] entity for parsing
##
## [url]https://quakewiki.org/wiki/Entity[/url]
class_name QEntity extends Resource

enum FaceFormat{
	STANDARD,
	VALVE_220
	}

enum GroupingType{
	NONE,
	LAYER,
	GROUP}

## Flags for generating solid geometry
enum GeometryFlags{
	## Generate [MeshInstance3D]
	RENDER = 					0b0000001,
	## Generate concave [CollisionShape3D] (Prefered for [StaticBody3D])
	CONCAVE_COLLISIONS = 		0b0000010,
	## Generate multiple convex [CollisionShape3D] (Prefered for [Area3D])
	## (Will take priority over [enum GeometryFlags.CONCAVE_COLLISIONS])
	CONVEX_COLLISIONS = 		0b0000100,
	## Generate [OccluderInstance3D]
	OCCLUSION = 				0b0001000,
	## Generate [NavigationRegion3D]
	NAV_REGION = 				0b0010000,
	## Generate [NavigationObstacle3D]
	NAV_BLOCKING = 				0b0100000,
	## Use only for navigation objects that will move. High performance cost
	NAV_DYNAMIC = 				0b1000000,
}
## Default geometry generation flags (see [enum GeometryFlags])
const GEOMETRY_FLAG_DEFAULT := 	0b0111011

class Brush extends RefCounted:
	var faces: Array[Face]
	## Array of planes from [member faces]
	var planes: Array[Plane]:
		get:
			var output: Array[Plane]
			for face in faces: output.append(face.plane)
			return output
	## Array of uvs from [member faces]
	var uvs: Array[Transform2D]:
		get:
			var output: Array[Transform2D]
			for face in faces: output.append(face.uv)
			return output
	## Array of texturenames from [member faces]
	var texturenames: PackedStringArray:
		get:
			var output: PackedStringArray
			for face in faces: output.append(face.texturename)
			return output

class Face extends RefCounted:
	var points: PackedVector3Array
	var texturename: StringName
	var u_offset: Vector4
	var v_offset: Vector4
	var uv_scale: Vector2
	var format: FaceFormat
	var rotation: float
	var has_surface_flags: bool
	var surface_flag: int
	var contents_flag: int
	var value: int
	var plane: Plane
	var uv: Transform2D

## Classname to find in [FGD]
@export var classname: String:
	get: return properties.get(&"classname", "")
	set(value): properties.set(&"classname", value)
## Property key values to apply when spawned
@export var properties: Dictionary[StringName, String] = {&"classname":""}
## Property "_tb_type"-- either "_tb_group" or "_tb_layer"
var group_type: GroupingType:
	get:
		match properties.get(&"_tb_type", ""):
			"_tb_group": return GroupingType.GROUP
			"_tb_layer": return GroupingType.LAYER
			_: return GroupingType.NONE
## Property "_tb_layer", "_tb_group", or "_tb_id" (in that priority order)
var group_id: int:
	get:
		if properties.has(&"_tb_layer"):
			return properties.get(&"_tb_layer", "-1").to_int()
		elif properties.has(&"_tb_group"):
			return properties.get(&"_tb_group", "-1").to_int()
		else: return properties.get(&"_tb_id", "-1").to_int()
## Property "_tb_layer_omit_from_export"
var omit_from_export: bool:
	get: return properties.has(&"_tb_layer_omit_from_export")
## Property "_tb_name"
var group_name: String:
	get: return properties.get(&"_tb_name", "Unnamed")
## Property "origin"
var origin: Vector3:
	get:
		var raw: PackedStringArray = properties.get(&"origin", "").split(" ", false)
		if raw.size() < 3: return Vector3.ZERO
		return Vector3(
			raw[0].to_float(),
			raw[1].to_float(),
			raw[2].to_float()
		)
## Property "angle" or "mangle" ("mangle" will take priority if both present)
var angle: Vector3:
	get:
		if properties.has(&"mangle"):
			var raw: PackedStringArray = properties.get(&"mangle", "").split(" ", false)
			if raw.size() < 3: return Vector3.ZERO
			return Vector3(
				raw[0].to_float(),
				raw[1].to_float(),
				raw[2].to_float()
			)
		else:
			var _angle: float = properties.get(&"angle", "0").to_float()
			if _angle == -1: return Vector3.RIGHT * 90 # Up
			if _angle == -2: return Vector3.RIGHT * -90 # Down
			return Vector3.UP * _angle # Y rotation
## Property "scale" translated to [Vector3]
var scale: Vector3:
	get: return Vector3.ONE * properties.get(&"scale", "1").to_float()
## Array of strings from property "wad"
var wad_paths: PackedStringArray:
	get: return properties.get(&"wad", "").split(";", false)
## Array of unique texturenames present across all brush faces
var texturenames: PackedStringArray:
	get:
		var output: PackedStringArray
		for brush in brushes: for face in brush.faces:
			if !output.has(face.texturename): output.append(face.texturename)
		return output
## Array of strings from property "_tb_mod"
var mods: PackedStringArray:
	get: return properties.get(&"_tb_mod", "").split(";", false)
## Property "_phong"
var phong: bool:
	get: return bool(properties.get(&"_phong", "0").to_int())
## Property "_phong_angle"
var phong_angle: float:
	get: return properties.get(&"_phong_angle", "89.0").to_float()
## Array of brushes
var brushes: Array[Brush]

## Returns true if classname exists in [param fgd]
func is_defined(fgd: FGD) -> bool:
	return fgd.classes.has(classname)

## Returns true if this class is a SolidClass as defined by [param fgd]
func is_solid(fgd: FGD) -> bool:
	var fgd_class: FGDClass = fgd.classes.get(classname)
	if fgd_class == null: return false
	return fgd_class.class_type == FGDClass.ClassType.SOLID

## Returns dictionary of properties (both defined, and default values)
## parsed into their correct [Variant] types as defined by [param fgd]
func get_parsed_properties(settings: QMapSettings, mods := PackedStringArray([])) -> Dictionary[StringName, Variant]:
	var fgd_class: FGDClass = settings.fgd.classes.get(classname)
	if fgd_class == null: return properties
	var parsed_properties: Dictionary[StringName, Variant]
	var to_parse: Dictionary[StringName, String]
	for base in fgd_class.base_classes:
		if !settings.fgd.classes.has(base): continue
		settings.fgd.classes[base]
		for key in settings.fgd.classes[base].properties.keys():
			to_parse.set(key, settings.fgd.classes[base].properties[key].default_value)
			if settings.fgd.classes[base].properties[key].type == FGDEntityProperty.PropertyType.FLAGS:
				var default_value: int
				for flag in settings.fgd.classes[base].properties[key].default_flags:
					default_value += flag
				to_parse.set(key, "%s"%default_value)
	for key in fgd_class.properties.keys():
		to_parse.set(key, fgd_class.properties[key].default_value)
		if fgd_class.properties[key].type == FGDEntityProperty.PropertyType.FLAGS:
			var default_value: int
			for flag in fgd_class.properties[key].default_flags:
				default_value += flag
			to_parse.set(key, "%s"%default_value)
	for key in properties.keys():
		to_parse.set(key, properties[key])
	for key in to_parse:
		var raw_value: String = to_parse[key]
		var value: Variant
		match fgd_class.properties.get(key, FGDEntityProperty.new()).default_value:
			FGDEntityProperty.PropertyType.INTEGER: 
				value = raw_value.to_int()
			FGDEntityProperty.PropertyType.FLOAT: 
				value = raw_value.to_float()
			FGDEntityProperty.PropertyType.FLAGS:
				value = raw_value.to_int()
			FGDEntityProperty.PropertyType.CHOICES: 
				value = raw_value.to_int()
			FGDEntityProperty.PropertyType.ANGLE:
				var nums: PackedFloat64Array
				for num in raw_value.split(" ", false):
					nums.append(num.to_float())
				if nums.size() >= 3: value = Vector3(nums[0], nums[1], nums[2])
				else: value = Vector3.ZERO
			FGDEntityProperty.PropertyType.VECTOR: 
				var nums: PackedFloat64Array
				for num in raw_value.split(" ", false):
					nums.append(num.to_float())
				if nums.size() >= 4: value = Vector4(nums[0], nums[1], nums[2], nums[3])
				elif nums.size() >= 3: value = Vector3(nums[0], nums[1], nums[2])
				elif nums.size() >= 2: value = Vector2(nums[0], nums[1])
				else: value = Vector3.ONE * raw_value.to_float()
			FGDEntityProperty.PropertyType.COLOR_255: 
				var nums: PackedFloat64Array
				for num in raw_value.split(" ", false):
					nums.append(num.to_int())
				if nums.size() >= 3: value = Color8(nums[0], nums[1], nums[2])
				else: value = Color8(0,0,0)
			FGDEntityProperty.PropertyType.COLOR_1: 
				var nums: PackedFloat64Array
				for num in raw_value.split(" ", false):
					nums.append(num.to_float())
				if nums.size() >= 3: value = Color(nums[0], nums[1], nums[2])
				else: value = Color(0,0,0)
			FGDEntityProperty.PropertyType.DECAL:
				value = null
				for texture_path in settings.get_paths_decals(mods):
					if ResourceLoader.exists("%s/%s"%[texture_path, raw_value]):
						value = ResourceLoader.load("%s/%s"%[texture_path, raw_value])
						break
			FGDEntityProperty.PropertyType.STUDIO:
				value = null
				for model_path in settings.get_paths_models(mods):
					if ResourceLoader.exists("%s/%s"%[model_path, raw_value]):
						value = ResourceLoader.load("%s/%s"%[model_path, raw_value])
						break
			FGDEntityProperty.PropertyType.SPRITE:
				value = null
				for texture_path in settings.get_paths_decals(mods):
					if ResourceLoader.exists("%s/%s"%[texture_path, raw_value]):
						value = ResourceLoader.load("%s/%s"%[texture_path, raw_value])
						break
			FGDEntityProperty.PropertyType.SOUND:
				value = null
				for audio_path in settings.get_paths_sounds(mods):
					if ResourceLoader.exists("%s/%s"%[audio_path, raw_value]):
						value = ResourceLoader.load("%s/%s"%[audio_path, raw_value])
						break
			FGDEntityProperty.PropertyType.SCALE:
				value = raw_value.to_float()
			FGDEntityProperty.PropertyType.TARGET_SOURCE:
				value = StringName(raw_value)
			FGDEntityProperty.PropertyType.TARGET_DESTINATION:
				value = StringName(raw_value)
			_: value = raw_value
		parsed_properties.set(key, value)
	return parsed_properties
