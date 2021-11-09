# React GD - Create user interfaces with reactive components

## Building from source
React GD is now a module, that means you need build with the engine source yourself, but don't worry, this section will go trough all the steps needed to build it.

### 1. Requirements
You need some tools to be able to build from source, those requirements are explained in the Godot docs, for [Windows](https://docs.godotengine.org/en/stable/development/compiling/compiling_for_windows.html), [GNU/Linux](https://docs.godotengine.org/en/stable/development/compiling/compiling_for_x11.html) and [MacOS](https://docs.godotengine.org/en/stable/development/compiling/compiling_for_osx.html).
Also you need to clone the godot source, so in any folder execute:
`git clone -b 3.x https://github.com/godotengine/godot.git`
This will clone the 3.x branch which is used by this module.

### 2. Building
Clone this repository inside godot/modules/ folder, then from the godot root folder, run the following commands:
#### x11/Linux:
`scons platform=x11 reactgd_enabled=yes -j4`

#### Windows:
I didn't test for windows yet, but you can try to compile it with:
`scons platform=windows reactgd_enabled=yes -j4`

### 3. Run
The building step will produce an executable in godot/bin/ folder, go ahead and run it with:
#### x11/Linux:
`./bin/godot.x11.tools.64`

### Windows:
`start bin/godot.windows.tools.64.exe`

## How to use
(Disclaimer: This part will be used for future implementations, the reactive part of ReactGD is not yet implemented)

ReactGD comes with runtime tools and extra syntax for GDScript, to help you to build user interfaces, so let's start with a simple script, this script will render a simple `Control` node, expanded to full screen with a `Button` as children, and when you press the button, the message "Hello world from React GD!" should be printed.
```gdscript
# You can use a tool script to visualize the changes in the editor
tool
# Any component need to inherit from ReactGDComponent
extends ReactGDComponent

# This function will be called when the button is pressed
func on_btn_pressed() -> void:
	print("Hello world from React GD!")

# `render` is the main function used to return the node tree to render
func render():
	# Let's return a Control node as root node, you can only return one node from each
	# return statement
	return (
		<Control
			# Set the anchors so the control resize to it's parent
			anchor_left = 0.0
			anchor_top = 0.0
			anchor_right = 1.0
			anchor_bottom = 1.0
		>
			# Let's put a button as child
			<Button
				# Put a simple text
				text = "Press me!"

				# To pass a function to be called from a signal, prefix the signal name with
				# `on_` so ReactGD understand that it is a signal connection
				on_pressed = on_btn_pressed
			/>
		</Control>
	)
```

And done! With some simple lines you already have a reactive interface!
Set this script to a Control node, run the scene and press the button, and you should be seeing the message "Hello world from React GD!" in the output. Congratulations, you made your first GDXScript!

