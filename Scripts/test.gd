extends Control

class OtherComponent:
	extends Control

	# Called when this node initializes
	func _init() -> void:
		# Initializes this node as a component
		ReactGD.component_init(self)

	# Render this component
	func _render() -> Dictionary:
		# Return simple node
		return ReactGD.create_node({
			"type": Label,
			"props": {
				"text": "This text will hide"
			}
		})

class ButtonComponent:
	extends VBoxContainer

	# A theme object
	var style: ReactGDTheme

	# The button reference
	var btn: Button

	# Called when this node initializes
	func _init() -> void:
		# Initializes this node as a component
		ReactGD.component_init(self)

		style = ReactGD.create_teme()

		style.add_style({
			"Button:*:flat": {
				"content_margin_horizontal": 16.0,
				"content_margin_vertical": 4.0,
				"corner_radius": 4.0
			}
		})
		style.add_color({
			"Button:*": Color("#000"),
			"Button:font_color_pressed": Color("#f00")
		})
	
	# Called when the button is pressed
	func _on_button_pressed() -> void:
		print("Pressed button from %s" % btn)

		# Get the state
		var state: Dictionary = ReactGD.component_get_state(self)

		# Set the state
		ReactGD.component_set_state(self, {
			"click_count": state.get("click_count", 0) + 1
		})

		# Trigger event
		ReactGD.component_trigger_event(self, "pressed")

	# Render this component
	func _render() -> Dictionary:
		# Get the state from the component
		var state: Dictionary = ReactGD.component_get_state(self)

		var click_count: int = state.get("click_count", 0)

		var tw	= ReactGD.tween()
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
					"tween": tw,
					"props": {
						"text": "Press me!",
						"theme": style.theme,
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
						"theme": style.theme,
						"rect_min_size:x": ReactGD.tween()
					}
				})
			]
		})
		
# Called when this node is ready
func _ready() -> void:
	add_child(ButtonComponent.new())
