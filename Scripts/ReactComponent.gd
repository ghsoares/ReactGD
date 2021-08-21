extends Node

class_name ReactComponent

var _dirty: bool
var _render_state: Dictionary
var state: Dictionary

func _enter_tree() -> void:
	if Engine.editor_hint:
		for c in get_children():
			if !c.owner: c.queue_free()
	
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
	
	#print(JSON.print(new_render_state, "  "))
	
	if !diff.empty():
		_iterate_tree(self, self, diff)
		_render_state = new_render_state
	
	_dirty = false
	
	var elapsed = OS.get_ticks_msec() - start
	print("(" + name + ")" + " Render: ", elapsed, " ms")

func _change_node_type(node: Node, to_type) -> Node:
	var parent = node.get_parent()
	var idx = node.get_index()
	
	parent.remove_child(node)
	node.call_deferred("free")
	
	if to_type.new().get_class() == "ReactComponent":
		node = to_type.get_base().new()
		node.script = to_type
	else:
		node = to_type.new()
	
	parent.add_child(node)
	parent.move_child(node, idx)
	
	return node

func _iterate_tree(
	parent: Node, prev_component: Node, nodes: Dictionary
) -> void:
	var num_nodes := nodes.size()
	
	var i := 0
	var keys := nodes.keys()
	
	while i < num_nodes:
		var n = keys[i]
		
		var node_change_type: int = nodes[n].change_type
		var node_data: Dictionary = nodes[n].value
		
		var ref: Dictionary = node_data.get("ref", {})
		var ref_name: String = ref.get("value", "")
		var ref_change: int = ref.get("change_type", -1)
		
		var node :Node = parent
		
		if node_change_type == 0:
			var type = node_data.type
			if type.value.new().get_class() == "ReactComponent":
				node = type.value.get_base().new()
				node.script = type.value
			else:
				node = type.value.new()
			
			parent.add_child(node)
			_update_node(node, prev_component, node_data)
		elif node_change_type == 1:
			node = parent.get_child(n)
			node.queue_free()
			
			i += 1
			continue
		elif node_change_type == 2:
			node = parent.get_child(n)
			var type = node_data.get("type", null)
			if type && type.change_type == 2:
				node = _change_node_type(node, type.value)
			
			_update_node(node, prev_component, node_data)
		
		if ref_name != "" && ref_change == 2 || ref_change == 0:
			prev_component.set(ref_name, node)
		
		var children = node_data.get("children", {}).get("value", {})
		var secondary_children = node_data.get("secondary_children", {}).get("value", {})
		
		if !secondary_children.empty(): _iterate_tree(node, prev_component, secondary_children)
		if !children.empty(): _iterate_tree(node, prev_component, children)
		
		i += 1

func _update_node(node: Node, prev_component: Node, data: Dictionary) -> void:
	var props :Dictionary = data.get("props", {}).get("value", {})
	var signals :Dictionary = data.get("signals", {}).get("value", {})
	
	for prop_name in props:
		var prop_val = props[prop_name].value
		var prop_change_type = props[prop_name].change_type
		if prop_change_type == 0 || prop_change_type == 2:
			node.set(prop_name, prop_val)
			if node.get_class() == "ReactComponent":
				node._dirty = true
	
	for signal_name in signals:
		var signal_val = signals[signal_name].value
		var signal_change_type = signals[signal_name].change_type
		
		if signal_val is Dictionary:
			var target = signal_val.target.value
			var binds = signal_val.get("binds", {}).get("value", [])
			var flags = signal_val.get("flags", {}).get("value", 0)
			
			if signal_change_type == 0:
				if node.has_signal(signal_name):
					node.connect(signal_name, prev_component, target, binds, flags)
			elif signal_change_type == 1:
				if node.has_signal(signal_name):
					node.disconnect(signal_name, prev_component, target)
			else:
				var prev_target = signal_val.target.prev_value
				if node.has_signal(signal_name):
					node.disconnect(signal_name, prev_component, prev_target)
					node.connect(signal_name, prev_component, target, binds, flags)
		elif signal_val is String:
			var target = signal_val
			
			if signal_change_type == 0:
				if node.has_signal(signal_name):
					node.connect(signal_name, prev_component, target)
			elif signal_change_type == 1:
				if node.has_signal(signal_name):
					node.disconnect(signal_name, prev_component, target)
			else:
				var prev_target = signals[signal_name].prev_value
				if node.is_connected(signal_name, prev_component, prev_target):
					node.disconnect(signal_name, prev_component, prev_target)
					node.connect(signal_name, prev_component, target)
	
	if node is Control:
		_update_theme(node, data.get("theme", {}).get("value", {}))

func _update_theme(node: Control, theme: Dictionary) -> void:
	var styles :Dictionary = theme.get("styles", {}).get("value", {})
	var colors :Dictionary = theme.get("colors", {}).get("value", {})
	var constants :Dictionary = theme.get("constants", {}).get("value", {})
	var fonts :Dictionary = theme.get("fonts", {}).get("value", {})
	var icons :Dictionary = theme.get("icons", {}).get("value", {})
	
	_update_styles(node, styles)
	_update_colors(node, colors)
	_update_constants(node, constants)
	_update_fonts(node, fonts)
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
			match prop:
				"border_width":
					style_obj.set("border_width_left", prop_val)
					style_obj.set("border_width_right", prop_val)
					style_obj.set("border_width_top", prop_val)
					style_obj.set("border_width_bottom", prop_val)
				"border_width_horizontal":
					style_obj.set("border_width_left", prop_val)
					style_obj.set("border_width_right", prop_val)
				"border_width_vertical":
					style_obj.set("border_width_top", prop_val)
					style_obj.set("border_width_bottom", prop_val)
				"corner_radius":
					style_obj.set("corner_radius_top_left", prop_val)
					style_obj.set("corner_radius_top_right", prop_val)
					style_obj.set("corner_radius_bottom_left", prop_val)
					style_obj.set("corner_radius_bottom_right", prop_val)
				"expand_margin":
					style_obj.set("expand_margin_left", prop_val)
					style_obj.set("expand_margin_right", prop_val)
					style_obj.set("expand_margin_top", prop_val)
					style_obj.set("expand_margin_bottom", prop_val)
				"expand_margin_horizontal":
					style_obj.set("expand_margin_left", prop_val)
					style_obj.set("expand_margin_right", prop_val)
				"expand_margin_vertical":
					style_obj.set("expand_margin_top", prop_val)
					style_obj.set("expand_margin_bottom", prop_val)
				"content_margin":
					style_obj.set("content_margin_left", prop_val)
					style_obj.set("content_margin_right", prop_val)
					style_obj.set("content_margin_top", prop_val)
					style_obj.set("content_margin_bottom", prop_val)
				"content_margin_horizontal":
					style_obj.set("content_margin_left", prop_val)
					style_obj.set("content_margin_right", prop_val)
				"content_margin_vertical":
					style_obj.set("content_margin_top", prop_val)
					style_obj.set("content_margin_bottom", prop_val)
				_:
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

func _update_fonts(node: Control, fonts: Dictionary) -> void:
	for f in fonts:
		var change_type = fonts[f].change_type
		var value :DynamicFont = null
		
		if change_type == 0:
			value = DynamicFont.new()
			node.add_font_override(f, value)
		elif change_type == 1:
			node.add_font_override(f, null)
			continue
		else:
			value = node.get_font(f)
		
		for prop in fonts[f].value:
			var prop_val = fonts[f].value[prop].value
			if prop == "src":
				prop_val = ResourceLoader.load(prop_val)
				value.font_data = prop_val
				continue
			
			value.set(prop, prop_val)

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






























