extends Node

class_name ReactGDTreeBuilder

# Relevant data from component
var cached_nodes: Dictionary
var root_component: Node

"""
Create node function
This function takes a node data, current cached nodes dictionary and path.
cached_nodes is provided by the ReactGDComponent, it stores already created node
for a id, without the need to remove all the children of the tree and add then
again.
"""
func create_node(node_data: Dictionary, path: String) -> Dictionary:
	# Grab all the relevant data
	var node_id: String = node_data.id
	var node_props: Dictionary = node_data.props
	var node_children: Array = node_props.children
	var node_cached_path: String = path + node_id
	var node_type = node_data.type
	
	# Creates the node container
	var node: Dictionary = {}
	
	# This node is new, so add it to cached nodes
	if not cached_nodes.has(node_cached_path):
		# First we create the container, creating the instance after the provided type
		node = {
			"id": node_id,
			"instance": node_type.new(),
			"props": node_props,
			"cached_path": node_cached_path
		}
		# Then store the instance in the cached nodes in the path
		cached_nodes[node_cached_path] = node.instance
	# This node exists, so just grab the instance
	else:
		node = {
			"id": node_id,
			"instance": cached_nodes[node_cached_path],
			"props": node_props,
			"cached_path": node_cached_path
		}
	
	# Convert the children from Array to Dictionary,
	# makes tree difference easier when updating the node
	node_props.children = {}
	
	# This node has children, so create then too
	if not node_children.empty():
		for child_data in node_children:
			node_props.children[child_data.id] = create_node(child_data, node_cached_path)
	
	return node

"""
Update node function
This function takes the root component, parent node, instance child index,
previous node state and current node state.
The node is then removed if needed, update the props and add it if needed.
"""
func update_node(
	parent_node: Node, idx: int,
	prev_node_state: Dictionary, node_state: Dictionary
) -> void:
	# Both states are empty, abort
	if prev_node_state.empty() and node_state.empty(): return
	
	# Get the previous relevant data.
	# As previous data may be empty, so we use `get` with default
	# parameter to avoid errors
	var prev_instance: Node = prev_node_state.get("instance", null)
	var prev_props: Dictionary = prev_node_state.get("props", {})
	var prev_children: Dictionary = prev_props.get("children", {})
	var prev_instance_is_component: bool = prev_instance and prev_instance.get_class() == "ReactGDComponent"
	
	# The node was removed, so just remove it before going further
	if node_state.empty():
		# Remove this node from the tree
		parent_node.remove_child(prev_instance)
		
		# Remove it's registry from the cached nodes
		cached_nodes.erase(prev_node_state.cached_path)
		
		# Remove previous children
		for child_id in prev_children.keys():
			var child: Dictionary = prev_children[child_id]
			# If the current instance is a component,
			# the node must be removed from the instance parent,
			# else the node must be removed from the instance node
			if prev_instance_is_component:
				update_node(parent_node, -1, child, {})
			else:
				update_node(prev_instance, -1, child, {})
		
		# Queue free it from the free
		prev_instance.queue_free()
		return
	
	# Get the current relevant data.
	var current_instance: Node = node_state.instance
	var current_props: Dictionary = node_state.props
	var current_children: Dictionary = current_props.children
	var instance_is_component: bool = current_instance and current_instance.get_class() == "ReactGDComponent"
	
	# Update the props
	var props_changed := update_node_props(
		root_component, node_state.instance,
		prev_node_state.get("props", {}), node_state.props
	)
	# If the props has changed and the instance node
	# is a component, query it to render
	if instance_is_component and props_changed:
		current_instance._dirty = true
	
	# The node was added
	if prev_node_state.empty():
		parent_node.add_child(current_instance)
	# This node already exists
	else:
		# Update the previous children
		for child_id in prev_children.keys():
			var child: Dictionary = prev_children[child_id]
			# This node was removed
			if not current_children.has(child_id):
				# If the current instance is a component,
				# the node must be removed from the instance parent,
				# else the node must be removed from the instance node
				if instance_is_component:
					update_node(parent_node, -1, child, {})
				else:
					update_node(current_instance, -1, child, {})
	
	# Move the node to the index
	parent_node.move_child(current_instance, idx)
	
	# The node child index, dictates the index position as child of a node
	var node_idx := 0
	for child_id in current_children.keys():
		var child: Dictionary = current_children[child_id]
		# This node was added
		if not prev_children.has(child_id):
			# If the current instance is a component,
			# the node must be added from the instance parent,
			# else the node must be added from the instance node
			if instance_is_component:
				update_node(parent_node, node_idx, {}, child)
			else:
				update_node(current_instance, node_idx, {}, child)
		else:
			# If the current instance is a component,
			# the node must be updated from the instance parent,
			# else the node must be updated from the instance node
			if instance_is_component:
				update_node(parent_node, node_idx, prev_children[child_id], child)
			else:
				update_node(current_instance, node_idx, prev_children[child_id], child)
		
		# This node is a component, jump a node index, because is reserved to the
		# component rendered children
		if child.instance.get_class() == "ReactGDComponent":
			node_idx += 2
		# Else just increment the node index
		else:
			node_idx += 1

"""
Update node props function
This function takes the root component, instance node, previous props and
current props.
The prop set behaviour is different to each prop, specially for component's built-ins
like children, theme, signals, ref, etc.
"""
func update_node_props(
	root_component: Node, node: Node, prev_props: Dictionary,
	props: Dictionary
) -> bool:
	# If the node is a component, just pass the props to the component's
	# `props` variable
	if node.get_class() == "ReactGDComponent":
		# Only return true if the props truly changed,
		# so the component can render
		var changed := false
		for prop_name in props.keys():
			if not prev_props.has(prop_name) or hash(prev_props[prop_name]) != hash(props[prop_name]):
				node.props[prop_name] = props[prop_name]
				changed = true
		return changed
	
	# Pass to each assigned props, signals, themes, ref, etc.
	for prop_name in props.keys():
		var prop_value = props[prop_name]
		
		# Children is ignored for regular nodes,
		# even for custom types, use `get_children` instead
		if prop_name == "children": continue
		# If the prop name begins with `on_`, this means
		# that this prop is a signal
		elif prop_name.begins_with("on_"):
			var signal_name: String = prop_name.substr(3, prop_name.length() - 3)
			if not prev_props.has(prop_name):
				node_update_signal(node, signal_name, null, prop_value)
			else:
				node_update_signal(node, signal_name, prev_props[prop_name], prop_value)
		# If the prop name begins with `style_` this means
		# that this prop is a theme style
		elif prop_name.begins_with("style_"):
			var style_name: String = prop_name.substr(6, prop_name.length() - 6)
			if not prev_props.has(prop_name):
				node_update_style(node, style_name, null, prop_value)
			else:
				node_update_style(node, style_name, prev_props[prop_name], prop_value)
		# If the prop name begins with `font_` this means
		# that this prop is a theme font
		elif prop_name.begins_with("font_") or prop_name == "font":
			var font_name: String = prop_name.substr(5, prop_name.length() - 5)
			if not prev_props.has(prop_name):
				node_update_font(node, font_name, null, prop_value)
			else:
				node_update_font(node, font_name, prev_props[prop_name], prop_value)
		else:
			node_update_prop(node, prop_name, prop_value)
	
	return true

"""
Update the node property.
Some nodes have undesired behaviour on properties changes,
so this function takes care of these behaviours.
"""
func node_update_prop(node: Node, prop_name: String, prop_value) -> void:
	# LineEdit resets the caret position when text is changed
	if node is LineEdit and prop_name == "text":
		var before: int = node.caret_position
		node.text = prop_value
		node.caret_position = before
		return
	
	# Default behaviour, just set the node property
	node.set_indexed(prop_name, prop_value)

"""
Update the node signal.
Compares the previous connection and disconnect if needed.
"""
func node_update_signal(node: Node, signal_name: String, previous_value, current_value) -> void:
	# There was a connection
	if previous_value:
		# Signal connection is different, disconect first
		if not current_value or typeof(previous_value) != typeof(current_value) or\
			hash(previous_value) != hash(current_value):
			
			if previous_value is String:
				node.disconnect(signal_name, root_component, previous_value)
			elif previous_value is Array:
				node.disconnect(signal_name, root_component, previous_value[0])
			elif previous_value is Dictionary:
				node.disconnect(signal_name, root_component, previous_value.target)
		# Connection is the same, return
		else: return
		
		# There is no new connection, don't connect
		if not current_value: return
	
	# Handle the connection
	if current_value is String:
		node.connect(signal_name, root_component, current_value)
	elif current_value is Array:
		if current_value.size() == 1:
			node.connect(signal_name, root_component, current_value[0])
		elif current_value.size() == 2:
			node.connect(signal_name, root_component, current_value[0], current_value[1])
		elif current_value.size() == 3:
			node.connect(signal_name, root_component, current_value[0], current_value[1], current_value[2])
	elif current_value is Dictionary:
		node.connect(
			signal_name, root_component, current_value.target,
			current_value.get("binds", []), current_value.get("flags", 0)
		)

"""
Update the node style.
Add a new style or remove it when needed.
"""
func node_update_style(node: Control, style_name: String, previous_value, current_value) -> void:
	# There is no style
	if not current_value:
		node.add_stylebox_override(style_name, null)
		return
	
	var style: StyleBox = null
	
	# The node already has a style
	if previous_value:
		# The type has changed, instantiate a new one
		if previous_value.type != current_value.type:
			style = current_value.type.new()
			node.add_stylebox_override(style_name, style)
		else:
			style = node.get_stylebox(style_name)
	# The style is new
	else:
		style = current_value.type.new()
		node.add_stylebox_override(style_name, style)
	
	# Go for each property
	var props: Dictionary = current_value.props
	for prop_name in props.keys():
		style.set_indexed(prop_name, props[prop_name])

"""
Update the node font.
Load or remove the font when needed
"""
func node_update_font(node: Control, font_name: String, previous_value, current_value) -> void:
	# There is not font
	if not current_value:
		node.add_font_override(font_name, null)
		return
	
	var font: DynamicFont = null
	
	# The node already has a font loaded
	if previous_value:
		font = node.get_font(font_name)
		# The font data src path has changed, load new one
		if previous_value.src != current_value.src:
			font.font_data = ResourceLoader.load(current_value.src)
	
	# The font is new
	else:
		font = DynamicFont.new()
		font.font_data = ResourceLoader.load(current_value.src)
		node.add_font_override(font_name, font)
	
	# Go for each property
	var props: Dictionary = current_value.props
	for prop_name in props.keys():
		font.set_indexed(prop_name, props[prop_name])









