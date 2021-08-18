extends Control

class_name ReactComponent

var _dirty: bool
var _render_state: Dictionary
var state: Dictionary

func _enter_tree() -> void:
	state = {}
	_dirty = true
	_render_state = {}
	construct()

func set_state(new_state: Dictionary) -> void:
	DictionaryMethods.merge_dict(state, new_state)
	_dirty = true

func construct() -> void: pass

func render() -> Dictionary:
	return {}

func _process(delta) -> void:
	if !_dirty: return
	
	var new_render_state := render()
	var diff := DictionaryMethods.compute_diff(_render_state, new_render_state)
	
	_iterate_tree(self, diff)
	
	_render_state = new_render_state
	_dirty = false

func _iterate_tree(
	parent: Node, data: Dictionary
) -> void:
	var comp_reg := RegEx.new()
	comp_reg.compile("([\\w]+)#([\\w]+)")
	
	for k in data.keys():
		var res := comp_reg.search(k)
		var c_name := res.get_string(1)
		var node_name := res.get_string(2)
		
		var change_type: int = data[k].change_type
		var node_data :Dictionary = data[k].value
		var children :Dictionary = node_data.get("children", {}).get("value", {})
		
		var node :Node = parent
		
		if change_type == 0:
			node = ClassDB.instance(c_name)
			
			node.name = node_name
			
			parent.add_child(node)
			_add_node(node, node_data)
		elif change_type == 1:
			node = parent.get_node(node_name)
			
			node.queue_free()
		else:
			node = parent.get_node(node_name)
			
			_update_node(node, node_data)
		
		if !children.empty(): _iterate_tree(node, children)

func _add_node(node: Node, data: Dictionary) -> void:
	var props :Dictionary = data.get("props", {}).get("value", {})
	var signals :Dictionary = data.get("signals", {}).get("value", {})
	
	for prop_name in props:
		var prop_val = props[prop_name].value
		node.set(prop_name, prop_val)
	
	for signal_name in signals:
		var signal_val = signals[signal_name].value
		if signal_val is Dictionary:
			var target = signal_val.target.value
			var binds = signal_val.get("binds", {}).get("value", [])
			var flags = signal_val.get("flags", {}).get("value", 0)
			
			node.connect(signal_name, self, target, binds, flags)
		elif signal_val is String:
			node.connect(signal_name, self, signal_val)
	
	if node is Control:
		_update_theme(node, data.get("theme", {}).get("value", {}))

"""
void add_color_override(name: String, color: Color)
void add_constant_override(name: String, constant: int)
void add_font_override(name: String, font: Font)
void add_icon_override(name: String, texture: Texture)
void add_shader_override(name: String, shader: Shader)
void add_stylebox_override(name: String, stylebox: StyleBox)
"""

func _update_theme(node: Control, theme: Dictionary) -> void:
	var stylebox :Dictionary = theme.get("stylebox", {}).get("value", {})
	
	for b in stylebox:
		var box = stylebox[b].value
		var box_type = box.type.value
		var change_type = box.type.change_type
		
		var box_obj = null
		
		if change_type == 0:
			box_obj = ClassDB.instance(box_type)
			node.add_stylebox_override(b, box_obj)
		elif change_type == 1:
			node.add_stylebox_override(b, null)
			continue
		elif change_type == 2:
			box_obj = node.get_stylebox(b)
		
		for prop in box.props.value:
			box_obj.set(prop, box.props.value[prop].value)
			pass

func _update_node(node: Node, data: Dictionary) -> void:
	var props :Dictionary = data.get("props", {}).get("value", {})
	var signals :Dictionary = data.get("signals", {}).get("value", {})
	
	for prop_name in props:
		var prop_val = props[prop_name].value
		node.set(prop_name, prop_val)
	
	for signal_name in signals:
		var signal_val = signals[signal_name].value
		if signal_val is Dictionary:
			var target = signal_val.target.value
			var binds = signal_val.get("binds", {}).get("value", [])
			var flags = signal_val.get("flags", {}).get("value", 0)
			
			if !node.is_connected(signal_name, self, target):
				node.connect(signal_name, self, target, binds, flags)
		elif signal_val is String:
			if !node.is_connected(signal_name, self, signal_val):
				node.connect(signal_name, self, signal_val)





