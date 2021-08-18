# ReactGD
ReactGD is a extension tool used to create dynamic UIs with flexibility and efficiency, where the nodes are updated only when needed.

## How it works
Extending a script with `ReactComponent`, you can use the function `render`, which you return a Godot's `Dictionary`.
In this dictionary, you put everything that must be rendered given the component's properties and state.

The component only renders when there's a change in it's state or when a parent ReactComponent change the properties of the component.

There's a example script of a simple button that tells how much times the button has clicked as text:

```gdscript
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
```

## TODO:
- [ ] Rename some things (ReactGD is not the best way to call it, as it is only inspired by ReactJS, not based on);
- [ ] Turn into a addon;
- [ ] Add documentation;
- [ ] Improve syntax (maybe custom language extension?);
- [ ] Upload to Godot's Asset Library;
- [ ] Port to GDNative as a native plugin;

