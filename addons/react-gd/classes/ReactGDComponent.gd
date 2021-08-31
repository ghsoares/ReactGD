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
var stores: Dictionary
var events: Dictionary
var children: Array

func _init() -> void:
	_render_state = {}
	_cached_nodes = {}
	stores = {}

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
	
	for node in _cached_nodes.values():
		if not node.is_inside_tree(): continue
		
		var props: Dictionary = node.get_meta("props")
		if node is Control:
			node.rect_pivot_offset = node.rect_size * props.get("rect_pivot_center", Vector2.ZERO)

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
			"signals": {},
			"theme": {
				"styles": {},
				"constants": {}
			},
			"ref": ""
		}
	else:
		node = {
			"cached_path": cached_path,
			"instance": render_state.type.new(),
			"signals": {},
			"theme": {
				"styles": {},
				"constants": {}
			},
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
		elif prop_name == "ref":
			node.ref = props[prop_name]
		elif prop_name == "children":
			children.append_array(props[prop_name])
		elif prop_name.begins_with("style_"):
			var style_name = prop_name.substr(6, prop_name.length())
			node.theme.styles[style_name] = props[prop_name]
		elif prop_name.begins_with("const_"):
			var const_name = prop_name.substr(6, prop_name.length())
			node.theme.constants[const_name] = props[prop_name]
		elif prop_name.begins_with("on_"):
			var signal_name = prop_name.substr(3, prop_name.length())
			if node.instance.has_signal(signal_name):
				if props[prop_name] is String and props[prop_name] != "":
					node.signals[signal_name] = props[prop_name]
	
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
	
	node.instance.set_meta("props", props)
	
	node.props = props
	return node

func _update_tree(render_diff: Dictionary, parent: Node, index: int) -> void:
	var cached_path: String = render_diff.cached_path.value
	var node_change_type: int = render_diff.instance.change_type
	var node: Node = render_diff.instance.value
	var ref: String = render_diff.ref.value
	
	if node_change_type != DIFF_TYPE.DIFF_REMOVED:
		var props_change_type: int = render_diff.props.change_type
		var props: Dictionary = render_diff.props.value
		
		var signals_change_type: int = render_diff.signals.change_type
		var signals: Dictionary = render_diff.signals.value
		
		var theme_change_type: int = render_diff.theme.change_type
		var theme: Dictionary = render_diff.theme.value
		
		if props_change_type != DIFF_TYPE.DIFF_UNCHANGED:
			_update_node_props(node, props)
			if node.get_class() == "ReactGDComponent":
				node._dirty = true
		
		if signals_change_type != DIFF_TYPE.DIFF_UNCHANGED:
			_update_node_signals(node, signals)
		
		if theme_change_type != DIFF_TYPE.DIFF_UNCHANGED:
			_update_node_theme(node, theme)
	
	if node_change_type == DIFF_TYPE.DIFF_ADDED:
		if node.get_class() == "ReactGDComponent":
			node.parent_component = self
			for store_name in stores.keys():
				node.stores[store_name] = stores[store_name]
		parent.add_child(node, true)
		parent.move_child(node, index)
		if node.get_class() == "ReactGDComponent":
			node._render_process()
		if ref != "":
			self.set_indexed(ref, node)
	
	elif node_change_type == DIFF_TYPE.DIFF_REMOVED:
		parent.remove_child(node)
		if node.get_class() == "ReactGDComponent":
			parent.remove_child(node._render_state.instance)
		
		_cached_nodes.erase(cached_path)
		node.queue_free()
		if node.get_class() == "ReactGDComponent":
			node._render_state.instance.queue_free()
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
		var prop_value = props[prop_name].value
		if prop_value is Dictionary and prop_value.has("reactgd_transition_data"):
			_update_transition(node, prop_name, prop_value["reactgd_transition_data"])
			continue
		node.set_indexed(prop_name, prop_value)
		if node is LineEdit:
			if prop_name == "text":
				node.caret_position = prop_value.length()

func _update_node_signals(node: Node, signals: Dictionary) -> void:
	for signal_name in signals.keys():
		if signals[signal_name].change_type == DIFF_TYPE.DIFF_UNCHANGED: continue
		_update_node_signal(node, signal_name, signals[signal_name])

func _update_node_theme(node: Control, theme: Dictionary) -> void:
	#print(theme)
	if theme.styles.change_type != DIFF_TYPE.DIFF_UNCHANGED:
		var styles: Dictionary = theme.styles.value
		for style_name in styles.keys():
			if styles[style_name].change_type == DIFF_TYPE.DIFF_UNCHANGED: continue
			if styles[style_name].change_type == DIFF_TYPE.DIFF_REMOVED:
				node.add_stylebox_override(style_name, null)
				continue
			var style = styles[style_name].value
			if style == null: continue
			if style.empty():
				node.add_stylebox_override(style_name, StyleBoxEmpty.new())
				continue
			
			var stylebox: StyleBox = null
			
			if styles[style_name].change_type == DIFF_TYPE.DIFF_ADDED:
				stylebox = style.type.value.new()
				node.add_stylebox_override(style_name, stylebox)
			else:
				stylebox = node.get_stylebox(style_name)
			
			var props: Dictionary = style.get("props", {}).get("value", {})
			for prop_name in props.keys():
				if props[prop_name].change_type == DIFF_TYPE.DIFF_REMOVED:
					stylebox.set_indexed(
						prop_name, style.type.value.new().get_indexed(prop_name)
					)
				else:
					var prop_val = props[prop_name].value
					if prop_val is Dictionary and prop_val.has("reactgd_transition_data"):
						_update_transition(stylebox, prop_name, prop_val["reactgd_transition_data"])
						continue
					
					stylebox.set_indexed(prop_name, prop_val)
	if theme.constants.change_type != DIFF_TYPE.DIFF_UNCHANGED:
		var constants: Dictionary = theme.constants.value
		for const_name in constants.keys():
			node.add_constant_override(const_name, constants[const_name].value)

func _update_transition(obj: Object, prop_name: String, transition_data: Dictionary) -> void:
	if transition_data.change_type == DIFF_TYPE.DIFF_REMOVED: return
	
	var frames: Array = transition_data.value.frames.value
	var prop_names: Array = transition_data.value.props.value
	var prop_values: Dictionary = {}
	
	if prop_name == "transition":
		prop_name = ""
	else:
		_tw.stop(obj, prop_name)
		prop_values = {
			prop_name: obj.get_indexed(prop_name)
		}
	
	for p_name in prop_names:
		if p_name != "":
			prop_values[prop_name + p_name] = obj.get_indexed(prop_name + p_name)
			_tw.stop(obj, prop_name + p_name)
	
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
			obj, p_name, start_value, final_value, duration, trans_type, ease_type,
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

func _on_store_changed() -> void:
	self._dirty = true

func do_transition() -> ReactGDTransition:
	return ReactGDTransition.new()

func create_style(style_data) -> Dictionary:
	var data := {}
	if style_data is Array:
		for d in style_data:
			ReactGDDictionaryMethods.merge_dict(data, d)
	elif style_data is Dictionary:
		data = style_data
	else:
		assert(false, "Invalid style data type")
	assert(data.has("type"), "Style must have the stylebox type!")
	var style := {
		"type": data.type,
		"props": {}
	}
	
	for prop_name in data.keys():
		if prop_name == "type": continue
		var prop_value = data[prop_name]
		
		if prop_value is ReactGDTransition:
			prop_value = {
				"reactgd_transition_data": {
					"frames": prop_value._frames,
					"props": prop_value._props,
					"hash": prop_value._hash
				}
			}
		
		match prop_name:
			"border_width":
				for p in ["_left", "_right", "_top", "_bottom"]:
					style.props["border_width" + p] = prop_value
			"border_width_horizontal":
				for p in ["_left", "_right"]:
					style.props["border_width" + p] = prop_value
			"border_width_vertical":
				for p in ["_top", "_bottom"]:
					style.props["border_width" + p] = prop_value
			"corner_radius":
				for p in ["_top_left", "_top_right", "_bottom_left", "_bottom_right"]:
					style.props["corner_radius" + p] = prop_value
			"expand_margin":
				for p in ["_left", "_right", "_top", "_bottom"]:
					style.props["expand_margin" + p] = prop_value
			"expand_margin_horizontal":
				for p in ["_left", "_right"]:
					style.props["expand_margin" + p] = prop_value
			"expand_margin_vertical":
				for p in ["_top", "_bottom"]:
					style.props["expand_margin" + p] = prop_value
			"content_margin":
				for p in ["_left", "_right", "_top", "_bottom"]:
					style.props["content_margin" + p] = prop_value
			"content_margin_horizontal":
				for p in ["_left", "_right"]:
					style.props["content_margin" + p] = prop_value
			"content_margin_vertical":
				for p in ["_top", "_bottom"]:
					style.props["content_margin" + p] = prop_value
			_:
				style.props[prop_name] = prop_value
	
	return style

func create_store(reducer: String) -> ReactGDStore:
	return ReactGDStore.new(funcref(self, reducer))

func register_store(store_name: String, store: ReactGDStore) -> void:
	stores[store_name] = store

func subscribe_to_store(store_name: String) -> void:
	stores[store_name].subscribe(self, "_on_store_changed")

func unsubscribe_from_store(store_name: String) -> void:
	stores[store_name].unsubscribe(self, "_on_store_changed")

func dispatch_action(store_name: String, action_type: String, payload) -> void:
	stores[store_name].dispatch(action_type, payload)

func get_store_state(store_name: String):
	return stores[store_name].state

func set_state(new_state: Dictionary) -> void:
	for state_key in new_state.keys():
		state[state_key] = new_state[state_key]
	_dirty = true

func trigger_event(event_name: String, val: bool = true) -> void:
	events[event_name] = val
	_dirty = true

func add_child(node, legible_name = false):
	.add_child(node, legible_name)

func construct() -> void: pass

func render() -> Dictionary: return {}

func get_class() -> String: return "ReactGDComponent"












