@tool
## Saver for [FGD]
class_name FGDResourceSaver extends ResourceFormatSaver

func _get_recognized_extensions(resource: Resource) -> PackedStringArray:
	return ["fgd", "FGD"]

func _recognize(resource: Resource) -> bool:
	return resource is FGD

func _save(resource: Resource, path: String, flags: int) -> Error:
	if !(resource is FGD): return ERR_INVALID_DATA
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null: return ERR_CANT_OPEN
	var fgd := resource as FGD
	# Write header if present
	if !fgd.header.is_empty():
		for line in fgd.header.split("\n"):
			file.store_string("// " + line + "\n")
		file.store_string("\n")
	# Write @mapsize if present
	if fgd.max_map_size != Vector2i.ZERO:
		file.store_string("@mapsize (%s, %s)\n\n"%[fgd.max_map_size.x, fgd.max_map_size.y])
	for key: String in fgd.classes:
		# Write class type
		if fgd.classes[key].class_type == FGDClass.ClassType.POINT:
			file.store_string("@PointClass ")
		elif fgd.classes[key].class_type == FGDClass.ClassType.SOLID:
			file.store_string("@SolidClass ")
		else:
			file.store_string("@BaseClass ")
		# Write base classes if any
		if fgd.classes[key].base_classes.size() > 0:
			file.store_string("base(")
			for n in fgd.classes[key].base_classes.size():
				if n + 1 >= fgd.classes[key].base_classes.size():
					file.store_string("%s"%fgd.classes[key].base_classes[n])
				else:
					file.store_string("%s, "%fgd.classes[key].base_classes[n])
			file.store_string(") ")
		# Write sizing if changed from default
		if fgd.classes[key].sizing_type == FGDClass.SizingType.ONLY_POSITIVE:
			if fgd.classes[key].positive_size != Vector3i(16,16,16):
				file.store_string("size(%s %s %s) "%[fgd.classes[key].positive_size.x, fgd.classes[key].positive_size.y, fgd.classes[key].positive_size.z])
		else:
			if fgd.classes[key].positive_size != Vector3i(16,16,16) || fgd.classes[key].negative_size != Vector3i.ZERO:
				file.store_string("size(%s %s %s, %s %s %s) "%[fgd.classes[key].negative_size.x, fgd.classes[key].negative_size.y, fgd.classes[key].negative_size.z, fgd.classes[key].positive_size.x, fgd.classes[key].positive_size.y, fgd.classes[key].positive_size.z])
		# Write color if changed from default
		if fgd.classes[key].color != Color.MAGENTA:
			file.store_string("color(%s %s %s) "%[fgd.classes[key].color.r8, fgd.classes[key].color.g8, fgd.classes[key].color.b8])
		# Write sprite if present
		if !fgd.classes[key].icon_sprite.is_empty():
			file.store_string('iconsprite("%s") '%fgd.classes[key].icon_sprite)
		# Write studio if present
		if !fgd.classes[key].studio.is_empty():
			file.store_string('studio("%s") '%fgd.classes[key].studio)
		# Write class name
		file.store_string("= %s "%key.replace(" ",""))
		# Write description if present
		if !fgd.classes[key].description.is_empty():
			file.store_string(': "%s" '%fgd.classes[key].description.replace('"', "'"))
		# Write properties
		if fgd.classes[key].properties.size() > 0:
			file.store_string("\n[\n")
			for prop: String in fgd.classes[key].properties.keys():
				# Write property internal name
				file.store_string("\t%s"%prop.replace("#","").replace(".","").replace('"',"").replace(" ",""))
				# Write property type
				match fgd.classes[key].properties[prop].type:
					FGDEntityProperty.PropertyType.STRING: file.store_string("(string) ")
					FGDEntityProperty.PropertyType.INTEGER: file.store_string("(integer) ")
					FGDEntityProperty.PropertyType.FLOAT: file.store_string("(float) ")
					FGDEntityProperty.PropertyType.FLAGS: file.store_string("(flags) ")
					FGDEntityProperty.PropertyType.CHOICES: file.store_string("(choices) ")
					FGDEntityProperty.PropertyType.COLOR_255: file.store_string("(color255) ")
					FGDEntityProperty.PropertyType.COLOR_1: file.store_string("(color1) ")
					FGDEntityProperty.PropertyType.ANGLE: file.store_string("(angle) ")
					FGDEntityProperty.PropertyType.TARGET_SOURCE: file.store_string("(target_source) ")
					FGDEntityProperty.PropertyType.TARGET_DESTINATION: file.store_string("(target_destination) ")
					FGDEntityProperty.PropertyType.DECAL: file.store_string("(decal) ")
					FGDEntityProperty.PropertyType.STUDIO: file.store_string("(studio) ")
					FGDEntityProperty.PropertyType.SPRITE: file.store_string("(sprite) ")
					FGDEntityProperty.PropertyType.SCALE: file.store_string("(scale) ")
					FGDEntityProperty.PropertyType.VECTOR: file.store_string("(vector) ")
				# Write property display name if present
				if !fgd.classes[key].properties[prop].display_name.is_empty():
					file.store_string(': "%s" '%fgd.classes[key].properties[prop].display_name.replace('"', "'"))
				# Write property default value if present
				if !fgd.classes[key].properties[prop].default_value.is_empty():
					if !fgd.classes[key].properties[prop].type == FGDEntityProperty.PropertyType.INTEGER && !fgd.classes[key].properties[prop].type == FGDEntityProperty.PropertyType.FLAGS && !fgd.classes[key].properties[prop].type == FGDEntityProperty.PropertyType.CHOICES:
						file.store_string(': "')
					else:
						file.store_string(': ')
					file.store_string("%s"%fgd.classes[key].properties[prop].default_value.replace('"', "'"))
					if !fgd.classes[key].properties[prop].type == FGDEntityProperty.PropertyType.INTEGER && !fgd.classes[key].properties[prop].type == FGDEntityProperty.PropertyType.FLAGS && !fgd.classes[key].properties[prop].type == FGDEntityProperty.PropertyType.CHOICES:
						file.store_string('" ')
					else:
						file.store_string(' ')
				# Write tooltip if present
				if !fgd.classes[key].properties[prop].display_tooltip.is_empty():
					file.store_string(': "%s" '%fgd.classes[key].properties[prop].display_tooltip.replace('"', "'"))
				# Write property choices / flags
				if fgd.classes[key].properties[prop].choices.size() > 0:
					if fgd.classes[key].properties[prop].type == FGDEntityProperty.PropertyType.FLAGS || fgd.classes[key].properties[prop].type == FGDEntityProperty.PropertyType.CHOICES:
						file.store_string("=\n\t[\n")
						for i in fgd.classes[key].properties[prop].choices.keys():
							file.store_string('\t\t%s : "%s"'%[i, fgd.classes[key].properties[prop].choices[i].replace('"', "'")])
							if fgd.classes[key].properties[prop].type == FGDEntityProperty.PropertyType.FLAGS:
								if fgd.classes[key].properties[prop].default_flags.has(i):
									file.store_string(" : 1\n")
								else:
									file.store_string(" : 0\n")
							else:
								file.store_string("\n")
						file.store_string("\t]\n")
					else:
						file.store_string("\n")
				else:
					file.store_string("\n")
			file.store_string("]\n")
		else:
			file.store_string("[]\n")
	file.store_string("\n")
	file.close()
	return OK
