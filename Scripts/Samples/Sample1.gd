extends Control

# Tasks:
# [ ] Add a single button

# Internal component data
var __component_data

# Called when the node receives a notification
func _notification(what: int) -> void:
	# Component init/deinit
	if what == NOTIFICATION_READY:
		ReactGD.component_init(self)
	elif what == NOTIFICATION_PREDELETE:
		ReactGD.component_deinit(self)

# Called when button is pressed
func on_button_pressed() -> void:
	# Get the component's state
	var state	:= ReactGD.component_get_state(self) as Dictionary

	# Increment the state
	ReactGD.component_set_state(self, {
		"inc": state.inc + 1
	})

# Called when the component starts
func component_start() -> void:
	# Set initial state
	ReactGD.component_set_state(self, {
		"inc": 0
	})

# Render function of the component
func component_render():
	# Get the component's state
	var state	:= ReactGD.component_get_state(self) as Dictionary

	# Get the increment count
	var inc		:= state.inc as int

	# Render a single button with "Press me!" as text
	return {
		0: {
			"type": Button,
			"props": {
				# Change the text based on increment
				"text": "Press me!" if inc == 0 else "Clicked " + str(inc) + " times!",
				"rect_scale": 	ReactGD.do_tween().goto(Vector2(1.0, 1.0), .1, 4, 2) \
								if inc % 2 == 0 else \
								ReactGD.do_tween().goto(Vector2(1.1, 1.1), .1, 4, 2),
				"on_pressed": {
					"target_method": "on_button_pressed"
				}
			}
		}
	}
