extends Control

# Simple component
class TestComponent:
	extends ReactGDComponent

# Called when the node is ready
func _ready() -> void:
	# Create a react node tree
	var tree	:= ReactGD.create_tree(self)

	# Render a simple component
	tree.render({
		"type": VBoxContainer,
		"children": {
			0: {
				"type": Button,
				"properties": {
					"text": "Hello from first button!"
				}
			},
			1: {
				"type": Button,
				"properties": {
					"text": "Hello from second button!"
				}
			}
		}
	})

	# Render with a deleted node
	tree.render({
		"type": VBoxContainer,
		"children": {
			1: {
				"type": Button,
				"properties": {
					"text": "Hello from second button!"
				}
			}
		}
	})



