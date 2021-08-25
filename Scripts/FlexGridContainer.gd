tool
extends Container
# A simple grid container that fits children with auto number of columns

class_name FlexGridContainer

export var children_size := Vector2(32.0, 32.0) setget set_children_size
export var spacing := Vector2(8.0, 8.0) setget set_spacing
export var num_columns := 8 setget set_num_columns

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_SORT_CHILDREN:
			_on_sort_children()

func _get_minimum_size() -> Vector2:
	var num_children := 0
	for i in range(get_child_count()):
		if get_child(i) is Control:
			num_children += 1
	var rows := ceil(num_children / float(num_columns))
	
	rows = max(rows, 1)
	
	return Vector2(
		num_columns * children_size.x + (num_columns - 1) * spacing.x,
		rows * children_size.y + (rows - 1) * spacing.y
	)

func set_children_size(new_size: Vector2) -> void:
	children_size = new_size
	minimum_size_changed()
	queue_sort()

func set_spacing(new_spacing: Vector2) -> void:
	spacing = new_spacing
	minimum_size_changed()
	queue_sort()

func set_num_columns(new_num: int) -> void:
	num_columns = new_num
	minimum_size_changed()
	queue_sort()

func _on_sort_children() -> void:
	var num_children := get_child_count()
	
	var id := 0
	for i in range(num_children):
		var c := get_child(i)
		if c is Control:
			var row := id / num_columns
			var column := id % num_columns
			
			var x := column * children_size.x + column * spacing.x
			var y := row * children_size.y + row * spacing.y
			
			var r := Rect2(x, y, children_size.x, children_size.y)
			fit_child_in_rect(c, r)
			
			id += 1









