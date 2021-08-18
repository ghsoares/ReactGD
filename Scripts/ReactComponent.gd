extends Control

class_name ReactComponent

var _dirty: bool
var _render_state: Dictionary
var state: Dictionary

func _enter_tree() -> void:
	_dirty = true
	state = {}
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
	var start = OS.get_ticks_msec()
	
	var new_render_state := render()
	var diff := DictionaryMethods.compute_diff(_render_state, new_render_state)
	
	_iterate_tree(self, self, diff)
	
	_render_state = new_render_state
	_dirty = false
	
	var elapsed = OS.get_ticks_msec() - start
	print("Render: ", elapsed, " ms")

func _iterate_tree(
	parent: Node, prev_component: Node, data: Dictionary
) -> void:
	for k in data.keys():
		var script = k[0]
		var node_name = k[1]
		
		var change_type: int = data[k].change_type
		var node_data :Dictionary = data[k].value
		var children :Dictionary = node_data.get("children", {}).get("value", {})
		
		var node :Node = parent
		
		if change_type == 0:
			if script.new().get_class() == "ReactComponent":
				node = script.get_base().new()
				node.script = script
			else:
				node = script.new()
			
			node.name = node_name
			
			parent.add_child(node)
			_update_node(node, prev_component, node_data)
		elif change_type == 1:
			node = parent.get_node(node_name)
			
			node.queue_free()
		else:
			node = parent.get_node(node_name)
			if node.get_class() == "ReactComponent":
				node._dirty = true
			
			_update_node(node, prev_component, node_data)
		
		if node.get_class() == "ReactComponent": prev_component = node
		
		if !children.empty(): _iterate_tree(node, prev_component, children)

func _update_node(node: Node, prev_component: Node, data: Dictionary) -> void:
	var props :Dictionary = data.get("props", {}).get("value", {})
	var signals :Dictionary = data.get("signals", {}).get("value", {})
	
	for prop_name in props:
		var prop_val = props[prop_name].value
		var prop_change_type = props[prop_name].change_type
		if prop_change_type == 0 || prop_change_type == 2:
			node.set(prop_name, prop_val)
	
	for signal_name in signals:
		var signal_val = signals[signal_name].value
		var signal_change_type = signals[signal_name].change_type
		
		if signal_val is Dictionary:
			var target = signal_val.target.value
			var binds = signal_val.get("binds", {}).get("value", [])
			var flags = signal_val.get("flags", {}).get("value", 0)
			
			if signal_change_type == 0:
				node.connect(signal_name, prev_component, target, binds, flags)
			elif signal_change_type == 1:
				node.disconnect(signal_name, prev_component, target)
			else:
				var prev_target = signal_val.target.prev_value
				node.disconnect(signal_name, prev_component, prev_target)
				node.connect(signal_name, prev_component, target, binds, flags)
		elif signal_val is String:
			var target = signal_val
			
			if signal_change_type == 0:
				node.connect(signal_name, prev_component, target)
			elif signal_change_type == 1:
				node.disconnect(signal_name, prev_component, target)
			else:
				var prev_target = signals[signal_name].prev_value
				node.disconnect(signal_name, prev_component, prev_target)
				node.connect(signal_name, prev_component, target)
	
	if node is Control:
		_update_theme(node, data.get("theme", {}).get("value", {}))

func _update_theme(node: Control, theme: Dictionary) -> void:
	var styles :Dictionary = theme.get("styles", {}).get("value", {})
	var colors :Dictionary = theme.get("colors", {}).get("value", {})
	var constants :Dictionary = theme.get("constants", {}).get("value", {})
	var icons :Dictionary = theme.get("icons", {}).get("value", {})
	
	_update_styles(node, styles)
	_update_colors(node, colors)
	_update_constants(node, constants)
	_update_icons(node, icons)

func _update_styles(node: Control, styles: Dictionary) -> void:
	for b in styles:
		var style_name :String = b[0]
		var change_type = styles[b].change_type
		var style_obj :StyleBox = null
		
		if change_type == 0:
			style_obj = b[1].new()
			node.add_stylebox_override(style_name, style_obj)
		elif change_type == 1:
			node.add_stylebox_override(style_name, null)
			continue
		else:
			style_obj = node.get_stylebox(style_name)
		
		for prop in styles[b].value:
			var prop_val = styles[b].value[prop].value
			style_obj.set(prop, prop_val)

func _update_colors(node: Control, colors: Dictionary) -> void:
	for c in colors:
		var change_type = colors[c].change_type
		var value: Color = Color.black
		
		if change_type == 0:
			value = colors[c].value
		elif change_type == 1:
			var default = ClassDB.instance(node.get_class()).get_color(c)
			node.add_color_override(c, default)
			continue
		else:
			value = colors[c].value
		
		node.add_color_override(c, value)

func _update_constants(node: Control, constants: Dictionary) -> void:
	for c in constants:
		var change_type = constants[c].change_type
		var value :int = 0
		
		if change_type == 0:
			value = constants[c].value
		elif change_type == 1:
			node.add_constant_override(c, 0)
			continue
		else:
			value = constants[c].value
		
		node.add_constant_override(c, value)

func _update_icons(node: Control, icons: Dictionary) -> void:
	for i in icons:
		var change_type = icons[i].change_type
		var value :Texture = null
		
		if change_type == 0:
			value = icons[i].value
		elif change_type == 1:
			node.add_icon_override(i, null)
			continue
		else:
			value = icons[i].value
		
		node.add_icon_override(i, value)

func get_class() -> String: return "ReactComponent"

static func get_base(): return Control






























