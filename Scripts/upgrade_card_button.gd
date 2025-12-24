extends Button

func set_info(title_text, desc_text, icon_texture):
	$VBoxContainer/Title.text = title_text
	$VBoxContainer/Describetion.text = desc_text
	$VBoxContainer/icon.texture = icon_texture
