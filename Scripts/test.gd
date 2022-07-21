extends Control

# A simple component
class ButtonComponent:
	extends ReactGDComponent

	var label_text: String
	var button_text: String

	func _render() -> Dictionary:
		return {
			"label": {
				"id": "label",
				"type": Label,
				"props": {
					"text": label_text
				}
			},
			"btn": {
				"id": "btn",
				"type": Button,
				"props": {
					"text": button_text
				}
			}
		}

# The node tree
var node_tree

# Called when a button is pressed
func on_button_pressed(btn: Button) -> void:
	print(btn.text)

# Called when the node is ready
func _ready() -> void:
	node_tree = ReactGD.create_tree(self)

	node_tree.render({
		"id": "root",
		"type": ButtonComponent,
		"children": {
			
		}
	})