extends Node

class_name ReactGDComponent

enum DIFF_TYPE {
	DIFF_ADDED = 0,
	DIFF_MODIFIED = 1,
	DIFF_REMOVED = 2,
	DIFF_UNCHANGED = 3
}

var _dirty: bool
var _render_state: Dictionary
var _cached_nodes: Dictionary
var _tw: Tween
var parent_component: Node
var state: Dictionary
var children: Dictionary

func _init() -> void:
	_dirty = true
	_render_state = {}
	_cached_nodes = {}

func _enter_tree() -> void:
	_tw = Tween.new()
	add_child(_tw)
	state = {}
	construct()

func _process(delta: float) -> void:
	if _dirty:
		var start := OS.get_ticks_msec()
		
		_render_process()
		_dirty = false
		
		var elapsed := OS.get_ticks_msec() - start
		print("(", name, ") Render: ", elapsed, " ms")

func _render_process() -> void:
	var new_render = render()
	var new_render_state = _build_component(new_render, "")
	
	if new_render_state.hash() != _render_state.hash():
		var render_diff = ReactGDDictionaryMethods.diff(_render_state, new_render_state)
		if parent_component:
			_update_tree(render_diff, get_parent(), get_index() + 1)
		else:
			_update_tree(render_diff, self, 0)
		
		_render_state = new_render_state

func _build_component(render_state: Dictionary, path: String) -> Dictionary:
	var node :Dictionary = {}
	var cached_path :String = path + render_state.id
	
	if _cached_nodes.has(cached_path):
		node = {
			"cached_path": cached_path,
			"instance": _cached_nodes[cached_path]
		}
	else:
		node = {
			"cached_path": cached_path,
			"instance": render_state.type.new()
		}
		_cached_nodes[cached_path] = node.instance
	
	var props: Dictionary = render_state.get("props", {})
	var children: Dictionary = render_state.get("children", {})
	
	for prop_name in props:
		if props[prop_name] is ReactGDTransition:
			props[prop_name] = {
				"reactgd_transition_data": {
					"frames": props[prop_name]._frames,
					"props": props[prop_name]._props,
					"hash": props[prop_name]._hash
				}
			}
	
	for c in children:
		children[c] = _build_component(children[c], cached_path + "_")
	
	node.props = props
	node.children = children
	return node

func _update_tree(render_diff: Dictionary, parent: Node, index: int) -> void:
	var cached_path: String = render_diff.cached_path.value
	var node_change_type: int = render_diff.instance.change_type
	var node: Node = render_diff.instance.value
	
	if node_change_type != DIFF_TYPE.DIFF_REMOVED:
		var props_change_type: int = render_diff.props.change_type
		var props: Dictionary = render_diff.props.value
		if props_change_type != DIFF_TYPE.DIFF_UNCHANGED:
			_update_node_props(node, props)
			if node.get_class() == "ReactGDComponent":
				node._dirty = true
	
	if node_change_type == DIFF_TYPE.DIFF_ADDED:
		if node.get_class() == "ReactGDComponent":
			node.parent_component = self
		parent.add_child(node, true)
		parent.move_child(node, index)
	elif node_change_type == DIFF_TYPE.DIFF_REMOVED:
		parent.remove_child(node)
		_cached_nodes.erase(cached_path)
		return
	
	var children_change_type: int = render_diff.children.change_type
	var children: Dictionary = render_diff.children.value
	
	if children_change_type != DIFF_TYPE.DIFF_UNCHANGED:
		var child_index := 0
		for c in children.keys():
			var child = children[c]
			
			if child.change_type != DIFF_TYPE.DIFF_UNCHANGED:
				_update_tree(child.value, node, child_index)
				if child.value.instance.value.get_class() == "ReactGDComponent":
					child_index += 1
			else:
				if child.value.instance.get_class() == "ReactGDComponent":
					child_index += 1
			
			child_index += 1

func _update_node_props(node: Node, props: Dictionary) -> void:
	for prop_name in props.keys():
		if props[prop_name].change_type == DIFF_TYPE.DIFF_UNCHANGED: continue
		if prop_name.begins_with("on_"):
			var signal_name = prop_name.substr(3, prop_name.length() - 3)
			if node.has_signal(signal_name):
				_update_node_signal(node, signal_name, props[prop_name])
				continue
		var prop_value = props[prop_name].value
		if prop_value is Dictionary and prop_value.has("reactgd_transition_data"):
			_update_transition(node, prop_name, prop_value["reactgd_transition_data"])
			continue
		node.set_indexed(prop_name, prop_value)

func _update_transition(node: Node, prop_name: String, transition_data: Dictionary) -> void:
	if transition_data.change_type == DIFF_TYPE.DIFF_REMOVED: return
	
	var frames: Array = transition_data.value.frames.value
	var prop_names: Array = transition_data.value.props.value
	
	var prop_values: Dictionary = {
		prop_name: node.get_indexed(prop_name)
	}
	for p_name in prop_names:
		prop_values[p_name] = node.get_indexed(prop_name + ":" + p_name)
	
	frames.sort_custom(ReactGDTransition, "sort_frames")

func _update_node_signal(node: Node, signal_name: String, signal_data: Dictionary) -> void:
	var target_node: Node = self
	var target_function: String
	var binds: Array
	var flags: int
	
	if signal_data.value is String:
		target_function = signal_data.value
		binds = []
		flags = 0
	elif signal_data.value is Array:
		var args_size: int = signal_data.value.size()
		if args_size == 1:
			target_function = signal_data.value[0]
			binds = []
			flags = 0
		elif args_size == 2:
			target_function = signal_data.value[0]
			binds = signal_data.value[1]
			flags = 0
		elif args_size == 3:
			target_function = signal_data.value[0]
			binds = signal_data.value[1]
			flags = signal_data.value[2]
	
	if signal_data.change_type == DIFF_TYPE.DIFF_ADDED:
		node.connect(signal_name, target_node, target_function, binds, flags)
	elif signal_data.change_type == DIFF_TYPE.DIFF_MODIFIED:
		node.disconnect(signal_name, target_node, target_function)
		node.connect(signal_name, target_node, target_function, binds, flags)
	elif signal_data.change_type == DIFF_TYPE.DIFF_REMOVED:
		node.disconnect(signal_name, target_node, target_function)

func do_transition() -> ReactGDTransition:
	return ReactGDTransition.new()

func set_state(new_state: Dictionary) -> void:
	for state_key in new_state.keys():
		state[state_key] = new_state[state_key]
	_dirty = true

func construct() -> void: pass

func render(): return {}

func get_class() -> String: return "ReactGDComponent"












