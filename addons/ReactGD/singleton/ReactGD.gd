tool
extends Node

# Internal component's data structure
class ComponentData:
	extends Reference

	# The component's state dictionary
	var state := {}

	# Dirty flag, if needs to re-render
	var dirty := true

	# Previous render state
	var previous_render := {}

# Property tween data, supports method chaining
class PropertyTween:
	extends Reference

	# Single property frame
	class Frame:
		extends Reference

		# Target value
		var value

		# Start time
		var start: float

		# End time
		var end: float

		# Transition type
		var trans_type: int

		# Ease type
		var ease_type: int

	# Stores all the tween frames
	var frames	:= []

	# Current time
	var time	:= 0.0

	# Simple interpolate to value
	func goto(val, duration: float, trans_type := 0, ease_type := 0, delay := 0.0):
		# Add frame
		var frame := Frame.new()

		# Set properties
		frame.value = val
		frame.start = time + delay
		frame.end = time + delay + duration
		frame.trans_type = trans_type
		frame.ease_type = ease_type

		# Set current animation time
		time = frame.end

		# Append frame
		frames.append(frame)

		return self

	# Method to setup and animate tween
	func _animate(tw: Tween, prop: String, object: Object) -> void:
		# Get current animated value
		var val	= object.get_indexed(prop)

		# For each frame
		for frame in frames:
			# Interpolate property
			tw.interpolate_property(
				object, prop, val, frame.value,
				frame.end - frame.start, frame.trans_type,
				frame.ease_type,
				frame.start
			)

			# Set current value
			val = frame.value
		
		# Start animation
		tw.start()

# Global idle process tween node
var tw_idle	: Tween

# Global physics process tween node
var tw_phys	: Tween

#region Singleton functions

# Called when the node enters the tree
func _enter_tree() -> void:
	# Create the tween nodes
	tw_idle = Tween.new()
	tw_phys = Tween.new()

	# Set the physics process tween node process mode
	tw_phys.playback_process_mode = Tween.TWEEN_PROCESS_PHYSICS

	# Add both nodes as children
	add_child(tw_idle)
	add_child(tw_phys)

#endregion Singleton functions

#region Utility functions

# Checks if the node is a component
func is_component(node: CanvasItem) -> bool:
	return node.get("__component_data") is ComponentData

# Initializes a node as a reactive component
func component_init(node: CanvasItem) -> void:
	# Checks for crucial methods and variables
	assert("__component_data" in node, "Node doesn't have a variable called '__component_data'")
	assert(node.has_method("component_render"), "Node doesn't have a method called 'component_render'")

	# Create a new data for the node
	var data    := ComponentData.new()

	# Add the data
	node.__component_data = data

	# Call the component start method
	if node.has_method("component_start"):
		node.call("component_start")

	# Render the first time
	_component_render(node)

	# Connect the VisualServer's 'frame_pre_draw' signal
	VisualServer.connect("frame_pre_draw", self, "_component_render", [node])

# Deinitializes the node as a reactive component
func component_deinit(node: CanvasItem) -> void:
	# Disconnect the VisualServer's 'frame_pre_draw' signal
	VisualServer.disconnect("frame_pre_draw", self, "_component_render")

# Get the component's state
func component_get_state(comp: CanvasItem) -> Dictionary:
	# Checks if is component
	assert(is_component(comp), "Node isn't a component, call 'component_init' to initialize as a component")

	# Get the component's data
	var data        := comp.__component_data as ComponentData

	# Return from data
	return data.state

# Set the component's state
func component_set_state(comp: CanvasItem, state: Dictionary) -> void:
	# Checks if is component
	assert(is_component(comp), "Node isn't a component, call 'component_init' to initialize as a component")
	
	# Get the component's data
	var data        := comp.__component_data as ComponentData

	# Get the component's current state
	var curr_state  := data.state

	# For each key set the value
	for k in state.keys():
		curr_state[k] = state[k]
	
	# Mark the component as dirty
	data.dirty = true

# Create a new property animation
func do_tween() -> PropertyTween:
	return PropertyTween.new()

#endregion Utility functions

#region Internal functions

# Render the component, called from the VisualServer before rendering the Viewport
func _component_render(comp: CanvasItem) -> void:
	# Get the component's data
	var data        := comp.__component_data as ComponentData

	# If not dirty, return
	if !data.dirty: return

	# If not on tree, return
	if !comp.is_inside_tree(): return

	# Get the render state
	var render      := comp.component_render() as Dictionary

	# Get the previous render state
	var prev_render := data.previous_render

	# Render the tree
	_recursive_tree_update(comp, comp, prev_render, render)

	# Set dirty flag to false
	data.dirty = false

	# Set previous render state
	data.previous_render = render

# Recursively add/update nodes in the SceneTree relative to the component
func _recursive_tree_update(comp: CanvasItem, parent: CanvasItem, prev: Dictionary, curr: Dictionary) -> void:
	# For each node id
	for id in curr.keys():
		# Get current node data
		var curr_node_data  := curr[id] as Dictionary

		# Get previous node data
		var prev_node_data  := prev.get(id, {}) as Dictionary

		# The rendered node
		var node: CanvasItem

		# Node is new
		if prev_node_data.empty():
			# Create a new node
			node    = curr_node_data.type.new()

			# Set the node's properties
			_update_node_properties(comp, node, {}, curr_node_data.get("props", {}))

			# Add it to the parent
			parent.add_child(node, true)
		# Node already exists
		else:
			# Current node type can't be different type
			assert(curr_node_data.type == prev_node_data.type, "Current node's type can't be different from the previous node's type for the id '%s'" % [id])

			# Get the from the previous render
			node = prev_node_data.node

			# Set the node's properties
			_update_node_properties(comp, node, prev_node_data.get("props", {}), curr_node_data.get("props", {}))
		
		# Add the node to the current render, so it can be used for the next render
		curr_node_data.node = node

		# Recursively update the tree from the children's data
		_recursive_tree_update(comp, node, prev_node_data.get("children", {}), curr_node_data.get("children", {}))

# Update the node properties
func _update_node_properties(comp: CanvasItem, node: CanvasItem, prev: Dictionary, curr: Dictionary) -> void:
	# For each property key as prop name
	for prop_name in curr.keys():
		# Get current value
		var curr_value = curr[prop_name]

		# Get previous value
		var prev_value = prev.get(prop_name)

		# Property is a signal
		if prop_name.begins_with("on_"):
			# Set signal
			_set_node_signal(comp, node, prop_name.substr(3), curr_value)
		# Simple property
		else:
			_set_node_prop(comp, node, prop_name, prev_value, curr_value)

# Set node property
func _set_node_prop(
	comp: CanvasItem, node: CanvasItem, prop_name: String, 
	prev_value, curr_value
) -> void:
	# The value didn't change, so return
	if curr_value == prev_value: return

	# Current value is animation
	if curr_value is PropertyTween:
		# Force stop previous animation
		tw_idle.remove(node, prop_name)

		# Animate
		curr_value._animate(tw_idle, prop_name, node)
	else:
		# Simple property, so set as indexed
		node.set_indexed(prop_name, curr_value)

# Set node signal
func _set_node_signal(
	comp: CanvasItem, node: CanvasItem, signal_name: String, 
	curr_params: Dictionary
) -> void:    
	# The target method
	var target_method   := curr_params.target_method as String

	# The connection bindings
	var binds           := curr_params.get("binds", []) as Array

	# The connection flags
	var flags           := curr_params.get("flags", 0) as int

	# If already connected, disconnect first
	if node.is_connected(signal_name, comp, target_method):
		node.disconnect(signal_name, comp, target_method)
	
	# Connect the signal
	node.connect(signal_name, comp, target_method, binds, flags)

#endregion Internal functions




