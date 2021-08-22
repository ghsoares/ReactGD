# ReactGD
ReactGD is a extension tool used to create dynamic UIs with flexibility and efficiency, where the nodes are updated only when needed.

## How it works
Extending a script with `ReactComponent`, you can use the function `render`, which you return a Godot's `Dictionary`.
In this dictionary, you put everything that must be rendered given the component's properties and state.

The component only renders when there's a change in it's state or when a parent ReactComponent change the properties of the component.

There's a example script of a simple button that tells how much times the button has clicked as text and changes the background color to a random color:

```gdscript
# This is a .gdx file, gdx supports
# custom markdown language made for this addon

# To the first reactive element, extend from ReactUI,
# then for the nested component extend from ReactComponent
extends ReactUI

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

	# A quick and easy way to find a color perceived luminance 
	var color_lum := color.r * .2126 + color.g * .7152 + color.b * .0722

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
			},
			"colors": {
				# Assign dynamically the font color
				"font_color": Color.white if color_lum < .5 else Color.black,
				"font_color_hover": Color.white if color_lum < .5 else Color.black,
				"font_color_pressed": Color.white if color_lum < .5 else Color.black
			}
		},
		"click_count_label": {
			"colors": {
				"font_color": Color.black
			}
		}
	}

	# Here you are returning the rendering,
	# if you are using .gdx extension, you can use the markdown
	# language like on ReactJS, remember to wrap around parentheses
	# This extension import .gdx files like a regular gdscript file,
	# the difference is that it enables this custom language in the script
	# that will be parsed to a more ugly, verbose dictionary variant
	# (open the script on editor to see the parsed version)

	# Don't worry, all the comments are completely ignored by the parser
	return (
		# Like on HTML, you use tags with Godot's classes or
		# custom classes
		<VBoxContainer
			anchor_top: 0.0
			anchor_left: 0.0
			anchor_right: 1.0
			anchor_bottom: 1.0
			alignment: VBoxContainer.ALIGN_CENTER
		>
			<Button
				# Use props to set the variables of the node

				# Size flags
				size_flags_horizontal: Control.SIZE_SHRINK_CENTER
				size_flags_vertical: Control.SIZE_SHRINK_CENTER

				# Sets the node name
				name: "ClickButton"

				# Assign a static text
				text: "Click me!"

				# When you want to connect to a signal,
				# preffix the name of the signal with 'on_',
				# this tells the ReactTree
				on_pressed: "on_button_click"

				# Define the theme of the button
				theme: theme.click_button

				# Pass a variable name to 'ref' when you want to keep track
				# the reference of the rendered node
				ref: "click_button"
			/>
			<Label
				size_flags_horizontal: Control.SIZE_SHRINK_CENTER
				size_flags_vertical: Control.SIZE_SHRINK_CENTER
			
				# Dynamically assign the text, wrapping with parentheses
				text: ("You clicked " + str(click_count) + " times!")

				# You can hide/unhide dynamically
				visible: (click_count % 2 == 0)

				theme: theme.click_count_label
			/>
		</VBoxContainer>
	)
```
Here's the code in action:

![alt text](Demo%20Images/ClickButton.gif)

And here's a generic todo list:

![alt text](Demo%20Images/TodoList.gif)

All the demos can be found in [Demo Scenes](Demo%20Scenes)

## TODO:
- [ ] Rename some things (ReactGD is not the best way to call it, as it is only inspired by ReactJS, not based on);
- [ ] Turn into a addon;
- [ ] Add documentation;
- [ ] Improve gdx;
- [ ] Add functional based rendering (and hooks);
- [ ] Create intellisense, as extension for Visual Studio Code;
- [ ] Add a easy way to create prop transitions (with tweens);
- [ ] Upload to Godot's Asset Library;
- [ ] Port to GDNative as a native plugin.

