extends BoxContainer
class_name FreezableBoxContainer

var frozen := false

func freeze_layout():
	frozen = true

func thaw_layout():
	frozen = false
	queue_sort()

func _notification(what: int) -> void:
	if frozen and what == NOTIFICATION_SORT_CHILDREN:
		return
