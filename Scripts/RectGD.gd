extends Reference
class_name ReactGD

# Renders the component using object
static func _render_component(comp: Node) -> void:
	# Get the render object
	var render  := comp.component_render() as Dictionary

	# Get previous render
	var prev_render := {}
	if comp.has_meta("__REACTGD_PREVIOUS_RENDER"):
		prev_render = comp.get_meta("__REACTGD_PREVIOUS_RENDER")

	# Update the component node tree using the render object
	_update_component_tree(comp, comp, prev_render, render)

	# Set the previous render as meta
	comp.set_meta("__REACTGD_PREVIOUS_RENDER", render)

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

			# Add as child of the parent node
			parent.add_child(node, true)

			# Set the render node reference
			prot.node = node
		# Node isn't new, so just update it
		else:
			# Get the node reference
			node    = prev_prot.node as Node

			# Set the render node reference
			prot.node = node
	
		# Set child index
		parent.move_child(node, idx)

		# Update the properties
		_set_node_properties(comp, node, prot.props)

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
		node.connect(signal_name, comp, method_name, args, flags)

# Initializes this node as a component
static func component_init(comp: Node) -> void:
	# This node don't have some crucial method, throw errors
	assert(comp.has_method("component_render"), "This node don't have a 'component_render' method")
	assert(comp.has_method("component_start"), "This node don't have a 'component_start' method")

	# Set the component's state object
	comp.set_meta("__REACTGD_COMPONENT_STATE", {})

	# Call the start method
	comp.component_start()

	# Render the first time
	_render_component(comp)

	# Set the component's dirty meta as false
	comp.set_meta("__REACTGD_COMPONENT_DIRTY", false)

# Update the component
static func component_update(comp: Node) -> void:
	# Check if the component is dirty
	if comp.get_meta("__REACTGD_COMPONENT_DIRTY"):
		# Render it again
		_render_component(comp)

		# Set the meta as false
		comp.set_meta("__REACTGD_COMPONENT_DIRTY", false)

# Get the component's state
static func component_get_state(comp: Node) -> Dictionary:
	# Return from meta
	return comp.get_meta("__REACTGD_COMPONENT_STATE")

# Set the component's state
static func component_set_state(comp: Node, state: Dictionary) -> void:
	# Get the previous's state object
	var prev_state  := component_get_state(comp)

	# For each new key, add it to the previous state
	for k in state.keys():
		prev_state[k] = state[k]
	
	# Mark the component as dirty
	component_mark_dirty(comp)

# Marks the component as dirty
static func component_mark_dirty(comp: Node) -> void:
	# Set the meta as true
	comp.set_meta("__REACTGD_COMPONENT_DIRTY", true)




