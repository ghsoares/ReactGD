extends ReactTree

class ClickButton:
	extends ReactComponent
	
	signal remove(id)
	
	func construct() -> void:
		.construct()
		self.state = {
			"count": 0
		}
	
	func on_add_btn_pressed() -> void:
		set_state({
			"count": self.state.count + 1
		})
	
	func on_remove_btn_pressed() -> void:
		emit_signal("remove", self.props.id)
	
	func render() -> Dictionary:
		return {
			"type": HBoxContainer,
			"id": "fffffff",
			"children": [
				{
					"type": Label,
					"id": "addsadasddassad",
					"props": {
						"text": str(self.props.id)
					},
				},
				{
					"type": Button,
					"id": "addsadasdassad",
					"props": {
						"size_flags_horizontal": Control.SIZE_EXPAND_FILL,
						"text": "You clicked " + str(self.state.count) + " times!"
					},
					"signals": {
						"pressed": ["on_add_btn_pressed", [], 0]
					},
				},
				{
					"type": Button,
					"id": "fffffff",
					"props": {
						"size_flags_horizontal": Control.SIZE_EXPAND_FILL,
						"text": "Remove"
					},
					"signals": {
						"pressed": ["on_remove_btn_pressed", [], 0]
					},
				}
			],
			"props": {
				"size_flags_horizontal": Control.SIZE_EXPAND_FILL
			}
		}

func construct() -> void:
	.construct()
	self.state = {
		"click_count": 0,
		"click_ids": [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]
	}

func on_button_pressed() -> void:
	set_state({
		"click_count": self.state.click_count + 1
	})

func on_click_remove(id: int) -> void:
	var click_ids: Array = self.state.click_ids
	click_ids.erase(id)
	set_state({
		"click_ids": click_ids
	})

func render() -> Dictionary:
	var click_count: int = self.state.click_count
	
	var children := []
	
	for i in self.state.click_ids:
		children.append({
			"type": ClickButton,
			"id": "0Fa12321321123F1235" + str(i),
			"props": {
				"name": "click_button_" + str(i),
				"id": i
			},
			"signals": {
				"remove": ["on_click_remove", [], 0]
			}
		})
	
	return {
		"type": VBoxContainer,
		"id": "0FaF1234",
		"props": {
			"anchor_left": 0.0,
			"anchor_top": 0.0,
			"anchor_right": 1.0,
			"anchor_bottom": 1.0
		},
		"children": children
	}





