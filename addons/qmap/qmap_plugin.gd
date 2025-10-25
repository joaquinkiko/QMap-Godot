@tool
extends EditorPlugin

const PROP_TRENCHBROOM_DIR := &"qmap/trenchbroom/games_config_dir"
const PROP_TRENCHBROOM_VERSION := &"qmap/trenchbroom/config_version"

var fgd_loader: ResourceFormatLoader
var fgd_saver: ResourceFormatSaver
var wad_loader: ResourceFormatLoader
var wad_saver: ResourceFormatSaver
var qmap_loader: ResourceFormatLoader
var qmap_saver: ResourceFormatSaver
var lmp_loader: ResourceFormatLoader
var lmp_saver: ResourceFormatSaver

var local_settings: EditorSettings

func _enter_tree() -> void:
	local_settings = EditorInterface.get_editor_settings()
	fgd_loader = FGDResourceLoader.new()
	fgd_saver = FGDResourceSaver.new()
	wad_loader = WADResourceLoader.new()
	wad_saver = WADResourceSaver.new()
	qmap_loader = QMapResourceLoader.new()
	qmap_saver = QMapResourceSaver.new()
	lmp_loader = QPaletteResourceLoader.new()
	lmp_saver = QPaletteResourceSaver.new()
	ResourceLoader.add_resource_format_loader(fgd_loader)
	ResourceSaver.add_resource_format_saver(fgd_saver)
	ResourceLoader.add_resource_format_loader(wad_loader)
	ResourceSaver.add_resource_format_saver(wad_saver)
	ResourceLoader.add_resource_format_loader(qmap_loader)
	ResourceSaver.add_resource_format_saver(qmap_saver)
	ResourceLoader.add_resource_format_loader(lmp_loader)
	ResourceSaver.add_resource_format_saver(lmp_saver)
	local_settings.set_setting(PROP_TRENCHBROOM_DIR, "")
	local_settings.set_initial_value(PROP_TRENCHBROOM_DIR, "", false)
	local_settings.add_property_info({
		"name": PROP_TRENCHBROOM_DIR,
		"type": TYPE_STRING,
		"hint": PROPERTY_HINT_GLOBAL_DIR,
		"hint_string": "Path to Trenchbroom games directory"
	})
	local_settings.set_setting(PROP_TRENCHBROOM_VERSION, 0)
	local_settings.set_initial_value(PROP_TRENCHBROOM_VERSION, 0, false)
	local_settings.add_property_info({
		"name": PROP_TRENCHBROOM_VERSION,
		"type": TYPE_INT,
		"hint": PROPERTY_HINT_ENUM,
		"hint_string": "Latest:0,Version 4:4,Version 8:8,Version 9:9"
	})

func _exit_tree() -> void:
	ResourceLoader.remove_resource_format_loader(fgd_loader)
	ResourceSaver.remove_resource_format_saver(fgd_saver)
	ResourceLoader.remove_resource_format_loader(wad_loader)
	ResourceSaver.remove_resource_format_saver(wad_saver)
	ResourceLoader.remove_resource_format_loader(qmap_loader)
	ResourceSaver.remove_resource_format_saver(qmap_saver)
	ResourceLoader.remove_resource_format_loader(lmp_loader)
	ResourceSaver.remove_resource_format_saver(lmp_saver)
	if local_settings.get_setting(PROP_TRENCHBROOM_DIR) == "": local_settings.erase(PROP_TRENCHBROOM_DIR)
	if local_settings.get_setting(PROP_TRENCHBROOM_VERSION) == 0: local_settings.erase(PROP_TRENCHBROOM_VERSION)
