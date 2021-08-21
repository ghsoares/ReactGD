extends Control

class_name ReactTree

var _render_state: Dictionary
var _dirty: bool
var _cached_nodes: Dictionary
var state: Dictionary

func _enter_tree() -> void:
	_render_state = {}
	_dirty = true
	_cached_nodes = {}
	state = {}
	construct()

func construct() -> void: pass

func set_state(new_state: Dictionary) -> void:
	ReactGDDictionaryMethods.merge_dict(self.state, new_state)
	_dirty = true

func set_dirty() -> void:
	_dirty = true

func render() -> Dictionary:
	return {}

func _process(delta) -> void:
	if !_dirty: return
	_dirty = false
	
	var start = OS.get_ticks_msec()
	
	var new_render_state := render()
	new_render_state = _build_tree(new_render_state, "")
	var tree_diff = ReactGDDictionaryMethods.compute_diff(_render_state, new_render_state)
	
	_iterate_tree(self, self, tree_diff, 0)
	_render_state = new_render_state
	
	var elapsed = OS.get_ticks_msec() - start
	print("(" + name + ")" + " Render: ", elapsed, " ms")

func _build_tree(render_state, id: String) -> Dictionary:
	id = id + render_state.id
	var type = render_state.type
	var children :Array = render_state.get("children", [])
	var props :Dictionary = render_state.get("props", {})
	var signals :Dictionary = render_state.get("signals", {})
	var theme :Dictionary = render_state.get("theme", {})
	var ref :String = render_state.get("ref", "")
	var node := {}
	
	if self._cached_nodes.has(id):
		node = self._cached_nodes[id]
		var instance = node.instance
		if type != node.type:
			instance = type.new()
			if instance.get_class() == "ReactComponent":
				instance.construct()
		node = {
			"id": id,
			"type": type,
			"instance": instance,
			"children": {},
			"props": props,
			"signals": signals,
			"theme": theme,
			"ref": ref,
		}
		self._cached_nodes[id] = node
	else:
		node = {
			"id": id,
			"type": type,
			"instance": type.new(),
			"children": {},
			"props": props,
			"signals": signals,
			"theme": theme,
			"ref": ref,
		}
		if node.instance.get_class() == "ReactComponent":
			node.instance.construct()
		self._cached_nodes[id] = node
	
	node["props"] = props
	
	if node.instance.get_class() == "ReactComponent":
		node.instance.tree = self
		node.instance.props = props
		children.append(node.instance.render())
	
	if children.size() > 0:
		node.children = {}
		for i in range(children.size()):
			var c = self._build_tree(children[i], id + "_" )
			var c_id = c.id
			node.children[c_id] = c
	
	return node

func _iterate_tree(root_component: Node, parent: Node, tree: Dictionary, child_idx: int) -> void:
	var id: Dictionary = tree.id
	var instance: Dictionary = tree.instance
	var children: Dictionary = tree.children
	var props: Dictionary = tree.props
	var signals: Dictionary = tree.signals
	var theme: Dictionary = tree.theme
	var ref: Dictionary = tree.ref
	var c_type: String = instance.value.get_class()
	
	if instance.change_type == 0:
		parent.add_child(instance.value)
		parent.move_child(instance.value, child_idx)
	elif instance.change_type == 2:
		parent.remove_child(instance.value)
		if c_type == "ReactComponent":
			if !children.value.empty():
				var first = children.value.keys()[0]
				var child = children.value[first].value.instance
				parent.remove_child(child.value)
	
	if props.change_type == 0 || props.change_type == 1:
		_update_props(instance.value, props.value)
	
	if signals.change_type == 0 || signals.change_type == 1:
		_update_signals(root_component, instance.value, signals.value)
	
	if children.change_type == 0 || children.change_type == 1:
		var off = 0
		children = children.value
		for c_id in children.keys():
			var c :Dictionary = children[c_id]
			
			if c.change_type != 3:
				if c_type == "ReactComponent":
					_iterate_tree(instance.value, parent, c.value, child_idx + off + 1)
				else:
					_iterate_tree(root_component, instance.value, c.value, off)
			
			if c.change_type == 3:
				if c.value.instance.get_class() == "ReactComponent":
					off += 2
				else:
					off += 1
			elif c.change_type != 2:
				if c.value.instance.value.get_class() == "ReactComponent":
					off += 2
				else:
					off += 1

func _update_props(node: Node, props: Dictionary) -> void:
	for prop_name in props.keys():
		var prop = props[prop_name]
		if prop.change_type != 3:
			node.set(prop_name, prop.value)

func _update_signals(target_component: Node, node: Node, signals: Dictionary) -> void:
	for signal_name in signals.keys():
		var sig = signals[signal_name]
		if sig.change_type == 0:
			var target_name = sig.value[0]
			var target_binds = sig.value[1]
			var target_flags = sig.value[2]
			node.connect(signal_name, target_component, target_name, target_binds, target_flags)
		elif sig.change_type == 1:
			var prev_target_name = sig.prev_value[0]
			var target_name = sig.value[0]
			var target_binds = sig.value[1]
			var target_flags = sig.value[2]
			node.disconnect(signal_name, target_component, prev_target_name)
			node.connect(signal_name, target_component, target_name, target_binds, target_flags)
		elif sig.change_type == 2:
			var prev_target_name = sig.value[0]
			node.disconnect(signal_name, target_component, prev_target_name)

func get_class() -> String: return "ReactTree"

































