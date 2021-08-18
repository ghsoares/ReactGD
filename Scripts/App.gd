extends ReactComponent

func construct() -> void:
	self.state = {
		"count": 0
	}

func _on_button_pressed() -> void:
	var count = self.state.count
	set_state({
		"count": count + 1
	})

func render() -> Dictionary:
	var count = self.state.count
	
	return {
		"PanelContainer#container": {
			"props": {
				"anchor_left": 0.0,
				"anchor_right": 1.0,
				"anchor_top": 0.0,
				"anchor_bottom": 1.0,
			},
			"theme": {
				"stylebox": {
					"panel": {
						"type": "StyleBoxFlat",
						"props": {
							"border_width_bottom": 16.0,
							"bg_color": Color(0.109804, 0.101961, 0.152941),
							"border_color": Color(0.192157, 0.207843, 0.294118),
							"corner_radius_top_left": 10.0,
							"corner_radius_top_right": 10.0,
							"corner_radius_bottom_right": 10.0,
							"corner_radius_bottom_left": 10.0,
						}
					}
				}
			},
			"children": {
				"Button#button": {
					"props": {
						"text": "Clicked " + str(count) + " times!",
						"size_flags_horizontal": SIZE_SHRINK_CENTER,
						"size_flags_vertical": SIZE_SHRINK_CENTER
					},
					"signals": {
						"pressed": "_on_button_pressed"
					}
				}
			}
		}
	}





