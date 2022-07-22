extends Node
class_name ReactGDComponent

# Value used for undefined values
const UNDEFINED	:= {}

# The node reference
var node_ref: WeakRef

# The actual node
var node: Node

# This component state
var state: Dictionary

# Events that triggered re-rendering
var events: Dictionary

# Current render data
var render_data: Dictionary

# This component is dirty
var dirty: bool

# Construct this component
func _init() -> void:
	self.state = {}
	self.events = {}
	self.render_data = {}
	self.dirty = true

# Called to process this component
func _process(delta: float) -> void:
	# Get the node reference
	node = node_ref.get_ref()

	# If node is null, queue free self
	if not node:
		queue_free()
		return

	# Check if is dirty
	if not dirty: return

	# Mark as not dirty
	dirty = false

	# The start of the rendering
	var start	:= OS.get_ticks_msec()

	# Get the new render data
	var render: Dictionary = node._render()

	# Check if render data is empty
	if render.type is String and render.type == "empty":
		# Get the previous and next children
		var prev_children: Dictionary = render_data.get("children", {})
		var next_children: Dictionary = render.get("children", {})

		# Current child index
		var idx	:= 0

		# For each previous child
		for k in prev_children.keys():
			# Get previous and next child
			var prev_child: Dictionary = prev_children[k]
			var next_child: Dictionary = next_children.get(k, UNDEFINED)

			# Child was removed
			if next_child == UNDEFINED:
				# Update as removed
				__update_tree(node, 0, prev_child, next_child)

		# For each next children
		for k in next_children:
			# Get previous and next child
			var prev_child: Dictionary = prev_children.get(k, {})
			var next_child: Dictionary = next_children[k]

			# Update the tree
			__update_tree(node, idx, prev_child, next_child)

			# Set previous child
			prev_children[k] = prev_child

			# Increment index
			idx += 1

		# Set the previous children
		render_data.children = prev_children

		# Set the previous data type
		render_data.type = "empty"
	else:
		# Update the render data
		__update_tree(node, 0, render_data, render)
	
	# Clear the events
	events.clear()

	# The elapsed time
	var elapsed	:= OS.get_ticks_msec() - start

	# Print elapsed render time
	print("[%s:%d render]: %d ms elapsed" % [node.name, node.get_instance_id(), elapsed])

# Internal method to update tree from a point
func __update_tree(
	parent: Node,
	idx: int,
	prev: Dictionary,
	next: Dictionary
) -> void:
	# Get previous and next type
	var prev_type	= prev.get("type")
	var next_type	= next.type

	# Get previous and next reference variable name
	var prev_ref: String 	= prev.get("ref", "")
	var next_ref: String 	= next.get("ref", "")

	# Get previous and next key
	var prev_key: String	= prev.get("key", "")
	var next_key: String	= next.get("key", "")

	# Set previous type
	prev.type = next_type

	# Set previous reference variable name
	prev.ref = next_ref

	# Set previous key
	prev.key = next_key
	
	# Check if the node is new
	var node_is_new: bool = prev_type == null and next_type != null

	# Check if the node were removed
	var node_removed: bool = prev_type != null and next_type == null

	# Check if the node type changed
	var node_type_changed: bool = not node_is_new and (typeof(prev_type) != typeof(next_type) or prev_type != next_type) 

	# The node reference
	var n: Node

	# The default node reference
	var dn: Node

	# The node is new
	if node_is_new or node_type_changed:
		# Node type changed, so queue free previous nodes
		if node_type_changed:
			# Remove from parent first
			parent.remove_child(prev.node)

			# Queue free the node
			prev.node.queue_free()
			prev.default_node.queue_free()
		
		# Create the node
		n = next_type.new()
		
		# Create the default node
		dn = next_type.new()

		# Add as child of parent
		parent.add_child(n, true)

		# Set reference
		if next_ref:
			self.node.set_indexed(next_ref, n)
		
		# Reset properties
		prev.props = {}
		prev.signals = {}
		prev.children = {}
	# Node were removed
	elif node_removed:
		# Remove from parent first
		parent.remove_child(prev.node)

		# Queue free the node
		prev.node.queue_free()
		prev.default_node.queue_free()

		# Has reference variable
		if prev_ref:
			# Set reference to null
			self.node.set_indexed(prev_ref, null)

		return
	# The node isn't new
	else:
		# Get the node reference
		n = prev.node

		# Get the default node reference
		dn = prev.default_node

	# Reference variable changed
	if prev_ref != next_ref:
		# Set reference
		if next_ref:
			self.node.set_indexed(next_ref, n)

	# Check if node is a component
	var is_component: bool = ReactGD.is_component(n)

	# Set the node references
	prev.node = n
	prev.default_node = dn

	# Move the node
	parent.move_child(n, idx)

	# Get previous and next properties
	var prev_props: Dictionary	= prev.get("props", {})
	var next_props: Dictionary	= next.get("props", {})

	# Update the properties
	var props_changed	:= __update_props(n, dn, prev_props, next_props)

	# If properties changed and node is a component, mark the component as dirty
	if props_changed and is_component:
		ReactGD.component_mark_dirty(n)

	# Set previous properties
	prev.props = prev_props

	# Get previous and next signals
	var prev_signals: Dictionary = prev.get("signals", {})
	var next_signals: Dictionary = next.get("signals", {})

	# Update the signals
	__update_signals(n, prev_signals, next_signals)

	# Set previous signals
	prev.signals = prev_signals

	# Get previous and next tween
	var prev_tween: ReactGDTween = prev.get("tween", null)
	var next_tween: ReactGDTween = next.get("tween", null)

	# Check if there's tween
	if next_tween:
		# Check if tween were created
		# if not prev_tween:
		# Apply tween
		next_tween.apply_tween(n)
		

	# Set previous tween
	prev.tween = next_tween

	# Get previous and next children
	var prev_children: Dictionary = prev.get("children", {})
	var next_children: Dictionary = next.get("children", {})

	# Current child index
	var cidx	:= 0

	# For each previous child
	for k in prev_children.keys():
		# Get previous and next child
		var prev_child: Dictionary = prev_children[k]
		var next_child: Dictionary = next_children.get(k, UNDEFINED)

		# Child was removed
		if next_child == UNDEFINED:
			# Update as removed
			__update_tree(n, 0, prev_child, next_child)

	# For each new child
	for k in next_children:
		# Get previous and next child
		var prev_child: Dictionary = prev_children.get(k, {})
		var next_child: Dictionary = next_children[k]

		# Update the tree
		__update_tree(n, cidx, prev_child, next_child)

		# Set previous child
		prev_children[k] = prev_child

		# Increment index
		cidx += 1

	# Set previous children
	prev.children = prev_children

# Update properties for a node
func __update_props(
	node: Node,
	default: Node,
	prev_props: Dictionary,
	next_props: Dictionary
) -> bool:
	# Variable that tells if a variable changed
	var changed	:= false

	# For each prev property
	for k in prev_props.keys():
		# Get previous and next value
		var prev_value = prev_props[k]
		var next_value = next_props.get(k, UNDEFINED)

		# Check if next value is undefined
		if next_value is Dictionary and next_value == UNDEFINED:
			# Set to default property
			node.set_indexed(k, default.get_indexed(k))

			# Remove previous value
			prev_props.erase(k)

			# Set as changed
			changed = true

	# For each new property
	for k in next_props:
		# Get previous and next value
		var prev_value = prev_props.get(k, UNDEFINED)
		var next_value = next_props[k]

		# Value changed
		if typeof(prev_value) != typeof(next_value) or prev_value != next_value:
			# Set value in node
			node.set_indexed(k, next_value)

			# Set as changed
			changed = true
		
		# Set previous value
		prev_props[k] = next_value

	# Return if any property changed
	return changed

# Update signals for a node
func __update_signals(
	node: Node,
	prev_signals: Dictionary,
	next_signals: Dictionary
) -> void:
	# For each previous signals
	for k in prev_signals.keys():
		# Get previous and next signal
		var prev_sig: Dictionary = prev_signals[k]
		var next_sig: Dictionary = next_signals.get(k, UNDEFINED)

		# Signal removed
		if next_sig == UNDEFINED:
			# Disconnect the signal
			node.disconnect(k, self.node, prev_sig.target_method)

			# Remove the signal
			prev_signals.erase(k)
	
	# For each new signal
	for k in next_signals:
		# Get previous and next signal
		var prev_sig: Dictionary = prev_signals.get(k, UNDEFINED)
		var next_sig: Dictionary = next_signals[k]

		# Signal isn't new
		if prev_sig != UNDEFINED:
			# Get previous and next target method
			var prev_target_method: String = prev_sig.get("target_method", "")
			var next_target_method: String = prev_sig.target_method

			# Get previous and next binds
			var prev_binds: Array = prev_sig.get("binds", [])
			var next_binds: Array = next_sig.get("binds", [])

			# Get previous and next bind node
			var prev_bind_node: bool = prev_sig.get("bind_node", false)
			var next_bind_node: bool = next_sig.get("bind_node", false)

			# Get previous and next flags
			var prev_flags: int = prev_sig.get("flags", 0)
			var next_flags: int = next_sig.get("flags", 0)

			# Target method changed
			if prev_target_method != next_target_method:
				prev_sig = UNDEFINED
			
			# Binds array changed
			elif prev_binds.hash() != next_binds.hash():
				prev_sig = UNDEFINED
			
			# Bind node changed
			elif prev_bind_node != next_bind_node:
				prev_sig = UNDEFINED
			
			# Flags changed
			elif prev_flags != next_flags:
				prev_sig = UNDEFINED
			
			# Signal changed, so disconnect first
			if prev_sig == UNDEFINED:
				# Disconnect the signal
				node.disconnect(k, self.node, prev_target_method)

		# Signal is new
		if prev_sig == UNDEFINED:
			# Get the binds
			var binds: Array = next_sig.get("binds", [])

			# Get if should bind node
			var bind_node: bool = next_sig.get("bind_node", false)

			# Get the flags
			var flags: int = next_sig.get("flags", 0)

			# Get the total binds
			var total_binds: Array = binds

			# Add node reference bind
			if bind_node:
				total_binds = [node] + binds

			# Connect the signal
			node.connect(k, self.node, next_sig.target_method, total_binds, flags)

			# Set the previous signal
			prev_sig = {
				"target_method": next_sig.target_method,
				"binds": binds,
				"bind_node": bind_node,
				"flags": flags
			}

		# Set the signal
		prev_signals[k] = prev_sig

# Set the state of this component
func set_state(new_state: Dictionary) -> void:
	# For each new property, set the property in this state
	for k in new_state:
		state[k] = new_state[k]
	
	# Mark as dirty
	dirty = true

	# Add state change event
	events["state_changed"] = true

# Trigger a event for this component
func trigger_event(event: String, data = null) -> void:
	# Add the event
	events[event] = data if data != null else true

	# Mark as dirty
	dirty = true

