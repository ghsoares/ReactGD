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
var events: Dictionary
var children: Array

func _init() -> void:
	_render_state = {}
	_cached_nodes = {}

func _ready() -> void:
	_tw = Tween.new()
	add_child(_tw)
	
	state = {}
	events = {}
	
	construct()

func _enter_tree() -> void:
	_dirty = true

func _process(delta: float) -> void:
	if _dirty:
		var start := OS.get_ticks_msec()
		
		_render_process()
		_dirty = false
		
		var elapsed := OS.get_ticks_msec() - start
		print("(", name, ") Render: ", elapsed, " ms")

func _render_process() -> void:
	var new_render = render()
	if not new_render: new_render = {}
	var new_render_state = _build_component(new_render, "")
	
	if new_render_state.hash() != _render_state.hash():
		var render_diff = ReactGDDictionaryMethods.diff(_render_state, new_render_state)
		if render_diff.empty(): return
		if parent_component:
			_update_tree(render_diff, get_parent(), get_index() + 1)
		else:
			_update_tree(render_diff, self, 0)
		
		_render_state = new_render_state
	
	for ev in events.keys():
		events[ev] = false

func _build_component(render_state: Dictionary, path: String) -> Dictionary:
	if render_state.empty(): return {}
	var props: Dictionary = render_state.get("props", {})
	var children: Array = render_state.get("children", [])
	render_state.id += str(props.get("key", ""))
	
	var node :Dictionary = {}
	var cached_path :String = path + render_state.id
	
	if _cached_nodes.has(cached_path):
		node = {
			"cached_path": cached_path,
			"instance": _cached_nodes[cached_path],
			"persist": false,
			"ref": ""
		}
	else:
		node = {
			"cached_path": cached_path,
			"instance": render_state.type.new(),
			"persist": false,
			"ref": ""
		}
		_cached_nodes[cached_path] = node.instance
	
	var dict_children := {}
	
	for prop_name in props:
		if props[prop_name] is ReactGDTransition:
			props[prop_name] = {
				"reactgd_transition_data": {
					"frames": props[prop_name]._frames,
					"props": props[prop_name]._props,
					"hash": props[prop_name]._hash
				}
			}
		elif prop_name == "persist":
			node.persist = props[prop_name]
		elif prop_name == "ref":
			node.ref = props[prop_name]
	
	if node.instance.get_class() == "ReactGDComponent":
		node.instance.children = children
		node.children = {}
	else:
		var prev_conditional_true := false
		var new_children := {}
		for child in children:
			if child.type is String:
				if child.type == "If":
					prev_conditional_true = child.props.conditional
					if prev_conditional_true:
						for n_child in child.children:
							new_children[n_child.id] = _build_component(n_child, cached_path + "_")
				
				elif child.type == "Elif":
					if prev_conditional_true: continue
					prev_conditional_true = child.props.conditional
					if prev_conditional_true:
						for n_child in child.children:
							new_children[n_child.id] = _build_component(n_child, cached_path + "_")
				
				elif child.type == "Else":
					if prev_conditional_true: continue
					for n_child in child.children:
						new_children[n_child.id] = _build_component(n_child, cached_path + "_")
			else:
				new_children[child.id] = _build_component(child, cached_path + "_")
		node.children = new_children
	
	node.props = props
	#node.children = children
	return node

func _update_tree(render_diff: Dictionary, parent: Node, index: int) -> void:
	var cached_path: String = render_diff.cached_path.value
	var node_change_type: int = render_diff.instance.change_type
	var node: Node = render_diff.instance.value
	var persist: bool = render_diff.persist.value
	var ref: String = render_diff.ref.value
	
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
		if ref != "":
			self.set_indexed(ref, node)
	elif node_change_type == DIFF_TYPE.DIFF_REMOVED:
		parent.remove_child(node)
		if not persist:
			_cached_nodes.erase(cached_path)
			node.queue_free()
			if ref != "":
				self.set_indexed(ref, null)
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
	var prop_values: Dictionary = {}
	
	if prop_name == "transition":
		prop_name = ""
	else:
		_tw.stop(node, prop_name)
		prop_values = {
			prop_name: node.get_indexed(prop_name)
		}
	
	for p_name in prop_names:
		if p_name != "":
			prop_values[prop_name + p_name] = node.get_indexed(prop_name + p_name)
			_tw.stop(node, prop_name + p_name)
	
	frames.sort_custom(ReactGDTransition, "sort_frames")
	
	for frame in frames:
		var p_name: String = prop_name + frame.prop
		var start_value = prop_values[p_name]
		var final_value = frame.final_value
		var time: float = frame.time
		var duration: float = frame.duration
		var trans_type: int = frame.trans_type
		var ease_type: int = frame.ease_type
		
		_tw.interpolate_property(
			node, p_name, start_value, final_value, duration, trans_type, ease_type,
			time
		)
		
		prop_values[p_name] = final_value
	
	_tw.start()

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

func _do_transition(commands: Array) -> ReactGDTransition:
	return ReactGDTransition.new(commands)

func set_state(new_state: Dictionary) -> void:
	for state_key in new_state.keys():
		state[state_key] = new_state[state_key]
	_dirty = true

func trigger_event(event_name: String, val: bool = true) -> void:
	events[event_name] = val
	_dirty = true

func construct() -> void: pass

func render() -> Dictionary: return {}

func get_class() -> String: return "ReactGDComponent"












