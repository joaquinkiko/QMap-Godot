## Represents entity properties within an [FGDClass]
class_name FGDEntityProperty extends Resource

enum PropertyType {
	## Character sequence
	STRING,
	## Whole number in base 10 or hexadecimal via prefix 0x
	INTEGER,
	## Decimal number
	FLOAT,
	## Integer value read bitwise (some editors only support this for [b]spawnflags[/b])
	FLAGS,
	## Predefined set of values (similar to an enum)
	CHOICES,
	## [Vector3] Angle
	ANGLE,
	## RGB color in value 0-255
	COLOR_255,
	## RGB color in value 0.0-1.0
	COLOR_1,
	## Name that other entities may target
	TARGET_SOURCE,
	## Name of a [enum PropertyType.TARGET_SOURCE] to target
	TARGET_DESTINATION,
	## Texture to be used by [member FGDClass.includes_decal]
	DECAL,
	## Model for use with [member FGDClass.studio]
	STUDIO,
	## Sprite file
	SPRITE,
	## WAV file
	SOUND,
	## Scaling for model or sprite
	SCALE,
	## [Vector3]
	VECTOR
}

@export var type: PropertyType = PropertyType.STRING
## Default value (ignored if not valid based on [member type])
@export var default_value: String
## Editor display name
@export var display_name: String
## Editor display tooltip
@export_multiline var display_tooltip: String
## Choices or flags (flags should be powers of 2 (1,2,4,8...) not exceeding 2,147,483,648)
@export_group("Choices & Flags")
@export var choices: Dictionary[int, String]
## Values of flags that should default to [b]true[/b]
@export var default_flags: PackedInt32Array
