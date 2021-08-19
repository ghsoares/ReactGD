extends ReactComponent

# Path to a jetbrains mono font
const font_path := "res://Fonts/JetBrains/fonts/ttf/JetBrainsMono-Regular.ttf"

# Use this function to initialize component's state
func construct() -> void:
	self.state = {
		"click_count": 0,
		"color": Color.from_hsv(randf(), 1.0, 1.0)
	}

# Function is called when the button is clicked
func on_button_click() -> void:
	# Update the state and render the component
	self.set_state({
		"click_count": self.state.click_count + 1,
		"color": Color.from_hsv(randf(), 1.0, 1.0)
	})

# Render the component
func render() -> Dictionary:
	# Get the current state to render
	var click_count :int = self.state.click_count
	var color :Color = self.state.color
	
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
			},
			# Theme controls all the theme overrides of the node
			"theme": {
				# The theme is separated into categories like Godot:
				# - Color
				# - Constant
				# - Font
				# - Icon
				# - Stylebox
				"styles": {
					# For now, you must provide the name and the stylebox type
					["normal", StyleBoxFlat]: {
						"bg_color": color,
						# ReactGD provides some shorthands that can be usefull,
						# simillar to css
						"corner_radius": 8.0,
						"content_margin_horizontal": 16.0,
						"content_margin_vertical": 8.0
					},
					["hover", StyleBoxFlat]: {
						"bg_color": color,
						# ReactGD provides some shorthands that can be usefull,
						# simillar to css
						"corner_radius": 8.0,
						"content_margin_horizontal": 16.0,
						"content_margin_vertical": 8.0
					},
					["pressed", StyleBoxFlat]: {
						"bg_color": color,
						# ReactGD provides some shorthands that can be usefull,
						# simillar to css
						"corner_radius": 8.0,
						"content_margin_horizontal": 16.0,
						"content_margin_vertical": 8.0
					}
				},
				"fonts": {
					"font": {
						# You can dynamically provide a font size, that is
						# updated automatically
						"size": 24.0,
						"use_filter": true,
						# You can just provide the font path, that is loaded
						# only once when the path changes
						"src": font_path
					}
				}
			}
		}
	}

