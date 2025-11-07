## Represents an Entity Class within an [FGD]
class_name FGDClass extends Resource

enum SizingType {
	## Stores size as (-x -y -z +x +y +z)
	NEGATIVE_AND_POSITIVE,
	## Stores size as (x y z)
	ONLY_POSITIVE
}
enum ClassType {
	## @BaseClass - Set of properties that can be inherited
	BASE,
	## @SolidClass - Brush entity with volume
	SOLID,
	## @PointClass - Entity that exists at non-arbitrary point
	POINT
}

@export var class_type: ClassType
## Inherited classes [b](should be listed prior to this class in FGD)[/b]
@export var base_classes: PackedStringArray
## Editor description (typically limit each line to 125 characters)
## (Quotation marks (" ") will be replaced with apostrophes (' ')
@export_multiline var description: String
## Default properties sorted by internal name (typically limit to 30 characters)
## ( " . # and whitespace characters will be removed)
## (Typically limit to no more than 127 properties)
@export var properties: Dictionary[String, FGDEntityProperty]
@export_category("Optional")
@export_group("Editor Sizing")
@export var sizing_type: SizingType = SizingType.ONLY_POSITIVE
## [b]ONLY[/b] use if [member sizing_type] is [enum SizingType.NEGATIVE_AND_POSITIVE]
@export var negative_size: Vector3i
## Positive sizing for [enum SizingType.NEGATIVE_AND_POSITIVE]
## or main sizing for [enum SizingType.ONLY_POSITIVE]
@export var positive_size: Vector3i = Vector3i(16,16,16)
@export_group("Editor Preview")
## Editor preview color
@export_color_no_alpha var color: Color = Color.MAGENTA
## Path to preview icon to display in editor (see map editor supported formats)
@export var icon_sprite: String
## Path to preview model to display in editor (see map editor supported formats)
@export var studio: String
@export_group("Extra Features")
## Should editor render decals on nearby surfaces via "texture" property
@export var includes_decal: bool
## Should editor render sprite via [enum FGDEntityProperty.PropertyType.SPRITE] property
@export var includes_sprite: bool
