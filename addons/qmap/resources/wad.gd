@tool
@icon("../icons/qmap.svg")
## .wad file resource
class_name WAD extends Resource

const TEXTURE_NAME_LENGTH := 16
const MAX_MIP_LEVELS := 4

enum WadFormat {
	## Use [enum QEntryType]
	Q_FORMAT,
	## Use [enum HLEntryType]
	HL_FORMAT
}

enum QEntryType {
	PALETTE = 0x40,
	S_BAR_PIC = 0x42,
	MIPS_TEXTURE = 0x44,
	CONSOLE_PIC = 0x45,
}

enum HLEntryType {
	Q_PIC = 0x42,
	MIPS_TEXTURE = 0x43,
	FIXED_FONT = 0x45,
}

var format := WadFormat.HL_FORMAT
## Textures sorted by name
@export var textures: Dictionary[String, Texture2D]
