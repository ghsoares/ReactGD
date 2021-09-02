extends Node
class_name ReactGDComponent

# Some "private" variables, but as Godot don't
# have access modifiers so it's needed to prefix
# with `_` to tell this variable is private, so
# don't touch these.
# Cached nodes stores the instantiated nodes,
# so there is no need to re-instantiate then when
# rendering the same node again
var _cached_nodes: Dictionary
# Current tree state stores the tree state that can
# be used to compare difference between two renders
var _current_tree_state: Dictionary
# Parent component stores the component that instantiated
# this component, so in case of root components of a UI this
# will be null
var _parent_component: Node
# Dirty boolean says if the node needs to render again,
# in case of a prop or state change
var _dirty: bool

# State variable, store the actual state of the node,
# can be accessed from custom components
var state: Dictionary
# Props variable, store the props passed from another component,
# can be accessed from custom components
var props: Dictionary

"""
Init function, sets the initial variables
"""
func _init() -> void:
	_cached_nodes = {}
	_current_tree_state = {}
	
	state = {}
	props = {}

"""
Ready function, calls the component constructor
"""
func _ready() -> void:
	construct()

"""
Enter tree function, queries the component to render
"""
func _enter_tree() -> void:
	_dirty = true

"""
Exit tree function, removes the cached nodes
"""
func _exit_tree() -> void:
	var first: Node = _cached_nodes.values()[0]
	first.get_parent().remove_child(first)
	first.queue_free()

"""
Process function, call `_render_process` if need to render
"""
func _process(delta: float) -> void:
	if _dirty:
		var start := OS.get_ticks_usec()
		_render_process()
		_dirty = false
		var elapsed = OS.get_ticks_usec() - start
		elapsed /= 1000.0
		print("(" + name + ") Render: " + str(elapsed) + " ms")

"""
Main render process function, will be called when this component needs to update.
Takes the new render, build the node tree, set the properties and add nodes when needed
"""
func _render_process() -> void:
	# Uses another class to render the tree 
	# for readability purposes only
	var tree_builder := ReactGDTreeBuilder.new()
	tree_builder.root_component = self
	tree_builder.cached_nodes = _cached_nodes
	
	# Get the new render state
	var new_render: Dictionary = render()
	assert(not new_render.empty(), "Component redered nothing")
	# Get the new tree state builded from the render
	var tree_state: Dictionary = tree_builder.create_node(new_render, "")
	
	if _parent_component == null:
		# This is the root component, so render the nodes as children of this component
		tree_builder.update_node(
			 self, 0,
			_current_tree_state, tree_state
		)
	else:
		# This component was added by a parent component, so render the nodes as children
		# of the parent node with the index being the index of this component + 1.
		# The reason why is that if we add these nodes as children of this component,
		# but the parent node is a container, the container will not affect the rendered
		# nodes, so we add then as children of the container instead.
		tree_builder.update_node(
			get_parent(), get_index() + 1,
			_current_tree_state, tree_state
		)
	
	# Set the current tree state as the new tree state
	_current_tree_state = tree_state

"""
Component constructor function, called on ready
"""
func construct() -> void: pass

"""
Set state function, called when the component want to change the current state.
Sets only the provided keys of the state and queries the component to render.
"""
func set_state(new_state: Dictionary) -> void:
	for key in new_state.keys():
		state[key] = new_state[key]
	_dirty = true

"""
Create style function.
Can take a Array of Dictionaries or just a Dictionary, use Array if you want
to define a default style and just override some properties of the style
"""
func create_style(styles_data) -> Dictionary:
	var complete_data := {}
	if styles_data is Array:
		# Merges all the styles properties into a single data
		for data in styles_data:
			for key in data.keys():
				complete_data[key] = data[key]
	elif styles_data is Dictionary:
		complete_data = styles_data
	else:
		assert(false, "Style data type is invalid, use Array or Dictionary")
	
	# In case style data is empty, just return a StyleBoxEmpty
	if complete_data.empty():
		return {
			"type": StyleBoxEmpty,
			"props": {}
		}
	
	# Creates a dictionary with the props compiled, like transitions,
	# shorthands, etc.
	var style := {
		"type": complete_data.type,
		"props": {}
	}
	
	# Handles all the properties and useful shorthands
	for prop_name in complete_data.keys():
		if prop_name == "type": continue
		var prop_value = complete_data[prop_name]
		
		match prop_name:
			# Border width shorthands
			"border_width":
				for p in ["_left", "_right", "_top", "_bottom"]:
					style.props["border_width" + p] = prop_value
			"border_width_horizontal":
				for p in ["_left", "_right"]:
					style.props["border_width" + p] = prop_value
			"border_width_vertical":
				for p in ["_top", "_bottom"]:
					style.props["border_width" + p] = prop_value
			
			# Corner radius shorthands
			"corner_radius":
				for p in ["_top_left", "_top_right", "_bottom_left", "_bottom_right"]:
					style.props["corner_radius" + p] = prop_value
			"corner_radius_top":
				for p in ["_top_left", "_top_right"]:
					style.props["corner_radius" + p] = prop_value
			"corner_radius_bottom":
				for p in ["_top_left", "_top_right"]:
					style.props["corner_radius" + p] = prop_value
			"corner_radius_left":
				for p in ["_top_left", "_bottom_left"]:
					style.props["corner_radius" + p] = prop_value
			"corner_radius_right":
				for p in ["_top_right", "_bottom_right"]:
					style.props["corner_radius" + p] = prop_value
			
			# Expand margin shorthands
			"expand_margin":
				for p in ["_left", "_right", "_top", "_bottom"]:
					style.props["expand_margin" + p] = prop_value
			"expand_margin_horizontal":
				for p in ["_left", "_right"]:
					style.props["expand_margin" + p] = prop_value
			"expand_margin_vertical":
				for p in ["_top", "_bottom"]:
					style.props["expand_margin" + p] = prop_value
			
			# Content margin shorthands
			"content_margin":
				for p in ["_left", "_right", "_top", "_bottom"]:
					style.props["content_margin" + p] = prop_value
			"content_margin_horizontal":
				for p in ["_left", "_right"]:
					style.props["content_margin" + p] = prop_value
			"content_margin_vertical":
				for p in ["_top", "_bottom"]:
					style.props["content_margin" + p] = prop_value
			
			# Default props
			_:
				style.props[prop_name] = prop_value
	
	return style

"""
Create font function.
Can take a Array of Dictionaries or just a Dicionary, use Array if you want
to define a default font and just override some properties of the font
"""
func create_font(fonts_data) -> Dictionary:
	var complete_data := {}
	if fonts_data is Array:
		# Merges all the styles properties into a single data
		for data in fonts_data:
			for key in data.keys():
				complete_data[key] = data[key]
	elif fonts_data is Dictionary:
		complete_data = fonts_data
	else:
		assert(false, "Font data type is invalid, use Array or Dictionary")
	
	# Creates a dictionary with the props compiled, like transitions,
	# shorthands, etc.
	var font := {
		"src": complete_data.src,
		"font_antialiased": complete_data.get("font_antialiased", true),
		"font_hinting": complete_data.get("font_hinting", DynamicFontData.HINTING_NORMAL),
		"props": {}
	}
	
	# Handles all the properties and useful shorthands
	for prop_name in complete_data.keys():
		if prop_name == "type": continue
		var prop_value = complete_data[prop_name]
		
		font.props[prop_name] = prop_value
	
	return font

"""
Main render function, will be overrided by other component scripts
"""
func render() -> Dictionary: return {}

"""
get_string override function, returns class_name
"""
func get_class() -> String: return "ReactGDComponent"




