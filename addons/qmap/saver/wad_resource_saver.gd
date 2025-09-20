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
	return ERR_UNAVAILABLE
	if !(resource is WAD): return ERR_INVALID_DATA
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null: return ERR_CANT_OPEN
	var wad := resource as WAD
	var data: PackedByteArray
	# Write header
	if wad.format == WAD3: data.append_array("WAD3".to_ascii_buffer())
	elif wad.format == WAD2: data.append_array("WAD3".to_ascii_buffer())
	data.resize(12)
	data.encode_u32(4, wad.dir_entries.size())
	data.encode_u32(8, wad.dir_offset)
	data.resize(wad.dir_offset + wad.dir_entries.size() * DIR_ENTRY_SIZE)
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
	# Write entries
	for entry in wad.dir_entries:
		pass
		# Write entry data
		
	file.store_buffer(data)
	file.close()
	return OK
