# Don't forget to extend from 'ReactComponent'!
extends ReactComponent

# Path to a jetbrains mono font
const font_path := "res://Fonts/JetBrains/fonts/ttf/JetBrainsMono-Regular.ttf"

# Reference of the rendered button
var click_button: Button

# Use this function to initialize component's state
func construct() -> void:
	self.state = {
		"click_count": 0,
		"color": Color.from_hsv(randf(), 1.0, 1.0)
	}

# Function is called when the button is clicked
func on_button_click() -> void:
	print(click_button.name)
	# Update the state and render the component
	self.set_state({
		"click_count": self.state.click_count + 1,
		"color": Color.from_hsv(randf(), 1.0, 1.0)
	})

# Here you will be rendering the component
func render():
	# Get the current state to use to render the nodes
	var click_count :int = self.state.click_count
	var color :Color = self.state.color

	# Temporary variable of all the returned node's themes
	var theme := {
		# You can insert multiple themes one for each node, remember to
		# reference by name latter
		"click_button": {
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

	# Here you are returning the rendering,
	# if you are using .gdx extension, you can use the markdown
	# language like on ReactJS, remember to prefix with '@' and wrap
	# around parentheses.
	# This extension import .gdx files like a regular gdscript file,
	# the difference is that it enables this custom language in the script
	# that will be parsed to a more ugly, verbose dictionary variant
	# (open the script on editor to see the parsed version)
	return [{"children":[], "props":{"name":"ClickButton", "text":("You clicked " + str(click_count) + " times!"), "theme":(theme.click_button)}, "ref":"idk", "signals":{"pressed":"on_button_click"}, "theme":, "type":Button}]