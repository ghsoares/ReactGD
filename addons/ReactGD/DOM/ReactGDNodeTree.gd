extends Node
class_name ReactGDNodeTree

"""
Step 1:
	Prev:
	{}

	Next:
	{
		'id': 'root',
		'type': VBoxContainer,
		'children': {}
	}
Step 2:
	Prev:
	{
		'id': 'root',
		'type': VBoxContainer,
		'children': {}
	}
"""

# The base node to render the tree
var base_node: Node

# Nodes queried to update
var queried_nodes: Array

# Previous tree data
var prev_tree_data: Dictionary

# Current tree data
var curr_tree_data: Dictionary

# Called when the node initializes
func _init() -> void:
	# Set the name
	name = "ReactGDNodeTree"

	# Create the queried nodes array
	queried_nodes = []

	# Set process to true to be able to receive NOTIFICATION_PROCESS
	set_process(true)

# Called when a notification occours
func _notification(what: int) -> void:
	match what:
		# Idle process
		NOTIFICATION_PROCESS:
			__process_tree(get_process_delta_time())

# Sets the base node
func set_base_node(node: Node) -> void:
	base_node = node

# Renders a node data into the root node
func render(root_data: Dictionary) -> void:
	# Validate root data
	__validate(root_data)

	# Set the current node data
	curr_tree_data = root_data

	# Query the tree data to update
	queried_nodes.append({
		"parent": self,
		"prev": prev_tree_data,
		"curr": curr_tree_data
	})

# Internal function to validade a node data
func __validate(data: Dictionary) -> void:
	assert(data.has("type"), 'Data must have a "type" value')
	assert(data.has("id"), 'Data must have a "id" value')

# Internal function called to process the tree
func __process_tree(delta: float) -> void:
	# Check if need to update queried nodes
	if queried_nodes.size() > 0:
		# Get the start time
		var start	:= OS.get_ticks_msec()

		# While number of nodes to update is greater than zero
		while queried_nodes.size() > 0:
			__update_tree()

		# Get the elapsed time
		var elapsed	:= OS.get_ticks_msec() - start

		print("[ReactGDNodeTree update] %s ms elapsed" % [elapsed])

# Internal function called to update tree
func __update_tree() -> void:
	# Get previous queried nodes
	var prev_queried	:= queried_nodes

	# Clear current queried nodes
	queried_nodes = []

	# For each node to update
	for up in prev_queried:
		__update_branch(
			up.parent,
			up.prev, 
			up.curr
		)

# Update the tree at a given branch
func __update_branch(
	parent: Node,
	prev: Dictionary, 
	curr: Dictionary
) -> void:
	# Get previous and current type
	var prev_type 		= prev.get("type", null)
	var curr_type 		= curr["type"]

	# Get previous and current id
	var prev_id: String	= prev.get("id", "")
	var curr_id: String	= curr["id"]
	
	# Check if the node is new
	var node_is_new: bool 		= prev.empty()

	# Check if parent is root
	var parent_is_root: bool	= parent == self

	# Check if node is a component
	var is_component: bool		= false

	# The virtual, real and default node
	var node_v: Node
	var node_r: Node
	var node_d: Node

	# The real parent
	var parent_r: Node

	# The virtual and real child index of this node
	var idx_v	:= 0
	var idx_r	:= 0

	# Parent is self, so set the real parent to the base node
	if parent == self:
		parent_r = base_node
	# Else, find the actual node
	else:
		parent_r = parent.prev_tree_data.node_r

	# Node is new
	if node_is_new:
		# Create the real node
		node_r	= curr_type.new()

		# Create the default node
		node_d 	= curr_type.new()

		# Check if is a component
		is_component = node_r is ReactGDComponent

		# If isn't a component, create the virtual node
		if not is_component:
			# Create the virtual node
			node_v 	= ReactGDNode.new()

			# Set the name
			node_r.name = node_r.get_class() + "_" + curr_id

			# Add the real node as child of real parent node
			parent_r.add_child(node_r, true)
		else:
			# Set the name
			node_r.name = node_r.get_component_name() + "_" + curr_id

			# Set the virtual node as the real node
			node_v = node_r
		
		# Set the root tree node
		node_v.root_tree = self

		# Set the parent node
		node_v.parent = parent

		# Add the virtual node as child of virtual parent node
		parent.add_child(node_v, true)
	# Node isn't new
	else:
		# Assert that ids are equal
		assert(prev_id == curr_id, "Previous node id and current node id are different!")

		# Get the nodes references
		node_v = prev["node_v"]
		node_r = prev["node_r"]
		node_d = prev["node_d"]

	# Set the previous and current tree data
	node_v.prev_tree_data = prev
	node_v.curr_tree_data = curr

	# Set the node references
	prev["node_v"] 		= node_v
	prev["node_r"] 		= node_r
	prev["node_d"] 		= node_d
	curr["node_v"] 		= node_v
	curr["node_r"] 		= node_r
	curr["node_d"] 		= node_d

	# Parent isn't self, so find in parent children index
	if not parent_is_root:
		idx_v 	= parent.curr_tree_data.children.keys().find(curr_id)
		idx_r 	= idx_v

	# Move child
	parent.move_child(node_v, idx_v)
	if not is_component:
		parent_r.move_child(node_r, idx_r)

	# Ensure that the name is the same as the real node
	if not is_component:
		node_v.name = node_r.name + "_virtual"

	# Get the previous and current properties
	var prev_props: Dictionary		= prev.get("props", {})
	var curr_props: Dictionary		= curr.get("props", {})

	# Update properties
	__update_props(node_v, prev_props, curr_props)

	# Set the previous and current data properties
	prev["props"]	= prev_props
	curr["props"]	= curr_props

	# Get the previous and current children
	var prev_children: Dictionary 	= prev.get("children", {})
	var curr_children: Dictionary 	= curr.get("children", {})

	# For each previous child's id
	for k in prev_children:
		# Get the previous and current child
		var prev_child: Dictionary = prev_children[k]
		var curr_child: Dictionary = curr_children.get(k, {})

		# Check if removed
		if curr_child.empty():
			# Queue free this node references
			prev_child.node_r.queue_free()
			prev_child.node_v.queue_free()
			prev_child.node_d.queue_free()
			
			# Erase from children dictionary
			prev_children.erase(k)

	# For each current child's id
	for k in curr_children:
		# Get the previous and current child
		var prev_child: Dictionary = prev_children.get(k, {})
		var curr_child: Dictionary = curr_children[k]

		# Check if child is new
		var child_is_new	:= prev_child.empty()

		# If is new, query this child
		if child_is_new:
			queried_nodes.append({
				"parent": node_v,
				"prev": prev_child,
				"curr": curr_child
			})
		# Else, update further
		else:
			__update_branch(node_v, prev_child, curr_child)
		
		# Set this child in previous children
		prev_children[k] = prev_child

	# Set the previous and current children
	prev["children"] 	= prev_children
	curr["children"] 	= curr_children

	# Set previous id and type
	prev["id"] 			= curr_id
	prev["type"] 		= curr_type

# Update the properties of a node
func __update_props(
	node: Node,
	prev_props: Dictionary,
	curr_props: Dictionary
) -> void:
	# Get real and default node
	var node_r: Node 	= node.prev_tree_data["node_r"]
	var node_d: Node 	= node.prev_tree_data["node_d"]

	# Value used when is undefined
	var undefined		:= {}

	# For each previous properties
	for k in prev_props:
		# Get current value
		var curr_val	= curr_props.get(k, undefined)

		# If is undefined, set to default value
		if curr_val is Dictionary and curr_val == undefined:
			node_r.set_indexed(k, node_d.get_indexed(k))
			prev_props.erase(k)
	
	# For each current properties
	for k in curr_props:
		# Get previous and current value
		var prev_val	= prev_props.get(k, undefined)
		var curr_val	= curr_props[k]

		# Value changed
		if typeof(prev_val) != typeof(curr_val) or prev_val != curr_val:
			# Set to new value
			node_r.set_indexed(k, curr_val)

			# Set the value
			prev_props[k] = curr_val
