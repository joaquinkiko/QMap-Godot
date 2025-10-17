class_name QMapSettings extends Resource

## [FGD] to initialize entities with
@export var fgd: FGD = preload("res://addons/qmap/default_resources/base.fgd")
@export_group("Scaling")
## QUnit to Godot scaling ratio
@export_range(1, 256, 1) var scaling: int = 32
## Ratio for UV unwrapping
@export_range(1, 256, 1) var uv_unwrap_texel_ratio: int = 16
## If true will unwrap mesh UVs for lightmapping
@export var unwrap_uvs: bool = false
## Defines typical map bounds
@export var soft_map_bounds: AABB = AABB(Vector3.ONE * 4096, -Vector3.ONE * 4096)
@export_group("Special Textures")
## This texture will be used to identify orign brushes. This also won't create collisions, nor be rendered
@export var texture_origin: StringName = "origin"
## These textures will just use the default placeholder
@export var empty_textures: Array[StringName] = ["__tb_empty"]
@export var smart_tags: Array[QMapSmartTag]
@export_group("Face Attributes")
## Surface flags in bitflag order (1,2,4...). May have up to 32. Null fields will be treated as unused
@export var surface_flags: Array[QMapFaceAttribute]
## Content flags in bitflag order (1,2,4...). May have up to 32. Null fields will be treated as unused
@export var content_flags: Array[QMapFaceAttribute]
@export_group("Texture Settings")
## Wad files to always load during map generation
@export var extra_wads: Array[WAD]
## Valid texture extensions to load from
@export var texture_extensions: PackedStringArray = ["png", "jpg", "jpeg", "bmp", "tga"]
## Valid material extensions to load from
@export var material_extensions: PackedStringArray = ["tres"]
@export_group("Resource Paths")
## Base path relative to res:// for loading resources
@export var base_path: StringName = &"."
## Path relative to [base_path] to load textures and Wads
@export var path_textures: StringName = &"textures"
## Path relative to [base_path] to decal textures
@export var path_decals: StringName = &"decals"
## Path relative to [base_path] to load materials
@export var path_materials: StringName = &"materials"
## Path relative to [base_path] to load audio
@export var path_sounds: StringName = &"sounds"
## Path relative to [base_path] to load models
@export var path_models: StringName = &"models"
## Path relative to [base_path] to load Scenes
@export var path_scenes: StringName = &"scenes"

@export_group("Default Material")
## Default material for new textures
@export var default_material: Material
## Path to apply texture for [member default_material]
@export var default_material_texture_path: String = "albedo_texture"
## Path to apply transparency setting for [member default_material]
@export var default_material_transparency_path: String = "transparency"
## Value to apply to [member default_material_transparency_path] for Alphatest textures
## (Defaults to [member BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR])
@export var transparency_alphatest_value: int = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
## Whether to allow [AnimatedTexture] to be generated for certain textures
@export var allow_animated_textures: bool = true
## Animated texture prefixes
@export var animated_texture_prefixes: PackedStringArray = ["+"]
## Default speed scale for animated texture playback
## (by default will loop through textures once per second)
@export var animated_texture_speed_scale: float = 1.0
@export_group("PBR textures")
## Whether to search for pbr textures
@export var use_pbr: bool = true
## Texture suffix for normal map
@export var suffix_normal: String = "_normal"
## Texture suffix for metallic map
@export var suffix_metallic: String = "_metallic"
## Texture suffix for roughness map
@export var suffix_roughness: String = "_roughness"
## Texture suffix for emission map
@export var suffix_emission: String = "_emission"
## Texture suffix for ao map
@export var suffix_ao: String = "_ao"
## Texture suffix for height map
@export var suffix_height: String = "_height"
@export_group("Worldspawn Properties")
## Whether worldspawn should generate [WorldEnvironment] settings
@export var worldspawn_generate_enviroment: bool = true
## Whether worldspawn should generate a skybox
@export var worldspawn_generate_skybox: bool = true
## Whether worldspawn should generate [DirectionalLight3D] settings
@export var worldspawn_generate_sunlight: bool = true
## Material for skybox
@export var custom_sky_material: Material
## Path to apply texture to [member skybox_material]
@export var custom_sky_texture_path: String = "panorama"
## Worldspawn proprty for defining [WorldEnvironment] ambient light level
@export var worldspawn_ambient_light: StringName = &"light"
## Worldspawn proprty for defining [WorldEnvironment] ambient light color
@export var worldspawn_ambient_color: StringName = &"_minlight_color"
## Worldspawn proprty for defining texture to load into [WorldEnvironment] sky
@export var worldspawn_skyname: StringName = &"skyname"
## Worldspawn property for defining [DirectionalLight3D] light level
@export var worldspawn_sunlight: StringName = &"_sunlight"
## Worldspawn property for defining [DirectionalLight3D] light angle
@export var worldspawn_sun_angle: StringName = &"_sun_mangle"
## Worldspawn property for defining [DirectionalLight3D] light color
@export var worldspawn_sun_color: StringName = &"_sunlight_color"
## Worldspawn property for defining if [DirectionalLight3D] should cast shadows
@export var worldspawn_sun_shadows: StringName = &"_sun_shadows"
## Worldspawn property for defining [DirectionalLight3D] angular distance for soft shadows
@export var worldspawn_sun_penumbra: StringName = &"_sunlight_penumbra"
## Worldspawn property for enabling ambient occlusion
@export var worldspawn_ao_enabled: StringName = &"_dirt"
## Worldspawn property for enabling ambient occlusion
@export var worldspawn_ao_intensity: StringName = &"_dirtscale"
## Worldspawn property for enabling ambient occlusion
@export var worldspawn_ao_radius: StringName = &"_dirtgain"
@export_group("Worldspawn Properties Defaults")
## Default value of [member worldspawn_ambient_light]
@export var default_ambient_light: String = "0.2"
## Default value of [member worldspawn_ambient_color]
@export var default_ambient_color: String = "255 255 255"
## Default value of [member worldspawn_skyname]
@export var default_skyname: String = ""
## Default value of [member worldspawn_sunlight]
@export var default_sunlight: String = "0.0"
## Default value of [member worldspawn_sun_angle]
@export var default_sun_angle: String = "-90 0 0"
## Default value of [member worldspawn_sun_color]
@export var default_sun_color: String = "255 255 255"
## Default value of [member worldspawn_sun_shadows]
@export var default_sun_shadows: String = "0"
## Default value of [member worldspawn_sun_penumbra]
@export var default_sun_penumbra: String = "3.0"
## Default value of [member worldspawn_ao_enabled]
@export var default_ao_enabled: String = "0"
## Default value of [member worldspawn_ao_intensity]
@export var default_ao_intensity: String = "2"
## Default value of [member worldspawn_ao_radius]
@export var default_ao_radius: String = "1"

## Returns list of non-rendered texture patterns
func get_non_rendered_textures() -> PackedStringArray:
	var output: PackedStringArray
	for tag in smart_tags:
		if tag.match_type != QMapSmartTag.MatchType.MATERIAL: continue
		if tag.properties & QMapSmartTag.SmartProperties.NON_RENDERED:
			output.append(tag.pattern)
	return output

## Returns list of non-rendered classname patterns
func get_non_rendered_entities() -> PackedStringArray:
	var output: PackedStringArray
	for tag in smart_tags:
		if tag.match_type != QMapSmartTag.MatchType.CLASSNAME: continue
		if tag.properties & QMapSmartTag.SmartProperties.NON_RENDERED:
			output.append(tag.pattern)
	return output

## Returns list of non-rendered surface flag values
func get_non_rendered_surfaces() -> PackedInt32Array:
	var output: PackedInt32Array
	for tag in smart_tags:
		if tag.match_type != QMapSmartTag.MatchType.SURFACE_FLAG: continue
		if tag.properties & QMapSmartTag.SmartProperties.NON_RENDERED:
			output.append(find_content_flag(tag.pattern))
	return output

## Returns list of non-rendered content flag values
func get_non_rendered_content() -> PackedInt32Array:
	var output: PackedInt32Array
	for tag in smart_tags:
		if tag.match_type != QMapSmartTag.MatchType.CONTENT_FLAG: continue
		if tag.properties & QMapSmartTag.SmartProperties.NON_RENDERED:
			output.append(find_content_flag(tag.pattern))
	return output

## Returns list of non-occluding texture patterns
func get_non_occluding_textures() -> PackedStringArray:
	var output: PackedStringArray
	for tag in smart_tags:
		if tag.match_type != QMapSmartTag.MatchType.MATERIAL: continue
		if tag.properties & QMapSmartTag.SmartProperties.TRANSPARENT:
			output.append(tag.pattern)
	return output

## Returns list of non-occluding classname patterns
func get_non_occluding_entities() -> PackedStringArray:
	var output: PackedStringArray
	for tag in smart_tags:
		if tag.match_type != QMapSmartTag.MatchType.CLASSNAME: continue
		if tag.properties & QMapSmartTag.SmartProperties.TRANSPARENT:
			output.append(tag.pattern)
	return output

## Returns list of non-occluding surface flag values
func get_non_occluding_surfaces() -> PackedInt32Array:
	var output: PackedInt32Array
	for tag in smart_tags:
		if tag.match_type != QMapSmartTag.MatchType.SURFACE_FLAG: continue
		if tag.properties & QMapSmartTag.SmartProperties.TRANSPARENT:
			output.append(find_content_flag(tag.pattern))
	return output

## Returns list of non-occluding content flag values
func get_non_occluding_content() -> PackedInt32Array:
	var output: PackedInt32Array
	for tag in smart_tags:
		if tag.match_type != QMapSmartTag.MatchType.CONTENT_FLAG: continue
		if tag.properties & QMapSmartTag.SmartProperties.TRANSPARENT:
			output.append(find_content_flag(tag.pattern))
	return output

## Returns list of non-colliding texture patterns
func get_non_colliding_textures() -> PackedStringArray:
	var output: PackedStringArray
	for tag in smart_tags:
		if tag.match_type != QMapSmartTag.MatchType.MATERIAL: continue
		if tag.properties & QMapSmartTag.SmartProperties.NON_COLLIDING:
			output.append(tag.pattern)
	return output

## Returns list of non-colliding classname patterns
func get_non_colliding_entities() -> PackedStringArray:
	var output: PackedStringArray
	for tag in smart_tags:
		if tag.match_type != QMapSmartTag.MatchType.CLASSNAME: continue
		if tag.properties & QMapSmartTag.SmartProperties.NON_COLLIDING:
			output.append(tag.pattern)
	return output

## Returns list of non-colliding surface flag values
func get_non_colliding_surfaces() -> PackedInt32Array:
	var output: PackedInt32Array
	for tag in smart_tags:
		if tag.match_type != QMapSmartTag.MatchType.SURFACE_FLAG: continue
		if tag.properties & QMapSmartTag.SmartProperties.NON_COLLIDING:
			output.append(find_content_flag(tag.pattern))
	return output

## Returns list of non-colliding content flag values
func get_non_colliding_content() -> PackedInt32Array:
	var output: PackedInt32Array
	for tag in smart_tags:
		if tag.match_type != QMapSmartTag.MatchType.CONTENT_FLAG: continue
		if tag.properties & QMapSmartTag.SmartProperties.NON_COLLIDING:
			output.append(find_content_flag(tag.pattern))
	return output

## Returns list of non-pathfinding texture patterns
func get_non_pathfinding_textures() -> PackedStringArray:
	var output: PackedStringArray
	for tag in smart_tags:
		if tag.match_type != QMapSmartTag.MatchType.MATERIAL: continue
		if tag.properties & QMapSmartTag.SmartProperties.NON_PATHFINDING:
			output.append(tag.pattern)
	return output

## Returns list of non-pathfinding classname patterns
func get_non_pathfinding_entities() -> PackedStringArray:
	var output: PackedStringArray
	for tag in smart_tags:
		if tag.match_type != QMapSmartTag.MatchType.CLASSNAME: continue
		if tag.properties & QMapSmartTag.SmartProperties.NON_PATHFINDING:
			output.append(tag.pattern)
	return output

## Returns list of non-pathfinding surface flag values
func get_non_pathfinding_surfaces() -> PackedInt32Array:
	var output: PackedInt32Array
	for tag in smart_tags:
		if tag.match_type != QMapSmartTag.MatchType.SURFACE_FLAG: continue
		if tag.properties & QMapSmartTag.SmartProperties.NON_PATHFINDING:
			output.append(find_content_flag(tag.pattern))
	return output

## Returns list of non-pathfinding content flag values
func get_non_pathfinding_content() -> PackedInt32Array:
	var output: PackedInt32Array
	for tag in smart_tags:
		if tag.match_type != QMapSmartTag.MatchType.CONTENT_FLAG: continue
		if tag.properties & QMapSmartTag.SmartProperties.NON_PATHFINDING:
			output.append(find_content_flag(tag.pattern))
	return output

## Returns list of convex classname patterns
func get_convex_entities() -> PackedStringArray:
	var output: PackedStringArray
	for tag in smart_tags:
		if tag.match_type != QMapSmartTag.MatchType.CLASSNAME: continue
		if tag.properties & QMapSmartTag.SmartProperties.ENFORCE_CONVEX:
			output.append(tag.pattern)
	return output

## Returns matching content flag's value, or 0 if the flag doesn't exist
func find_content_flag(name: StringName) -> int:
	var bit: int = 1
	for flag in content_flags:
		if flag.name == name:
			return bit
		bit *= 2
	return 0

## Returns matching surface flag's value, or 0 if the flag doesn't exist
func find_surface_flag(name: StringName) -> int:
	var bit: int = 1
	for flag in surface_flags:
		if flag.name == name:
			return bit
		bit *= 2
	return 0

## Base paths (including mods)
func get_paths_base(mods := PackedStringArray([])) -> PackedStringArray:
	var output: PackedStringArray
	output.append("res://%s"%[base_path])
	for mod in mods:
		output.append("res://%s"%[mod])
	return output

## Wad paths (including mods)
func get_paths_wads(mods := PackedStringArray([])) -> PackedStringArray:
	return get_paths_textures(mods)

## Texture paths (including mods)
func get_paths_textures(mods := PackedStringArray([])) -> PackedStringArray:
	var output: PackedStringArray
	output.append("res://%s/%s"%[base_path, path_textures])
	for mod in mods:
		output.append("res://%s/%s"%[mod, path_textures])
	return output

## Decal  texture paths (including mods)
func get_paths_decals(mods := PackedStringArray([])) -> PackedStringArray:
	var output: PackedStringArray
	output.append("res://%s/%s"%[base_path, path_decals])
	for mod in mods:
		output.append("res://%s/%s"%[mod, path_decals])
	return output

## Material paths (including mods)
func get_paths_materials(mods := PackedStringArray([])) -> PackedStringArray:
	var output: PackedStringArray
	output.append("res://%s/%s"%[base_path, path_materials])
	for mod in mods:
		output.append("res://%s/%s"%[mod, path_materials])
	return output

## Sound paths (including mods)
func get_paths_sounds(mods := PackedStringArray([])) -> PackedStringArray:
	var output: PackedStringArray
	output.append("res://%s/%s"%[base_path, path_sounds])
	for mod in mods:
		output.append("res://%s/%s"%[mod, path_sounds])
	return output

## Model paths (including mods)
func get_paths_models(mods := PackedStringArray([])) -> PackedStringArray:
	var output: PackedStringArray
	output.append("res://%s/%s"%[base_path, path_models])
	for mod in mods:
		output.append("res://%s/%s"%[mod, path_models])
	return output


## Scene paths (including mods)
func get_paths_scenes(mods := PackedStringArray([])) -> PackedStringArray:
	var output: PackedStringArray
	output.append("res://%s/%s"%[base_path, path_scenes])
	for mod in mods:
		output.append("res://%s/%s"%[mod, path_scenes])
	return output

var _scale_factor: float:
	get: return 1.0/float(scaling)
