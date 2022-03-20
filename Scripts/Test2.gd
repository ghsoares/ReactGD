extends Control

# Taks:
# [x] Add a VBoxContainer
# [x] Add three buttons as children
# [x] Remove each button when pressed
# [x] Restore all buttons when all buttons are removed

# Called when this node enters the tree
func _enter_tree() -> void:
	# Initialize this node as component
	ReactGD.component_init(self)

# Called every frame
func _process(_delta: float) -> void:
	# Update the component
	ReactGD.component_update(self)

# Called when a button is pressed
func on_button_pressed(id: int) -> void:
	# Remove the button
	ReactGD.component_set_state(self, {
		"btn_" + str(id): false
	})

	# Get the state
	var state	:= ReactGD.component_get_state(self)

	# For each button, check if all is untoggled
	for i in 3:
		if state["btn_" + str(i)]: return

	# If they are untoggled, set all as true
	ReactGD.component_set_state(self, {
		"btn_0": true,
		"btn_1": true,
		"btn_2": true,
	})

# Called to start this component
func component_start() -> void:
	# Create children buttons
	ReactGD.component_set_state(self, {
		"btn_0": true,
		"btn_1": true,
		"btn_2": true,
	})

# Called to render this component, return a dictionary
func component_render() -> Dictionary:
	# Get the state
	var state		:= ReactGD.component_get_state(self) as Dictionary

	# The children of the container
	var children 	:= {}

	# Add three childrens
	for i in 3:
		# Get if this child is enabled
		var enabled	:= state["btn_" + str(i)] as bool

		# If it is, add to the children
		if enabled:
			var props	:= {
				"on_pressed": {
					"method": "on_button_pressed",
					"args": [i]
				}
			}
			var child	:= {
				"type": Button,
				"props": props
			}

			match i:
				0:
					props.text = "Remove me"
				1:
					props.text = "Delete me"
				2:
					props.text = "Cancel me"
			children[i] = child

	return {
		0: {
			"type": VBoxContainer,
			"props": {
				"anchor_left": 0,
				"anchor_top": 0,
				"anchor_right": 1,
				"anchor_bottom": 1,
			},
			"children": children
		}
	}



	

