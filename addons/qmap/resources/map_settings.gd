@tool
class_name QMapSettings extends Resource

## [FGD] to initialize entities with
@export var fgd: FGD = preload("res://addons/qmap/default_resources/base.fgd")
@export_group("Scaling")
## QUnit to Godot scaling ratio
@export_range(1, 256, 1) var scaling: int = 32
## Ratio for UV unwrapping
@export_range(1, 256, 1) var uv_unwrap_texel_ratio: int = 16
## Default UV scaling
@export var default_uv_scale := Vector2.ONE
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
@export var texture_extensions: PackedStringArray = ["png", "jpg", "jpeg", "bmp", "tga", "exr", "webp"]
## Valid material extensions to load from
@export var material_extensions: PackedStringArray = ["tres"]
@export_group("Resource Paths")
## Base path relative to res:// for loading resources
@export var base_path: StringName = &"."
## Path relative to [base_path] to load textures and Wads
@export var path_textures: StringName = &"textures"
## Path relative to [base_path] to load skyboxes
@export var path_skies: StringName = &"sky"
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
## Path to default palette relative to [member base_path]
@export var path_palette: StringName = &"palette.lmp"
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
## Worldspawn property for enabling fog
@export var worlspawn_fog_enabled: StringName = &"_fog_enabled"
## Worldspawn property for setting fog density
@export var worlspawn_fog_density: StringName = &"_fog_density"
## Worldspawn property for setting fog height
@export var worlspawn_fog_height: StringName = &"_fog_height"
## Worldspawn property for setting fog height density
@export var worlspawn_fog_height_density: StringName = &"_fog_height_density"
## Worldspawn property for setting fog light color
@export var worlspawn_fog_color: StringName = &"_fog_color"
## Worldspawn property for setting fog light level
@export var worlspawn_fog_light: StringName = &"_fog_light"
## Worldspawn property for setting fog sky affect
@export var worlspawn_fog_sky_affect: StringName = &"_fog_sky_affect"
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
## Default value of [member worlspawn_fog_enabled]
@export var default_fog_enabled: String = "0"
## Default value of [member worlspawn_fog_density]
@export var default_fog_density: String = "0.01"
## Default value of [member worlspawn_fog_height]
@export var default_fog_height: String = "0"
## Default value of [member worlspawn_fog_height_density]
@export var default_fog_height_density: String = "0"
## Default value of [member worlspawn_fog_color]
@export var default_fog_color: String = "132 141 155"
## Default value of [member worlspawn_fog_light]
@export var default_fog_light: String = "1"
## Default value of [member worlspawn_fog_sky_affect]
@export var default_fog_sky_affect: String = "0.1"
@export_group("General Entity Properties")
## Entity property for controlling render transparency
@export var entity_property_transparency: StringName = &"_render_transparency"
## Entity property for controlling render shadow_casting
@export var entity_property_shadow_casting: StringName = &"_render_shadows"
## Entity property for controlling visibility start distance
@export var entity_property_visibility_begin: StringName = &"_render_range_begin"
## Entity property for controlling visibility start margin for fading
@export var entity_property_visibility_begin_margin: StringName = &"_render_range_begin_margin"
## Entity property for controlling visibility end distance
@export var entity_property_visibility_end: StringName = &"_render_range_end"
## Entity property for controlling visibility end margin for fading
@export var entity_property_visibility_end_margin: StringName = &"_render_range_end_margin"
## Entity property for controlling visibility fade mode
@export var entity_property_visibility_fade_mode: StringName = &"_render_fade_mode"
## Entity property for controlling render layer
@export var entity_property_render_layer: StringName = &"_render_layer"
## Entity property for controlling collision layer
@export var entity_property_collision_layer: StringName = &"_physics_layer"
## Entity property for controlling collision mask
@export var entity_property_collision_mask: StringName = &"_physics_mask"
## Entity property for controlling constant linear velocity
@export var entity_property_linear_velocity: StringName = &"_physics_linear_velocity"
## Entity property for controlling constant angular velocity
@export var entity_property_angular_velocity: StringName = &"_physics_angular_velocity"
@export_group("General Entity Property Defaults")
## Default value of [member entity_property_transparency]
@export var default_entity_transparency: String = "0.0"
## Default value of [member entity_property_shadow_casting]
@export var default_entity_shadow_casting: String = "1"
## Default value of [member entity_property_visibility_begin]
@export var default_entity_visibility_begin: String = "0.0"
## Default value of [member entity_property_visibility_begin_margin]
@export var default_entity_visibility_begin_margin: String = "0.0"
## Default value of [member entity_property_visibility_end]
@export var default_entity_visibility_end: String = "0.0"
## Default value of [member entity_property_visibility_end_margin]
@export var default_entity_visibility_end_margin: String = "0.0"
## Default value of [member entity_property_visibility_fade_mode]
@export var default_entity_visibility_fade_mode: String = "0"
## Default value of [member entity_property_render_layer]
@export var default_entity_render_layer: String = "1"
## Default value of [member entity_property_collision_layer]
@export var default_entity_collision_layer: String = "1"
## Default value of [member entity_property_collision_mask]
@export var default_entity_collision_mask: String = "1"
## Default value of [member entity_property_linear_velocity]
@export var default_entity_linear_velocity: String = "0 0 0"
## Default value of [member entity_property_angular_velocity]
@export var default_entity_angular_velocity: String = "0 0 0"
@export_group("Pathfinding")
## If true, will generate pathfinding for solid entities
@export var generate_pathfinding: bool = true
## Default [NavigationMesh] used by Navigation regions
##
## NOTE: Will NOT work if [member NavigationMesh.geometry_parsed_geometry_type]
## is set to Mesh Instance
@export var default_nav_mesh: NavigationMesh
## Property for adjusting nav region enter cost
@export var property_nav_enter_cost: StringName = &"_enter_cost"
## Property for adjusting nav region travel cost
@export var property_nav_travel_cost: StringName = &"_travel_cost"
@export_group("Trenchbroom")
## Exports current configuration to Trenchbroom
@export_tool_button("Export Trenchbroom Config", "Callable") var _trenchbroom_export := _export_to_trenchbroom

## Exports current configuration to Trenchbroom (Editor Only)
func _export_to_trenchbroom() -> void:
	var local_settings: Object = Engine.get_singleton("EditorInterface").call("get_editor_settings")
	var games_dir: String = local_settings.get_setting("qmap/trenchbroom/games_config_dir")
	var game_name: String = ProjectSettings.get_setting("application/config/name", "")
	var icon_path: String = ProjectSettings.get_setting("application/config/icon", "")
	var config_path := "%s/%s"%[games_dir, game_name.validate_filename().replace(" ", "")]
	# Validate data
	if games_dir.is_empty() || !games_dir.is_absolute_path():
		printerr("Cannot export trenchbroom config: must provide valid path in project settings 'qmap/trenchbroom/games_config_dir'")
		return
	if fgd == null:
		printerr("Cannot export trenchbroom config: Must set FGD")
		return
	if game_name.is_empty():
		printerr("Cannot export trenchbroom config: must set application name in project settings 'application/config/name'")
		return
	# Create directory if needed
	if !DirAccess.dir_exists_absolute(config_path):
		print("Creating new trenchbroom config...")
		if DirAccess.make_dir_recursive_absolute(config_path) != OK:
			printerr("Cannot export trenchbroom config: Error creating config directory")
			return
	else: print("Updating trenchbroom config...")
	# Export icon
	if ResourceLoader.exists(icon_path):
		var icon_texture: Texture2D = ResourceLoader.load(icon_path)
		var icon := icon_texture.get_image()
		icon.resize(32, 32, Image.INTERPOLATE_LANCZOS)
		icon.save_png("%s/icon.png"%config_path)
	# Export fgd
	var fgd_filename: String = "%s.fgd"%fgd.resource_path.get_file().get_basename()
	if FGDResourceSaver.new()._save(fgd, "%s/%s"%[config_path, fgd_filename], 0) != OK:
		printerr("Cannot export trenchbroom config: Error writing FGD to config directory")
		return
	# Export @include fgds
	for path in fgd.get_base_fgd_paths():
		var base_fgd: FGD = ResourceLoader.load(path)
		if base_fgd == null:
			printerr("Issue exporting trenchbroom config: Missing @include FGD to save to config directory")
			continue
		var base_filename: String = "%s.fgd"%base_fgd.resource_path.get_file().get_basename()
		if FGDResourceSaver.new()._save(base_fgd, "%s/%s"%[config_path, base_filename], 0) != OK:
			printerr("Issue exporting trenchbroom config: Error writing @include FGD to config directory")
			continue
	# Export cfg
	var file := FileAccess.open("%s/GameConfig.cfg"%[config_path], FileAccess.WRITE)
	if file == null:
		printerr("Cannot export trenchbroom config: Error writing config (%s)"%error_string(FileAccess.get_open_error()))
		return
	var version: int = local_settings.get_setting("qmap/trenchbroom/config_version")
	if version == 0: version = 9
	var included_textures: String = ""
	for extension in texture_extensions:
		included_textures += '".%s", '%extension
	included_textures += '".D", ".C"'
	var exclude_textures: String = ""
	if use_pbr:
		exclude_textures += '"excludes": [ '
		exclude_textures += '"*%s", '%suffix_normal
		exclude_textures += '"*%s", '%suffix_metallic
		exclude_textures += '"*%s", '%suffix_roughness
		exclude_textures += '"*%s", '%suffix_emission
		exclude_textures += '"*%s", '%suffix_ao
		exclude_textures += '"*%s", '%suffix_height
		exclude_textures += '"*%s"'%suffix_normal
		exclude_textures += ' ],'
	var palette_str: String = ""
	if !path_palette.is_empty():
		palette_str = '"palette": "%s",'%path_palette
	var uv_scale_str: String = '"scale": [%s, %s]'%[default_uv_scale.x, default_uv_scale.y]
	var brush_tags: String
	var brush_face_tags: String
	for tag in smart_tags:
		var tag_str: String = "{\n"
		tag_str += '\t\t\t\t"name": "%s",\n'%tag.name
		if tag.properties & QMapSmartTag.SmartProperties.TRANSPARENT:
			tag_str += '\t\t\t\t"attribs": [ "transparent" ],\n'
		else:
			tag_str += '\t\t\t\t"attribs": [ ],\n'
		match tag.match_type:
			QMapSmartTag.MatchType.MATERIAL:
				tag_str += '\t\t\t\t"match": "material",\n'
			QMapSmartTag.MatchType.CONTENT_FLAG:
				tag_str += '\t\t\t\t"match": "contentflag",\n'
			QMapSmartTag.MatchType.SURFACE_FLAG:
				tag_str += '\t\t\t\t"match": "surfaceparm",\n'
			QMapSmartTag.MatchType.CLASSNAME:
				tag_str += '\t\t\t\t"match": "classname",\n'
		if tag.match_type == QMapSmartTag.MatchType.CONTENT_FLAG:
			tag_str += '\t\t\t\t"flags": "%s",\n'%tag.pattern
		else:
			tag_str += '\t\t\t\t"pattern": "%s",\n'%tag.pattern
		if !tag.default_texture.is_empty():
			tag_str += '\t\t\t\t"material": "%s",\n'%tag.default_texture
		tag_str = tag_str.trim_suffix(",\n")
		tag_str += "\n\t\t\t}"
		if tag.match_type == QMapSmartTag.MatchType.CLASSNAME:
			if brush_tags.is_empty(): brush_tags += tag_str
			else: brush_tags += ",\n\t\t\t%s"%tag_str
		else:
			if brush_face_tags.is_empty(): brush_face_tags += tag_str
			else: brush_face_tags += ",\n\t\t\t%s"%tag_str
	var content_flags_str: String
	var surface_flags_str: String
	var bit := 1
	for flag in content_flags:
		if flag == null || flag.name.is_empty():
			if !content_flags_str.is_empty(): content_flags_str += ", // %s\n\t\t\t"%(bit/2)
			content_flags_str += '{ "unused": true }'
		else:
			if !content_flags_str.is_empty(): content_flags_str += ", // %s\n\t\t\t"%(bit/2)
			content_flags_str += '{\n\t\t\t\t"name": "%s",\n\t\t\t\t"description": "%s - %s"\n\t\t\t}'%[flag.name, bit, flag.description]
		bit *= 2
	if !content_flags_str.is_empty(): content_flags_str +=  " // %s"%(bit/2)
	bit = 1
	for flag in surface_flags:
		if flag == null || flag.name.is_empty():
			if !surface_flags_str.is_empty(): surface_flags_str += ", // %s\n\t\t\t"%(bit/2)
			surface_flags_str += '{ "unused": true }'
		else:
			if !surface_flags_str.is_empty(): surface_flags_str += ", // %s\n\t\t\t"%(bit/2)
			surface_flags_str += '{\n\t\t\t\t"name": "%s",\n\t\t\t\t"description": "%s - %s"\n\t\t\t}'%[flag.name, bit, flag.description]
		bit *= 2
	if !surface_flags_str.is_empty(): surface_flags_str +=  " // %s"%(bit/2)
	var soft_bounds_str := "%s %s %s %s %s %s"%[
		soft_map_bounds.position.x,
		soft_map_bounds.position.y,
		soft_map_bounds.position.z,
		soft_map_bounds.size.x,
		soft_map_bounds.size.y,
		soft_map_bounds.size.z,
	]
	match version:
		8,9:
			file.store_string("""{
	"version": %s,
	"name": "%s",
	"icon": "icon.png",
	"fileformats": [
		{ "format": "Valve" },
		{ "format": "Standard" },
		{ "format": "Quake2" },
		{ "format": "Quake2 (Valve)" },
		{ "format": "Quake3" },
		{ "format": "Quake3 (Valve)" },
		{ "format": "Quake3 (legacy)" }
	],
	"filesystem": {
		"searchpath": "%s",
		"packageformat": { "extension": ".zip", "format": "zip" }
	},
	"materials": {
		"root": "%s",
		"extensions": [%s],
		%s
		%s
		"attribute": "wad"
	},
	"entities": {
		"definitions": [ "%s" ],
		"defaultcolor": "1.0 0.0 1.0 1.0",
		"scale": %s
	},
	"tags": {
		"brush": [
			%s
		],
		"brushface": [
			%s
		]
	},
	"faceattribs": { 
		"defaults": {
			%s
		},
		"contentflags": [
			%s
		],
		"surfaceflags": [
			%s
		]
	},
	"softMapBounds":"%s"
}
"""%[
				version,
				game_name,
				base_path,
				path_textures,
				included_textures,
				exclude_textures,
				palette_str,
				fgd_filename,
				scaling,
				brush_tags,
				brush_face_tags,
				uv_scale_str,
				content_flags_str,
				surface_flags_str,
				soft_bounds_str
			])
		4:
			file.store_string("""{
	"version": 4,
	"name": "%s",
	"icon": "icon.png",
	"fileformats": [
		{ "format": "Valve" },
		{ "format": "Standard" },
		{ "format": "Quake2" },
		{ "format": "Quake2 (Valve)" },
		{ "format": "Quake3" },
		{ "format": "Quake3 (Valve)" },
		{ "format": "Quake3 (legacy)" }
	],
	"filesystem": {
		"searchpath": "%s",
		"packageformat": { "extension": ".zip", "format": "zip" }
	},
	"textures": {
		"package": { "type": "directory", "root": "%s" },
		"format": { "extensions": [%s], "format": "image" },
		%s
		%s
		"attribute": ["_tb_textures", "wad"]
	},
	"entities": {
		"definitions": [ "%s" ],
		"defaultcolor": "1.0 0.0 1.0 1.0",
		"modelformats": [ "bsp, mdl, md2" ],
		"scale": %s
	},
	"tags": {
		"brush": [
			%s
		],
		"brushface": [
			%s
		]
	},
	"faceattribs": { 
		"defaults": {
			%s
		},
		"contentflags": [
			%s
		],
		"surfaceflags": [
			%s
		]
	},
	"softMapBounds":"%s"
}
"""%[
				game_name,
				base_path,
				path_textures,
				included_textures.replace(".",""),
				exclude_textures,
				palette_str,
				fgd_filename,
				scaling,
				brush_tags,
				brush_face_tags,
				uv_scale_str,
				content_flags_str,
				surface_flags_str,
				soft_bounds_str
			])
		_:
			printerr("Cannot export trenchbroom config: Unsupported config version")
	file.close()
	print("Successfully exported config to: %s"%config_path)

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
			output.append(find_surface_flag(tag.pattern))
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
			output.append(find_surface_flag(tag.pattern))
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
			output.append(find_surface_flag(tag.pattern))
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
			output.append(find_surface_flag(tag.pattern))
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

## Returns matching content flag's value, or 0 if the flag doesn't exist. If is int, just return that int
func find_content_flag(name: StringName) -> int:
	if name.is_valid_int(): return name.to_int()
	var bit: int = 1
	for flag in content_flags:
		if flag.name == name:
			return bit
		bit *= 2
	return 0

## Returns matching surface flag's value, or 0 if the flag doesn't exist. If is int, just return that int
func find_surface_flag(name: StringName) -> int:
	if name.is_valid_int(): return name.to_int()
	var bit: int = 1
	for flag in surface_flags:
		if flag.name == name:
			return bit
		bit *= 2
	return 0

## Base paths (including mods)
func get_paths_base(mods := PackedStringArray([])) -> PackedStringArray:
	var output: PackedStringArray
	for mod in mods:
		output.append("res://%s"%[mod])
	output.append("res://%s"%[base_path])
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

## Sky paths (including mods)
func get_paths_skies(mods := PackedStringArray([])) -> PackedStringArray:
	var output: PackedStringArray
	output.append("res://%s/%s"%[base_path, path_skies])
	for mod in mods:
		output.append("res://%s/%s"%[mod, path_skies])
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
