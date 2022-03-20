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
					"on_pressed": "on_remove_pressed"
				},
				"children": {}
			}
		}

# Taks:
# [x] Add a VBoxContainer
# [x] Add multiple Task components when added to state
# [x] Remove Task components when button inside Task component is pressed

# Called when this node enters the tree
func _enter_tree() -> void:
	# Initialize this node as component
	ReactGD.component_init(self)

# Called every frame
func _process(_delta: float) -> void:
	# Update the component
	ReactGD.component_update(self)

# Called when the button is pressed
func on_button_pressed() -> void:
	# Get state
	var state	:= ReactGD.component_get_state(self) as Dictionary

	# Add task
	state.tasks.append(str(state.inc))

	# Increase increment
	state.inc += 1

	# Set state
	ReactGD.component_set_state(self, state)

# Called to remove a task
func on_task_remove(task) -> void:
	# Get state
	var state	:= ReactGD.component_get_state(self) as Dictionary

	# Remove task
	state.tasks.erase(task)

	# Set state
	ReactGD.component_set_state(self, state)

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
				"id": task,
				"on_remove": {
					"method": "on_task_remove",
					"args": [task]
				}
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
				"scroll": {
					"type": ScrollContainer,
					"props": {
						"size_flags_vertical": Control.SIZE_EXPAND_FILL
					},
					"children": {
						"tasks": {
							"type": VBoxContainer,
							"props": {
								"size_flags_horizontal": Control.SIZE_EXPAND_FILL
							},
							"children": tasks
						}
					}
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
						"size_flags_horizontal": 0,
						"on_pressed": "on_button_pressed"
					}
				}
			}
		}
	}


