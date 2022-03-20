extends Control

class Task:
	extends HBoxContainer

	# The id of this task
	var id	: String

	# Signal to remove this task
	signal remove()

	# Called when this node enters the tree
	func _enter_tree() -> void:
		# Initialize this node as component
		ReactGD.component_init(self)

	# Called every frame
	func _process(_delta: float) -> void:
		# Update the component
		ReactGD.component_update(self)

	# Called when the remove button is pressed
	func on_remove_pressed() -> void:
		emit_signal("remove")

	# Called to start this component
	func component_start() -> void:
		pass

	# Called to render this component, return a dictionary
	func component_render() -> Dictionary:
		return {
			0: {
				"type": Button,
				"props": {
					"text": "Something " + str(id),
					"size_flags_horizontal": Control.SIZE_EXPAND_FILL
				},
				"children": {}
			},
			1: {
				"type": Button,
				"props": {
					"text": "Remove",
				},
				"children": {}
			}
		}

# Taks:
# [x] Add a VBoxContainer
# [ ] Add other components

# Called when this node enters the tree
func _enter_tree() -> void:
	# Initialize this node as component
	ReactGD.component_init(self)

# Called every frame
func _process(_delta: float) -> void:
	# Update the component
	ReactGD.component_update(self)

# Called when

# Called to start this component
func component_start() -> void:
	# Create a empty tasks object and increment
	ReactGD.component_set_state(self, {
		"inc": 0,
		"tasks": []
	})

# Called to render this component, return a dictionary
func component_render() -> Dictionary:
	# Get the state
	var state	:= ReactGD.component_get_state(self) as Dictionary

	# The tasks children
	var tasks	:= {}

	# Add the tasks in state
	for task in state.tasks:
		tasks[task] = {
			"type": Task,
			"props": {
				"id": task
			}
		}

	return {
		0: {
			"type": VBoxContainer,
			"props": {
				"anchor_left": 0,
				"anchor_top": 0,
				"anchor_right": 1,
				"anchor_bottom": 1,
			},
			"children": {
				"tasks": {
					"type": VBoxContainer,
					"props": {}
				},
				"spacer": {
					"type": HSeparator,
					"props": {
						"rect_min_size:y": 8
					}
				},
				"add_task": {
					"type": Button,
					"props": {
						"text": "Add task",
						"size_flags_horizontal": 0
					}
				}
			}
		}
	}


