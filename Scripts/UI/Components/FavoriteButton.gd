extends AnimatedOptionButton
class_name FavoriteButton

@export_category("Settings")
@export var solid_texture: Texture2D
@export var basic_texture: Texture2D

@export var current_status: bool = false


func set_status(status: bool) -> void:
	icon = solid_texture if status else basic_texture
	current_status = status
