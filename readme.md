# ReactGD
ReactGD is a extension tool used to create dynamic UIs with flexibility and efficiency, where the nodes are updated only when needed.

The third prototype of the extension tool, maybe the last one, focused on runtime utility.

### Main features:
- Ability to implement any kind of script as a component:
```gd
class ButtonComponent:
	extends Control

	# A theme object
	var style: ReactGDTheme

	# Called when this node initializes
	func _init() -> void:
		# Initializes this node as a component
		ReactGD.component_init(self)
	
	# Called when the button is pressed
	func _on_button_pressed() -> void:
		# Get the state
		var state: Dictionary = ReactGD.component_get_state(self)

		# Set the state
		ReactGD.component_set_state(self, {
			"click_count": state.get("click_count", 0) + 1
		})

	# Render this component
	func _render() -> Dictionary:
		# Get the state from the component
		var state: Dictionary = ReactGD.component_get_state(self)

        # Get the click count from state
		var click_count: int = state.get("click_count", 0)

        # Return a simple button
        return ReactGD.create_node({
            "type": Button,
            "props": {
                "text": "Button pressed %d times" % click_count
            },
            "signals": {
                "pressed": "_on_button_pressed"
            }
        })
```
- Ability to render multiple children of a single component:
```gd
class MultipleChildrenComponent:
	extends VBoxContainer

	# Render this component
	func _render() -> Dictionary:
        # Return two labels
        return ReactGD.create_node({
            # Here we're rendering a "empty" node, which will render the children directly
            # to the component
            "type": "empty",
            "children": [
                ReactGD.create_node({
                    "type": Label,
                    "props": {
                        "text": "Hello!"
                    }
                }),
                ReactGD.create_node({
                    "type": Label,
                    "props": {
                        "text": "How are you?"
                    }
                })
            ]
        })
```
- Ability to change children order without creating new ones:
```gd
class ButtonComponent:
	extends VBoxContainer

	# Called when this node initializes
	func _init() -> void:
		# Initializes this node as a component
		ReactGD.component_init(self)
	
	# Called when the button is pressed
	func _on_button_pressed() -> void:
		# Get the state
		var state: Dictionary = ReactGD.component_get_state(self)

		# Set the state
		ReactGD.component_set_state(self, {
			"click_count": state.get("click_count", 0) + 1
		})

	# Render this component
	func _render() -> Dictionary:
		# Get the state from the component
		var state: Dictionary = ReactGD.component_get_state(self)

        # Get the click count from state
		var click_count: int = state.get("click_count", 0)

        # Render button first
		if click_count % 2 == 0:
			return ReactGD.create_node({
				"type": "empty",
				"children": [
					ReactGD.create_node({
                        # "key" property is needed to be able to change ordering
                        # without creating a new node, it must be unique
						"key": "button",
						"type": Button,
						"props": {
							"text": "Press me!",
							"size_flags_horizontal": Control.SIZE_SHRINK_CENTER
						},
						"signals": {
							"pressed": "_on_button_pressed"
						}
					}),
					ReactGD.create_node({
						"key": "label",
						"type": Label,
						"props": {
							"text": "Button pressed %d times" % [click_count]
						}
					})
				]
			})
        # Render label first
		else:
			return ReactGD.create_node({
				"type": "empty",
				"children": [
					ReactGD.create_node({
						"key": "label",
						"type": Label,
						"props": {
							"text": "Button pressed %d times" % click_count
						}
					}),
					ReactGD.create_node({
						"key": "button",
						"type": Button,
						"props": {
							"text": "Press me!",
							"size_flags_horizontal": Control.SIZE_SHRINK_CENTER
						},
						"signals": {
							"pressed": "_on_button_pressed"
						}
					})
				]
			})
```
- Get rendered node reference:
```gd
class ButtonComponent:
	extends Control

	# A theme object
	var style: ReactGDTheme

	# The button reference
	var btn: Button

	# Called when this node initializes
	func _init() -> void:
		# Initializes this node as a component
		ReactGD.component_init(self)
	
	# Called when the button is pressed
	func _on_button_pressed() -> void:
		print("Pressed from button %s" % btn)

		# Get the state
		var state: Dictionary = ReactGD.component_get_state(self)

		# Set the state
		ReactGD.component_set_state(self, {
			"click_count": state.get("click_count", 0) + 1
		})

	# Render this component
	func _render() -> Dictionary:
		# Get the state from the component
		var state: Dictionary = ReactGD.component_get_state(self)

        # Get the click count from state
		var click_count: int = state.get("click_count", 0)

        # Return a simple button
        return ReactGD.create_node({
            "type": Button,
			# Here we're setting the reference of the button to variable
			# "btn"
			"ref": "btn",
            "props": {
                "text": "Button pressed %d times" % click_count
            },
            "signals": {
                "pressed": "_on_button_pressed"
            }
        })
```
- Create themes with ease:
```gd
class ButtonComponent:
	extends VBoxContainer

	# A theme object
	var style: ReactGDTheme

	# Called when this node initializes
	func _init() -> void:
		# Initializes this node as a component
		ReactGD.component_init(self)

        # ReactGDTheme is the wrapper class used to set the theme variables
		style = ReactGDTheme.new()

        # Adding a new style that can contain multiple selectors
		style.add_style({
            # Here we're selecting the type Button, changing all the styles (*) with a StyleBoxFlat (flat)
			"Button:*:flat": {
                # Here we're setting "content_margin_left" and "content_margin_right" to value 16.0
				"content_margin_horizontal": 16.0,
                # Here we're setting "content_margin_top" and "content_margin_bottom" to value 4.0
				"content_margin_vertical": 4.0,
                # Here we're setting all the corner radius to value 4.0
				"corner_radius": 4.0
			}
		})
        # Adding a new color that can contain multiple selectors
		style.add_color({
            # Here we're selecting the type Button, changing all the colors (*) to black
			"Button:*": Color("#000"),
            # Here we're selecting the type Button, changing only "font_color_pressed" to red
			"Button:font_color_pressed": Color("#f00")
		})
	
	# Called when the button is pressed
	func _on_button_pressed() -> void:
		# Get the state
		var state: Dictionary = ReactGD.component_get_state(self)

		# Set the state
		ReactGD.component_set_state(self, {
			"click_count": state.get("click_count", 0) + 1
		})

	# Render this component
	func _render() -> Dictionary:
		# Get the state from the component
		var state: Dictionary = ReactGD.component_get_state(self)

        # Get the click count from state
		var click_count: int = state.get("click_count", 0)

        # Return a button and a label
		return ReactGD.create_node({
            "type": "empty",
            "children": [
                ReactGD.create_node({
                    "type": Button,
                    "props": {
                        "text": "Press me!",
                        # Here we're assigning the created theme
                        "theme": style.theme,
                        "size_flags_horizontal": Control.SIZE_SHRINK_CENTER
                    },
                    "signals": {
                        "pressed": "_on_button_pressed"
                    }
                }),
                ReactGD.create_node({
                    "type": Label,
                    "props": {
                        "text": "Button pressed %d times" % [click_count]
                    }
                })
            ]
        })
```
- Ability to get events that triggered rendering:
```gd
class ButtonComponent:
	extends VBoxContainer

	# Called when this node initializes
	func _init() -> void:
		# Initializes this node as a component
		ReactGD.component_init(self)
	
	# Called when the button is pressed
	func _on_button_pressed() -> void:
		# Get the state
		var state: Dictionary = ReactGD.component_get_state(self)

		# Set the state
		ReactGD.component_set_state(self, {
			"click_count": state.get("click_count", 0) + 1
		})

		# Trigger pressed event
		ReactGD.component_trigger_event(self, "pressed")

	# Render this component
	func _render() -> Dictionary:
		# Get the state from the component
		var state: Dictionary = ReactGD.component_get_state(self)

		# Get the click count from state
		var click_count: int = state.get("click_count", 0)

		# Check if has "pressed" event
		if ReactGD.component_get_event(self, "pressed"):
			print("Button pressed!")

		return ReactGD.create_node({
			"type": "empty",
			"children": [
				ReactGD.create_node({
					"key": "button",
					"type": Button,
					"ref": "btn",
					"props": {
						"text": "Press me!",
						"size_flags_horizontal": Control.SIZE_SHRINK_CENTER
					},
					"signals": {
						"pressed": "_on_button_pressed"
					}
				}),
				ReactGD.create_node({
					"key": "label",
					"type": Label,
					"props": {
						"text": "Button pressed %d times" % [click_count],
						"rect_min_size:x": ReactGD.tween()
					}
				})
			]
		})
```
- Create ui animations:
```gd
class ButtonComponent:
	extends VBoxContainer

	# Called when this node initializes
	func _init() -> void:
		# Initializes this node as a component
		ReactGD.component_init(self)
	
	# Called when the button is pressed
	func _on_button_pressed() -> void:
		# Get the state
		var state: Dictionary = ReactGD.component_get_state(self)

		# Set the state
		ReactGD.component_set_state(self, {
			"click_count": state.get("click_count", 0) + 1
		})

		# Trigger pressed event
		ReactGD.component_trigger_event(self, "pressed")

	# Render this component
	func _render() -> Dictionary:
		# Get the state from the component
		var state: Dictionary = ReactGD.component_get_state(self)

		# Get the click count from state
		var click_count: int = state.get("click_count", 0)

		# Create a tween object, simillar to SceneTreeTween
		var tw	= ReactGD.tween()

		# Play animation if has pressed event
		if ReactGD.component_get_event(self, "pressed"):
			tw.set_trans(Tween.TRANS_ELASTIC)
			tw.set_ease(Tween.EASE_OUT)
			tw.tween_property({"property": "rect_scale:x", "final_val": 1.1, "duration": 0.4})
			tw.parallel()
			tw.tween_property({"property": "rect_scale:y", "final_val": 1.1, "duration": 0.4})
			tw.set_trans(Tween.TRANS_CUBIC)
			tw.set_ease(Tween.EASE_IN_OUT)
			tw.tween_property({"property": "rect_scale:x", "final_val": 1.0, "duration": 0.25})
			tw.parallel()
			tw.tween_property({"property": "rect_scale:y", "final_val": 1.0, "duration": 0.25})

		return ReactGD.create_node({
			"type": "empty",
			"children": [
				ReactGD.create_node({
					"key": "button",
					"type": Button,
					"ref": "btn",
					# Here we're assigning the tweening animation
					"tween": tw,
					"props": {
						"text": "Press me!",
						"size_flags_horizontal": Control.SIZE_SHRINK_CENTER
					},
					"signals": {
						"pressed": "_on_button_pressed"
					}
				}),
				ReactGD.create_node({
					"key": "label",
					"type": Label,
					"props": {
						"text": "Button pressed %d times" % [click_count],
						"rect_min_size:x": ReactGD.tween()
					}
				})
			]
		})
```

### Planned features:
[ ] Global state management simillar to ReactJS Redux;

