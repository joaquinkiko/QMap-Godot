@tool
extends EditorPlugin

var fgd_loader: ResourceFormatLoader
var fgd_saver: ResourceFormatSaver
var wad_loader: ResourceFormatLoader
var wad_saver: ResourceFormatSaver
var qmap_loader: ResourceFormatLoader
var qmap_saver: ResourceFormatSaver
var lmp_loader: ResourceFormatLoader
var lmp_saver: ResourceFormatSaver

func _enter_tree() -> void:
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

func _exit_tree() -> void:
	ResourceLoader.remove_resource_format_loader(fgd_loader)
	ResourceSaver.remove_resource_format_saver(fgd_saver)
	ResourceLoader.remove_resource_format_loader(wad_loader)
	ResourceSaver.remove_resource_format_saver(wad_saver)
	ResourceLoader.remove_resource_format_loader(qmap_loader)
	ResourceSaver.remove_resource_format_saver(qmap_saver)
	ResourceLoader.remove_resource_format_loader(lmp_loader)
	ResourceSaver.remove_resource_format_saver(lmp_saver)
