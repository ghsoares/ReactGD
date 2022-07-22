tool
extends Node

# Meta key used for setting the component reference
const __COMPONENT_REF_KEY = "__REACTGD_COMPONENT_REFERENCE"

# Check if node already is a component
func is_component(node: Node) -> bool:
	return node.has_meta(__COMPONENT_REF_KEY)

# Initializes a node as a component
func component_init(node: Node) -> void:
	# Asserts that this node is a valid component
	assert(node.has_method("_render"), "The component must have a \"_render\" function")

	# Creates the reactgd component
	var component	:= ReactGDComponent.new()

	# Set the node reference
	component.node_ref = weakref(node)

	# Set the key in node to contain this component
	node.set_meta(__COMPONENT_REF_KEY, component)

	# Add as child of self
	add_child(component)

	# Connect signals
	node.connect("tree_entered", self, "_on_component_enter_tree", [node])
	node.connect("tree_exited", self, "_on_component_exit_tree", [node])

# Deinitializes a node as a component
func component_deinit(node: Node) -> void:
	# Remove the key from node
	node.remove_meta(__COMPONENT_REF_KEY)

	# Disconnect signals
	node.disconnect("tree_entered", self, "_on_component_enter_tree")
	node.disconnect("tree_exited", self, "_on_component_exit_tree")

# Get the state of the component
func component_get_state(node: Node) -> Dictionary:
	return node.get_meta(__COMPONENT_REF_KEY).state

# Set the state of the component
func component_set_state(node: Node, new_state: Dictionary) -> void:
	node.get_meta(__COMPONENT_REF_KEY).set_state(new_state)

# Trigger a event for the component
func component_trigger_event(node: Node, event: String, data = null) -> void:
	node.get_meta(__COMPONENT_REF_KEY).trigger_event(event, data)

# Get event from component
func component_get_event(node: Node, event: String):
	return node.get_meta(__COMPONENT_REF_KEY).events.get(event, false)

# Mark the component as dirty
func component_mark_dirty(node: Node) -> void:
	node.get_meta(__COMPONENT_REF_KEY).dirty = true

# Creates a render data properly formated for the ReactGDComponent rendering
func create_node(from: Dictionary) -> Dictionary:
	# Get the signals
	var signals: Dictionary = from.get("signals", {})

	# For each signal key
	for k in signals:
		# Get the signal value
		var sig = signals[k]

		# Signal is a string
		if sig is String:
			# Set the signal data
			sig = {
				"target_method": sig
			}

		# Set the signal value
		signals[k] = sig

	# Set the signals
	from.signals = signals

	# Get the children
	var children = from.get("children", {})

	# Children is a array
	if children is Array:
		# Create a dictionary of children
		var children_d	:= {}

		# The child index
		var idx	:= 0

		# For each child
		for c in children:
			# Get the child key
			var k = str(c.get("key", idx))
			c.key = k

			assert(not children_d.has(k), "Key \"%s\" is duplicate" % k)

			# Set the child in the dictionary
			children_d[k] = c

			# Increment index
			idx += 1

		# Set the children to the dictionary
		children = children_d

	# Set the children
	from.children = children

	return from

# Creates a teme
func create_teme() -> ReactGDTheme:
	return ReactGDTheme.new()

# Creates a tween
func tween() -> ReactGDTween:
	return ReactGDTween.new()

# Called when a component enters the tree
func _on_component_enter_tree(node: Node) -> void:
	
	pass

# Called when a component exits the tree
func _on_component_exit_tree(node: Node) -> void:
	component_deinit(node)


