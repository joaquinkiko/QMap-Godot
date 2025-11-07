@tool
extends EditorPlugin

const PROP_AUTOSAVE_DIR := &"qmap/ignore_map_autosave_dir"
const PROP_TRENCHBROOM_DIR := &"qmap/trenchbroom/games_config_dir"
const PROP_TRENCHBROOM_VERSION := &"qmap/trenchbroom/config_version"

var fgd_loader := FGDResourceLoader.new()
var fgd_saver := FGDResourceSaver.new()
var wad_loader := WADResourceLoader.new()
var wad_saver := WADResourceSaver.new()
var qmap_loader := QMapResourceLoader.new()
var qmap_saver := QMapResourceSaver.new()
var lmp_loader := QPaletteResourceLoader.new()
var lmp_saver := QPaletteResourceSaver.new()

var local_settings := EditorInterface.get_editor_settings()

func _enter_tree() -> void:
	ResourceLoader.add_resource_format_loader(fgd_loader)
	ResourceSaver.add_resource_format_saver(fgd_saver)
	ResourceLoader.add_resource_format_loader(wad_loader)
	ResourceSaver.add_resource_format_saver(wad_saver)
	ResourceLoader.add_resource_format_loader(qmap_loader)
	ResourceSaver.add_resource_format_saver(qmap_saver)
	ResourceLoader.add_resource_format_loader(lmp_loader)
	ResourceSaver.add_resource_format_saver(lmp_saver)

func _exit_tree() -> void:
	ResourceLoader.remove_resource_format_loader(fgd_loader)
	ResourceSaver.remove_resource_format_saver(fgd_saver)
	ResourceLoader.remove_resource_format_loader(wad_loader)
	ResourceSaver.remove_resource_format_saver(wad_saver)
	ResourceLoader.remove_resource_format_loader(qmap_loader)
	ResourceSaver.remove_resource_format_saver(qmap_saver)
	ResourceLoader.remove_resource_format_loader(lmp_loader)
	ResourceSaver.remove_resource_format_saver(lmp_saver)

func _enable_plugin() -> void:
	if !local_settings.has_setting(PROP_AUTOSAVE_DIR):
		local_settings.set_setting(PROP_AUTOSAVE_DIR, true)
	local_settings.set_initial_value(PROP_AUTOSAVE_DIR, true, false)
	local_settings.add_property_info({
		"name": PROP_AUTOSAVE_DIR,
		"type": TYPE_BOOL,
		"hint": PROPERTY_HINT_NONE,
		"hint_string": "When enabled will generate .gdignore in 'autosave' directory relative to map files"
	})
	if !local_settings.has_setting(PROP_TRENCHBROOM_DIR):
		local_settings.set_setting(PROP_TRENCHBROOM_DIR, "")
	local_settings.set_initial_value(PROP_TRENCHBROOM_DIR, "", false)
	local_settings.add_property_info({
		"name": PROP_TRENCHBROOM_DIR,
		"type": TYPE_STRING,
		"hint": PROPERTY_HINT_GLOBAL_DIR,
		"hint_string": "Path to Trenchbroom games directory"
	})
	if !local_settings.has_setting(PROP_TRENCHBROOM_VERSION):
		local_settings.set_setting(PROP_TRENCHBROOM_VERSION, 0)
	local_settings.set_initial_value(PROP_TRENCHBROOM_VERSION, 0, false)
	local_settings.add_property_info({
		"name": PROP_TRENCHBROOM_VERSION,
		"type": TYPE_INT,
		"hint": PROPERTY_HINT_ENUM,
		"hint_string": "Latest:0,Version 4:4,Version 8:8,Version 9:9"
	})

func _disable_plugin() -> void:
	local_settings.erase(PROP_AUTOSAVE_DIR)
	local_settings.erase(PROP_TRENCHBROOM_DIR)
	local_settings.erase(PROP_TRENCHBROOM_VERSION)
