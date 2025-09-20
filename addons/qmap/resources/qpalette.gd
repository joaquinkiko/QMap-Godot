@tool
@icon("../icons/qmap.svg")
## .lmp file resource
##
## [url]https://quakewiki.org/wiki/.lmp[/url]
## [url]https://quakewiki.org/wiki/Quake_palette#palette.lmp[/url]
class_name QPalette extends Resource

## Palette colors
@export var colors: PackedColorArray

static func new_empty(size: int = 256) -> QPalette:
	size = maxi(size, 0)
	var palette := QPalette.new()
	palette.colors.resize(size)
	for n in size: palette.colors[n] = Color8(0,0,255)
	return palette
