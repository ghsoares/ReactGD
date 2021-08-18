extends ReactComponent

# Use this function to initialize component's state
func construct() -> void:
	self.state = {
		"click_count": 0
	}

# Function is called when the button is clicked
func on_button_click() -> void:
	# Update the state and render the component
	self.set_state({
		"click_count": self.state.click_count + 1
	})

# Render the component
func render() -> Dictionary:
	var click_count :int = self.state.click_count
	
	return {
		# To add a node, pass the class and the name
		[Button, "ClickButton"]: {
			# Use props to set the variables of the node
			"props": {
				# Renders a reactive text, automatically updates with state
				"text": "You clicked " + str(click_count) + " times!"
			},
			# Use signals to bind the signals of the node with this component
			"signals": {
				# Pass the function name and ReactGD automatically
				# manages connection and disconnection of the signal
				"pressed": "on_button_click"
			}
		}
	}

