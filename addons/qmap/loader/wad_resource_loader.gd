@tool
class_name WADResourceLoader extends ResourceFormatLoader

const DEFAULT_PALETTE: QPalette =  preload("res://addons/qmap/default_resources/palette.lmp")
const USE_WAD_MIPMAPS := false # Not working for I'll be damned if I know why
const WAD2_TRANSPARENT_INDEX := 255
const WAD3_TRANSPARENT_COLOR := Color8(0, 0, 255)
const WAD2 := WAD.WadFormat.WAD2
const WAD3 := WAD.WadFormat.WAD3

enum WAD2EntryType {
	COLOR_PALETTE = 0x40,
	STATUS_BAR_PICTURE = 0x42,
	MIP_TEXTURE = 0x44,
	CONSOLE_PICTURE = 0x45,
}
enum WAD3EntryType {
	Q_PIC = 0x42,
	MIP_TEXTURE = 0x43,
	FIXED_FONT = 0x45,
}

func _get_recognized_extensions() -> PackedStringArray:
	return ["wad", "WAD"]

func _handles_type(type: StringName) -> bool:
	return ClassDB.is_parent_class(type, "Resource")

func _get_resource_type(path: String) -> String:
	if path.get_extension().to_lower() == "wad": return "Resource"
	else: return ""

func _load(path: String, original_path: String, use_sub_threads: bool, cache_mode: int) -> Variant:
	var resource := WAD.new()
	var data = FileAccess.get_file_as_bytes(path)
	if data.size() < 12: 
		printerr("Error loading data from '%s'"%path)
		return resource
	# Get WAD type from magic bytes
	match data.slice(0, 4).get_string_from_ascii():
		"WAD2": resource.format = WAD2
		"WAD3": resource.format = WAD3
		_:
			printerr("Cannot load '%s': is not WAD2 or WAD3 format"%path)
			return resource
	var palette: QPalette = DEFAULT_PALETTE
	if resource.format == WAD2:
		if palette == null:
			palette = QPalette.new()
			palette.colors.resize(256)
			for n in palette.colors.size():
				palette.colors[n] = WAD3_TRANSPARENT_COLOR
		elif palette.colors.size() < 256:
			palette = palette.duplicate()
			while palette.colors.size() < 256:
				palette.colors.append(WAD3_TRANSPARENT_COLOR)
	# Get rest of header data
	var entry_count: int = data.decode_u32(4)
	var dir_offset: int = data.decode_u32(8)
	if data.size() < dir_offset: return resource
	var entries: Array[Dictionary]
	# Parse directories
	for n in entry_count:
		var entry: Dictionary[StringName, Variant]
		entry[&"offset"] = data.decode_u32(dir_offset)
		entry[&"data_size"] = data.decode_u32(dir_offset + 4)
		entry[&"size"] = data.decode_u32(dir_offset + 8)
		entry[&"type"] = data.decode_u8(dir_offset + 12)
		entry[&"compression"] = data.decode_u8(dir_offset + 13)
		entry[&"dummy"] = data.decode_u16(dir_offset + 14)
		entry[&"name"] = data.slice(dir_offset + 16, dir_offset + 32).get_string_from_ascii()
		entries.append(entry)
		dir_offset += 32
	# Parse entries
	for entry in entries:
		# Miptex parsing: https://developer.valvesoftware.com/wiki/Miptex
		if resource.format == WAD2 && entry[&"type"] == WAD2EntryType.MIP_TEXTURE ||\
		resource.format == WAD3 && entry[&"type"] == WAD3EntryType.MIP_TEXTURE:
			var name := data.slice(entry[&"offset"], entry[&"offset"] + 16).get_string_from_ascii()
			var dimensions := Vector2i(
				data.decode_u32(entry[&"offset"] + 16),
				data.decode_u32(entry[&"offset"] + 20)
			)
			var mip_offsets := PackedInt32Array([])
			for n in 4: mip_offsets.append(data.decode_u32(entry[&"offset"] + 24 + 4*n))
			var mip_map_data: Array[PackedByteArray]
			var mip_map_level: int = 1
			if USE_WAD_MIPMAPS: mip_map_data.resize(4)
			else: mip_map_data.resize(1)
			for n in mip_map_data.size():
				mip_map_data[n] = data.slice(
					entry[&"offset"] + mip_offsets[n],
					entry[&"offset"] + mip_offsets[n] + (dimensions.x/mip_map_level) * (dimensions.y/mip_map_level)
					)
				mip_map_level *= 2
			# For WAD3 grab palette after last mipmap
			if resource.format == WAD3:
				var palette_offset: int = entry[&"offset"] + mip_offsets[3] + dimensions.x/8 + dimensions.y/8
				palette = QPalette.new()
				palette.colors.resize(data.decode_s16(palette_offset))
				for n in palette.colors.size():
					palette.colors[n] = Color8(
						data.decode_u8(palette_offset + n*3 + 2),
						data.decode_u8(palette_offset + n*3 + 3),
						data.decode_u8(palette_offset + n*3 + 4)
					)
			# Construct texture & mipmaps
			var image: Image
			var texture_data: PackedByteArray
			for mip_level in mip_map_data.size():
				for n in mip_map_data[mip_level]:
					texture_data.append_array([
						palette.colors[n].r8,
						palette.colors[n].g8,
						palette.colors[n].b8
					])
					if resource.format == WAD2:
						if n == WAD2_TRANSPARENT_INDEX: texture_data.append(0)
						else: texture_data.append(255)
					elif resource.format == WAD3: 
						if palette.colors[n] == WAD3_TRANSPARENT_COLOR: texture_data.append(0)
						else:  texture_data.append(255)
			image = Image.create_from_data(dimensions.x, dimensions.y, USE_WAD_MIPMAPS, Image.FORMAT_RGBA8, texture_data)
			if !USE_WAD_MIPMAPS: image.generate_mipmaps()
			resource.textures[name] = ImageTexture.create_from_image(image)
		# Parse palette
		elif resource.format == WAD2 && entry[&"type"] == WAD2EntryType.COLOR_PALETTE:
			var wad_palette := QPalette.new()
			wad_palette.colors.resize(256)
			for n in 256:
				wad_palette.colors[n] = Color8(
					data.decode_u8(entry[&"offset"] + n*3),
					data.decode_u8(entry[&"offset"] + n*3 + 1),
					data.decode_u8(entry[&"offset"] + n*3 + 2)
				)
			if resource.palettes.is_empty(): palette = wad_palette
			resource.palettes.append(palette)
	return resource
