@tool
class_name WADResourceSaver extends ResourceFormatSaver

const DEFAULT_PALETTE: QPalette = preload("res://addons/qmap/default_resources/palette.lmp")
const WAD2 := WAD.WadFormat.WAD2
const WAD3 := WAD.WadFormat.WAD3
const WAD3_TRANSPARENT_COLOR := Color8(0, 0, 255)
const DIR_ENTRY_SIZE := 32

func _get_recognized_extensions(resource: Resource) -> PackedStringArray:
	return ["wad", "WAD"]

func _recognize(resource: Resource) -> bool:
	return resource is WAD

func _save(resource: Resource, path: String, flags: int) -> Error:
	printerr("Cannot save '%s': WAD changes saving not currently supported in editor"%path)
	return ERR_UNAVAILABLE
	if !(resource is WAD): return ERR_INVALID_DATA
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null: return ERR_CANT_OPEN
	var wad := resource as WAD
	var data: PackedByteArray
	# Write magic bytes
	if wad.format == WAD3: data.append_array("WAD3".to_ascii_buffer())
	elif wad.format == WAD2: data.append_array("WAD3".to_ascii_buffer())
	# Generate new dirs / erase unused dirs
	
	# Initialize default palette
	var current_palette: QPalette
	if wad.format == WAD2: 
		current_palette = DEFAULT_PALETTE
		if current_palette == null:
			current_palette = QPalette.new_empty(256)
		elif current_palette.colors.size() < 256:
			current_palette = current_palette.duplicate()
			while current_palette.colors.size() < 256:
				current_palette.colors.append(WAD3_TRANSPARENT_COLOR)
	elif wad.format == WAD3: current_palette = QPalette.new()
	# WAD2: Format palettes and assign main palette
	for key in wad.palettes.keys():
		if wad.palettes[key].colors.size() != 256:
			wad.palettes[key] = wad.palettes[key].duplicate()
			if wad.palettes[key].colors.size() > 256:
				wad.palettes[key].colors.resize(256)
			else: while wad.palettes[key].colors.size() < 256:
				wad.palettes[key].colors.append(WAD3_TRANSPARENT_COLOR)
	if wad.format == WAD2:
		if wad.palettes.has(&"PALETTE"):
			current_palette = wad.palettes[&"PALETTE"]
		elif wad.palettes.size() > 0:
			current_palette = wad.palettes[wad.palettes.keys()[0]]
	# Check sizing on textures / generate mipmaps if needed
	# Texture dimensions must be divisible by 16
	
	# Generate raw data if needed
	for key in wad.textures.keys():
		pass
	# Determine file size
	var dir_size: int = wad.dir_entries.size() * DIR_ENTRY_SIZE
	var entries_size: int
	for mipmaps in wad.mipmap_data.values():
		for mipmap in mipmaps: entries_size += mipmap.size()
	var dir_offset: int = 12 + entries_size
	wad.dir_offset = dir_offset
	data.resize(12 + dir_size + entries_size)
	# Write header
	data.encode_u32(4, wad.dir_entries.size())
	data.encode_u32(8, wad.dir_offset)
	# Write entries
	var d_offset: int = dir_offset
	var e_offset: int
	for entry in wad.dir_entries:
		pass
		# Write entry data
		
	file.store_buffer(data)
	file.close()
	return OK
