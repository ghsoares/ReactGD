extends Control

# Taks:
# [x] Create a button with "Something" as text
# [x] When button is pressed, change 'clicks' state

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
	# Get previous state
	var state	:= ReactGD.component_get_state(self) as Dictionary

	# Increment clicks
	ReactGD.component_set_state(
		self, {"clicks": state.clicks + 1}
	)

# Called to start this component
func component_start() -> void:
	# Set this node's initial state
	ReactGD.component_set_state(self, {
		"clicks": 0
	})

# Called to render this component, return a dictionary
func component_render() -> Dictionary:
	# Get current state
	var state	= ReactGD.component_get_state(self)

	# Get number of clicks
	var clicks	:= state.clicks as int

	if clicks == 0:
		return {
			0: {
				"type": Button,
				"props": {
					"text": "Something",
					"on_pressed": "on_button_pressed"
				}
			}
		}
	else:
		return {
			0: {
				"type": Button,
				"props": {
					"text": "Clicks: " + str(clicks),
					"on_pressed": "on_button_pressed"
				}
			}
		}



	