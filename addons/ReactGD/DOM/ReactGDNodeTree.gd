extends Node
class_name ReactGDNodeTree

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
	var prev_type 				= prev.get("type", null)
	var curr_type 				= curr["type"]

	# Get previous and current id
	var prev_id: String			= prev.get("id", "")
	var curr_id: String			= curr["id"]
	
	# Check if the node is new
	var node_is_new: bool 		= prev.empty()

	# Check if the node was removed
	var node_removed: bool		= not prev.empty() and curr.empty()

	# Check if parent is root
	var parent_is_root: bool	= parent == self

	# Check if node is a reactgd node
	var is_reactgd_node: bool	= curr_type.get("__IS_REACTGD_NODE") != null

	# --ADD/REMOVAL--

	# The virtual and real node references
	var node_v: Node
	var node_r: Node

	# The virtual and real node parents
	var parent_v: Node = parent
	var parent_r: Node = base_node

	# This node is new
	if node_is_new:
		# Is a reactgd node
		if is_reactgd_node:
			# Create only the virtual node and set the real node the same as the virtual
			node_v	= curr_type.new()
			node_r 	= node_v

			# If parent isn't root, get the real parent from the virtual parent
			if not parent_is_root:
				parent_r = parent_v.parent_r
		# Is a simple node
		else:
			# Create a virtual node
			node_v	= ReactGDNode.new()

			# Create the real node
			node_r	= curr_type.new()

			# If parent isn't root, get the real parent as the real node of the virtual parent
			if not parent_is_root:
				parent_r = parent_v.prev_tree_data.node_r

		# Add the virtual node
		parent_v.add_child(node_v)

		# Add the real node if isn't a reactgd node
		if not is_reactgd_node:
			parent_r.add_child(node_r)
	# This node was removed
	elif node_removed:
		assert(false, "Node removal not implemented!")
	# This node isn't new
	else:
		node_v	= prev["node_v"]
		node_r	= prev["node_r"]
	
	# Set the node references
	prev["node_v"] = node_v
	prev["node_r"] = node_r
	curr["node_v"] = node_v
	curr["node_r"] = node_r

	# --CHILDREN--
	
	# Get previous and current children
	var prev_children: Dictionary	= prev.get("children", {})
	var curr_children: Dictionary	= curr.get("children", {})

	
