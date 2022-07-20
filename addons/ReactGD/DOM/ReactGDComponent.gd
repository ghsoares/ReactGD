extends ReactGDNode
class_name ReactGDComponent

# Current state
var state	:= {}

# Internal function called to return a render data
func __render() -> Dictionary:
	# Get render data
	var r	:= _render()

	# Assert that isn't empty
	assert(not r.empty(), "Render data is empty!")

	# Return render data
	return r

# Virtual function to render this component
func _render() -> Dictionary:
	return {}

# Get this component name
func get_component_name() -> String:
	return "ReactGDComponent"

