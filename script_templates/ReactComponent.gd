extends %BASE%

# Declare member variables here. Examples:
# var a%INT_TYPE% = 2
# var b%STRING_TYPE% = "text"

# Called when this node enters the tree
func _enter_tree() -> void:
	# Initialize this node as component
	ReactGD.component_init(self)

# Called every frame
func _process(_delta%FLOAT_TYPE%) -> void:
	# Update the component
	ReactGD.component_update(self)

# Called to start this component
func component_start() -> void:
	# Insert things to do when this component starts
	pass

# Called to render this component, return a dictionary
func component_render() -> Dictionary:
	return {
		0: {
			"type": Button,
			"props": {
				"text": "Hello World!"
			}
		}
	}


