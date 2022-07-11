extends ReactGDNode
class_name ReactGDVirtualNodeTree

# Initialize the node tree
func _init(root: Node) -> void:
	# Set self name
	self.name = "ReactGDVirtualNodeTree"

	# Set root to self
	self.__root = self

	# Set actual node to self
	self.__node = self

	# Set actual parent
	self.__parent = root

# Internal function to render a data on a node
func __render(
	vparent: ReactGDNode,
	parent: Node,
	vindex: int,
	index: int,
	prev: Dictionary,
	next: Dictionary
) -> void:
	# Get the previous and next type
	var prev_type 	= prev.get("type", null)
	var next_type	= next.get("type", null)

	# The virtual node reference
	var vnode: ReactGDNode

	# Node is new
	if not prev_type:
		# Create the actual node
		var node	:= next_type.new() as Node

		# Node is a react node
		if node is ReactGDNode:
			# Set the virtual node
			vnode = node
		# Node is another node
		else:
			# Create a virtual node
			vnode = ReactGDNode.new()
		
		# Set the actual parent
		vnode.__parent = parent

		# Set the actual node
		vnode.__node = node

		# Set the root
		vnode.__root = vparent.__root

		# Add the virtual node as child of virtual parent
		vparent.add_child(vnode, true)

		# If node and vnode are different, add node as child of actual parent
		if vnode != node:
			parent.add_child(node, true)
		
		# Set the actual node name and virtual node name
		node.name = node.get_class() + "_" + str(index)
		vnode.name = node.name + "_virtual"
	# Node isn't new
	else:
		# Get the node reference
		vnode = prev["virtual_node"]
	
	# Check if actual node is virtual
	var is_virtual	:= vnode == vnode.__node

	# Move the virtual node
	vparent.move_child(vnode, vindex)

	# Move the actual node if isn't virtual
	if not is_virtual:
		parent.move_child(vnode.__node, index)

	# Set the next render data node reference
	next["virtual_node"] = vnode

	# Set the virtual node render data
	vnode.__render_data = next

	# Get the previous children
	var prev_children	:= prev.get("children", {}) as Dictionary

	# Get the next children
	var next_children	:= next.get("children", {}) as Dictionary

	# For each previous children
	for ck in prev_children:
		# Get the previous and next child
		var prev_child	:= prev_children[ck] as Dictionary
		var next_child	:= next_children.get(ck, {}) as Dictionary

		# Deleted
		if not next_child:
			# Get the node reference
			var c	:= prev_child["virtual_node"] as ReactGDNode

			# Queue free the actual node
			c.__node.queue_free()

			# Queue free the virtual node
			if c.__node != c:
				c.queue_free()

	# The actual child index
	var idx		:= 0

	# The virtual child index
	var vidx	:= 0

	# For each new children
	for ck in next_children:
		# Get the previous and next child
		var prev_child	:= prev_children.get(ck, {}) as Dictionary
		var next_child	:= next_children[ck] as Dictionary

		# Current node is virtual
		if is_virtual:
			# Continue rendering in the virtual tree but in the actual parent
			__render(vnode, parent, vidx, index, prev_child, next_child)

			# Increment virtual index
			vidx	+= 1
		# Current node is simple
		else:
			# Continue rendering in the virtual tree and in the actual parent
			__render(vnode, vnode.__node, vidx, idx, prev_child, next_child)

			# Increment actual and virtual index
			idx 	+= 1
			vidx 	+= 1

	# Set virtual node dirty as false
	vnode.__dirty = false

	# Set virtual parent render data
	vnode.__render_data = next

# Render the tree
func render(render_data: Dictionary) -> void:
	# Kick-start the rendering
	__render(self, __parent, 0, 0, __render_data, render_data)

	# Set the previous render
	__render_data = render_data

	# Set dirty as false
	__dirty = false




