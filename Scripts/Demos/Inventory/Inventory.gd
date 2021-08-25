extends Node
# Just a simple inventory data container, has relevant signals
# to reactivity

class_name Inventory

signal inventory_resized(new_size)
signal item_count_changed(i, item)
signal item_added(i, item)
signal item_removed(i, item)
signal item_moved(from, to, item, other)
signal item_selected(i, item)

var data: Array
var size: int = 5
var selected_item: int = -1

func initialize() -> void:
	data = []
	resize(max(size, 1))

func resize(new_size: int) -> void:
	if new_size <= 0: return
	size = new_size
	data.resize(new_size)
	for i in range(new_size):
		if !data[i]: data[i] = {}
	
	if selected_item >= new_size:
		selected_item = -1
		emit_signal("item_selected", selected_item, {})

	emit_signal("inventory_resized", new_size)

func add_item(item: Dictionary) -> void:
	var id :String = item.id
	var stackable :bool = item.get("stackable", false)
	
	if stackable:
		for i in range(data.size()):
			var other = data[i]
			if !other: continue
			
			var other_id :String = other.id
			
			if other_id == id:
				if item.has("max_stack"):
					var max_stack: int = item.max_stack
					var diff: int = min(item.count, max_stack - other.count)
					
					if diff > 0:
						item.count -= diff
						other.count += diff
						emit_signal("item_count_changed", i, other)
					if item.count == 0: return
				else:
					other.count += item.count
					item.count = 0
					emit_signal("item_added", i, other)
					return
	
	for i in range(data.size()):
		if !data[i]:
			data[i] = item
			emit_signal("item_added", i, item)
			return

func move_item(from: int, to: int) -> void:
	if from == to: return

	var from_item = data[from]
	var to_item = data[to]
	
	data[from] = to_item
	data[to] = from_item
	
	emit_signal("item_moved", from, to, from_item, to_item)
	emit_signal("item_moved", to, from, to_item, from_item)

	if from == selected_item:
		emit_signal("item_selected", selected_item, to_item)
	elif to == selected_item:
		emit_signal("item_selected", selected_item, from_item)

func remove_item(id: int) -> void:
	var prev :Dictionary = data[id]
	data[id] = {}

	emit_signal("item_removed", id, prev)

func select_item(id: int) -> void:
	selected_item = id
	if selected_item == -1:
		emit_signal("item_selected", selected_item, {})
	else:
		emit_signal("item_selected", selected_item, data[id])

func get_item(pos: int) -> Dictionary:
	return data[pos]


