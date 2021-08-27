extends ReactGDComponent

class ClickButton:
	extends ReactGDComponent
	
	signal clicked
	
	var click_count: int
	
	func construct() -> void:
		self.events = {
			"clicked": false
		}
	
	func on_button_pressed() -> void:
		if click_count % 2 == 1:
			trigger_event("clicked")
		emit_signal("clicked")
	
	func render():
		var shake = null
		if self.events.clicked:
			shake = do_transition().from_commands([
				{
					"type": "punch",
					"prop": "rect_scale:x",
					"peak": 1.4,
					"target": 1.0,
					"duration": .2,
					"trans_type": Tween.TRANS_CUBIC,
					"ease_type": Tween.EASE_OUT
				},
				{
					"type": "append",
					"value": .1
				},
				{
					"type": "punch",
					"prop": "rect_scale:y",
					"peak": 1.4,
					"target": 1.0,
					"duration": .2,
					"trans_type": Tween.TRANS_CUBIC,
					"ease_type": Tween.EASE_OUT
				},
				{
					"type": "append",
					"value": 0
				},
				{
					"type": "punch",
					"prop": "rect_rotation",
					"peak": rand_range(-5.0, 5.0),
					"target": 0.0,
					"duration": .1,
					"trans_type": Tween.TRANS_CUBIC,
					"ease_type": Tween.EASE_OUT
				}
			])
		
		return {
			"id": "_X6G7",
			"type": Control,
			"props": {
				"anchor_left": 0.0,
				"anchor_top": 0.0,
				"anchor_right": 1.0,
				"anchor_bottom": 1.0,
			},
			"children": {
				"_X6G7": {
					"id": "_X6G7",
					"type": Button,
					"props": {
						"rect_size": Vector2(256, 64),
						"rect_pivot_offset": Vector2(128, 32),
						"text": "You clicked " + str(click_count) + " times!",
						"anchor_left": 0.5,
						"anchor_top": 0.5,
						"anchor_right": 0.5,
						"anchor_bottom": 0.5,
						"on_pressed": "on_button_pressed",
						"transition": shake
					}
				}
			}
		}



func construct() -> void:
	self.state = {
		"click_count": 0
	}

func on_button_clicked() -> void:
	set_state({
		"click_count": self.state.click_count + 1
	})
	pass

func render():
	return {
		"id": "_X6G7",
		"type": Control,
		"props": {
			"anchor_left": 0.0,
			"anchor_top": 0.0,
			"anchor_right": 1.0,
			"anchor_bottom": 1.0,
		},
		"children": {
			"_X6G7": {
				"id": "_X6G7",
				"type": ClickButton,
				"props": {
					"click_count": self.state.click_count,
					"on_clicked": "on_button_clicked"
				},
				"children": {
					"aaaa": {
						"id": "aaaa",
						"type": Label
					}
				}
			}
		}
	}





