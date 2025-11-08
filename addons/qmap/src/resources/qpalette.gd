@tool
@icon("../../icons/qmap.svg")
## .lmp file resource
##
## [url]https://quakewiki.org/wiki/.lmp[/url]
## [url]https://quakewiki.org/wiki/Quake_palette#palette.lmp[/url]
class_name QPalette extends ImageTexture

## Palette colors
@export var colors: PackedColorArray

## Returns a new blank palette with number of [member colors] equal to [param size]
static func new_empty(size: int = 256) -> QPalette:
	size = maxi(size, 0)
	var palette := QPalette.new()
	palette.colors.resize(size)
	for n in size: palette.colors[n] = Color8(0,0,255)
	palette.refresh_image()
	return palette

## Resets the image portion of the palette. 
## If size is not set, will just size as square (256 colors becomes 16x16 image)
## This should be called after updating [members colors]
func refresh_image(size: Vector2i = Vector2i.ZERO) -> void:
	if size == Vector2i.ZERO:
		var root := ceili(sqrt(colors.size()))
		size.x = root
		size.y = root
	var image := Image.create_empty(maxi(size.x, 1), maxi(size.y, 1), false, Image.FORMAT_RGB8)
	var n: int
	for y in image.get_height(): for x in image.get_width():
		if n < colors.size():
			image.set_pixel(x, y, colors[n])
		else:
			image.set_pixel(x, y, Color8(0,0,255))
		n += 1
	set_image(image)
