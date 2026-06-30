extends FreezableGridContainer
class_name FlexBoxFreezableGridContainer

func _ready() -> void:
    get_parent().resized.connect(_update_columns)

func _update_columns() -> void:
    if get_child_count() == 0:
        return

    var parent_width = get_parent().size.x
    var cols = max(1, int(parent_width / 96))
    columns = cols
