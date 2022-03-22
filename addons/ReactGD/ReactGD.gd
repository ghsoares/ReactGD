extends Node
class_name ReactGD

# Global component data
class ComponentData:
	extends Reference

	# Component state
	var state				:= {}

	# Component is dirty
	var dirty				:= false

	# Previous render data
	var prev_render 		:= {}

# Get the component's data
static func _component_data(comp: Node) -> ComponentData:
	return comp.__component_data

# Check if this node is a component
static func _is_component(node: Node) -> bool:
	return "__component_data" in node

# Renders the component using object
static func _render_component(comp: Node) -> void:
	# Get the component's data
	var data		:= _component_data(comp)

	# Get the render object
	var render  	:= comp.component_render() as Dictionary

	# Get previous render
	var prev_render	:= data.prev_render

	# Update the component node tree using the render object
	_update_component_tree(comp, comp, prev_render, render)

	# Set the previous render as current render
	data.prev_render = render

# Update the component node tree
static func _update_component_tree(comp: Node, parent: Node, prev_render: Dictionary, render: Dictionary) -> void:
	# Go for each id in the previous render
	for id in prev_render.keys():
		# Get next prototype
		var prot	:= render.get(id, {}) as Dictionary

		# If is removed from the new render, remove the node
		if prot.empty():
			# Get previous prototype
			var prev_prot	:= prev_render[id] as Dictionary

			# Get the node reference
			var node		:= prev_prot.node as Node

			# Remove from the tree
			parent.remove_child(node)

			# Queue free it
			node.queue_free()

	# Position in the tree
	var idx := 0

	# Go for each id in the render
	for id in render.keys():
		# Get the prototype
		var prot        := render[id] as Dictionary

		# Get the previous prototype
		var prev_prot   := prev_render.get(id, {}) as Dictionary

		# The node
		var node        : Node

		# Node is new
		if prev_prot.empty():
			# Get the render node type
			var type    = prot.type

			# Create the node
			node        = type.new() as Node

			# Set the properties
			_set_node_properties(comp, node, prot.props)

			# Add as child of the parent node
			parent.add_child(node, true)

			# Set the render node reference
			prot.node = node
		# Node isn't new, so just update it
		else:
			# Get the node reference
			node    = prev_prot.node as Node

			# Update the properties
			_set_node_properties(comp, node, prot.props)

			# Mark as dirty, if is a component
			if _is_component(node):
				component_mark_dirty(node)

			# Set the render node reference
			prot.node = node
		
		# Set child index
		parent.move_child(node, idx)

		# Get the children
		var children        := prot.get("children", {}) as Dictionary

		# Get the previous children
		var prev_children   := prev_prot.get("children", {}) as Dictionary

		# Render children
		_update_component_tree(comp, node, prev_children, children)

		# Increment index
		idx += 1

# Set the node properties using the props dictionary
static func _set_node_properties(comp: Node, node: Node, props: Dictionary) -> void:
	# Go for each key
	for k in props.keys():
		# Property is a signal
		if k.begins_with("on_"):
			_update_signal_connection(comp, node, k.substr(3), props[k])
		# Set the node property
		else:
			node.set_indexed(k, props[k])
	
# Update node connection
static func _update_signal_connection(comp: Node, node: Node, signal_name: String, args) -> void:
	# Args is only a string
	if args is String:
		_update_signal_connection_full(comp, node, signal_name, args, [], 0)
	# Args is a dictionary
	elif args is Dictionary:
		_update_signal_connection_full(
			comp, node, signal_name,
			args.get("method"), args.get("args", []),
			args.get("flags", 0)
		)

# Update node connection with all arguments
static func _update_signal_connection_full(
	comp: Node, node: Node, signal_name: String,
	method_name: String, args: Array, flags: int
) -> void:
	# Isn't connected
	if !node.is_connected(signal_name, comp, method_name):
		# Connect the signal
		# warning-ignore: RETURN_VALUE_DISCARDED
		node.connect(signal_name, comp, method_name, args, flags)

# Initializes this node as a component
static func component_init(node: Node) -> void:
	# This node don't have some crucial methods, throw errors
	assert(node.has_method("component_render"), "This node don't have a 'component_render' method")
	assert(node.has_method("component_start"), "This node don't have a 'component_start' method")

	# This node don't have data variable, throw error
	assert("__component_data" in node, "This node don't have a variable called '__component_data'")

	# Create a new component's data
	var data	:= ComponentData.new()

	# Set the node's variable to new data
	node.__component_data = data

	# Call the start method
	node.component_start()

	# Render the first time
	_render_component(node)

	# Set the component's dirty data as false
	data.dirty = true

# Update the component
static func component_update(comp: Node) -> void:
	# If node isn't a component, throw error
	assert(_is_component(comp), "This node isn't a component")

	# Get the component's data
	var data	:= _component_data(comp)

	# Check if the component is dirty
	if data.dirty:
		# Render it again
		_render_component(comp)

		# Set the data dirty as false
		data.dirty

# Get the component's state
static func component_get_state(comp: Node) -> Dictionary:
	# If node isn't a component, throw error
	assert(_is_component(comp), "This node isn't a component")

	# Get the component's data
	var data	:= _component_data(comp)

	# Return from data
	return data.state

# Set the component's state
static func component_set_state(comp: Node, state: Dictionary) -> void:
	# If node isn't a component, throw error
	assert(_is_component(comp), "This node isn't a component")

	# Get the component's data
	var data	:= _component_data(comp)

	# Get the previous's state object
	var prev_state  := data.state

	# For each new key, add it to the previous state
	for k in state.keys():
		prev_state[k] = state[k]
	
	# Mark the component as dirty
	data.dirty = true

# Marks the component as dirty
static func component_mark_dirty(comp: Node) -> void:
	# If node isn't a component, throw error
	assert(_is_component(comp), "This node isn't a component")

	# Get the component's data
	var data	:= _component_data(comp)

	# Set the data dirty as true
	data.dirty = true




