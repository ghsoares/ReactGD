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
Process function, call `_render_process` if need to render
"""
func _process(delta: float) -> void:
	if _dirty:
		_render_process()
		_dirty = false

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
Set state function, called when the component want to change the current state.
Sets only the provided keys of the state and queries the component to render.
"""
func set_state(new_state: Dictionary) -> void:
	for key in new_state.keys():
		state[key] = new_state[key]
	_dirty = true

"""
Component constructor function, called on ready
"""
func construct() -> void: pass

"""
Main render function, will be overrided by other component scripts
"""
func render() -> Dictionary: return {}

"""
get_string override function, returns class_name
"""
func get_string() -> String: return "ReactGDComponent"




