class_name QMapSettings extends Resource

## [FGD] to initialize entities with
@export var fgd: FGD
@export_group("Scaling")
## QUnit to Godot scaling ratio
@export_range(1, 256, 1) var scaling: int = 32
## Ratio for UV unwrapping
@export_range(1, 256, 1) var uv_unwrap_texel_ratio: int = 16
@export_group("Special Textures")
## Clip texturename
@export var texture_clip: StringName = "clip"
## Skip texturename
@export var texture_skip: StringName = "skip"
## Origin texturename
@export var texture_origin: StringName = "origin"
## Empty texturename
@export var texture_empty: StringName = "__TB_empty"
@export_group("Texture Settings")
## Wad files to always load during map generation
@export var extra_wads: Array[WAD]
## Valid texture extensions to load from
@export var texture_extensions: PackedStringArray = ["png", "jpg", "jpeg", "bmp", "tga"]
## Valid material extensions to load from
@export var material_extensions: PackedStringArray = ["tres"]
## If true, generated materials will be cached for faster loading
@export var cache_materials: bool = true
## Directory to cache material when [member cache_materials] is true
@export var cache_path: String = "user://material_cache"
@export_group("Resource Paths")
## Paths sorted by priority to load scenes from
@export_dir var paths_scenes: PackedStringArray = ["res://"]
## Paths sorted by priority to load scripts from
@export_dir var paths_scripts: PackedStringArray = ["res://"]
## Paths sorted by priority to load textures from
@export_dir var paths_textures: PackedStringArray = ["res://"]
## Paths sorted by priority to load materials from
@export_dir var paths_materials: PackedStringArray = ["res://"]
## Paths sorted by priority to load shaders from
@export_dir var paths_shaders: PackedStringArray = ["res://"]
## Paths sorted by priority to load sounds from
@export_dir var paths_sounds: PackedStringArray = ["res://"]
## Paths sorted by priority to load models from
@export_dir var paths_models: PackedStringArray = ["res://"]
## Paths sorted by priority to load wads from
@export_dir var paths_wads: PackedStringArray = ["res://"]
@export_group("Default Material")
## Default material for new textures
@export var default_material: Material
## Path to apply texture for [member default_material]
@export var default_material_texture_path: String = "albedo_texture"

var _scale_factor: float:
	get: return 1.0/float(scaling)
