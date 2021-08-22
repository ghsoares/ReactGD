extends Control

class_name ReactUI

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
	var node := {}
	
	if self._cached_nodes.has(id):
		node = self._cached_nodes[id]
		var instance = node.instance
		#if type != node.type:
		#	instance = type.new()
		#	if instance.get_class() == "ReactComponent":
		#		instance.construct()
		node = {
			"id": id,
			"type": type,
			"instance": instance,
			"children": {},
			"props": {},
			"signals": {},
			"theme": {},
			"ref": "",
		}
		self._cached_nodes[id] = node
	else:
		node = {
			"id": id,
			"type": type,
			"instance": type.new(),
			"children": {},
			"props": {},
			"signals": {},
			"theme": {},
			"ref": "",
		}
		if node.instance.get_class() == "ReactComponent":
			node.instance.construct()
		self._cached_nodes[id] = node
	
	node.props = props
	for p_name in props.keys():
		if p_name == "ref":
			node.ref = props[p_name]
		elif p_name == "theme":
			node.theme = props[p_name]
		elif p_name.begins_with("on_"):
			var signal_name :String = p_name.substr(3, p_name.length() - 3)
			if node.instance.has_signal(signal_name):
				var signal_value = props[p_name]
				if signal_value is String:
					signal_value = [signal_value, [], 0]
				elif signal_value is Array:
					if signal_value.size() == 1:
						signal_value += [[], 0]
					elif signal_value.size() == 2:
						signal_value += [0]
				node.signals[signal_name] = signal_value
	
	if node.instance.get_class() == "ReactComponent":
		node.instance.id = id
		node.instance.tree = self
		node.instance.props = props
		children.append(node.instance.render())
	
	if children.size() > 0:
		node.children = {}
		for i in range(children.size()):
			var c = self._build_tree(children[i], id + "." )
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
		if ref.value != "":
			root_component.set(ref.value, instance.value)
	elif instance.change_type == 2:
		parent.remove_child(instance.value)
		_cached_nodes.erase(id.value)
		if !children.value.empty():
			for c_id in children.value.keys():
				var c :Dictionary = children.value[c_id]
				if c_type == "ReactComponent":
					_iterate_tree(instance.value, parent, c.value, 0)
				else:
					_iterate_tree(root_component, instance.value, c.value, 0)
		if ref.value != "":
			root_component.set(ref.value, null)
		return
	
	if props.change_type == 0 || props.change_type == 1:
		_update_props(instance.value, props.value)
	
	if signals.change_type == 0 || signals.change_type == 1:
		_update_signals(root_component, instance.value, signals.value)
	
	if theme.change_type == 0 || theme.change_type == 1:
		_update_theme(instance.value, theme.value)
	
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
			if node is LineEdit && prop_name == "text":
				node.caret_position = prop.value.length()

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

func _update_theme(node: Node, theme: Dictionary) -> void:
	var styles :Dictionary = theme.get("styles", {})
	var colors :Dictionary = theme.get("colors", {})
	var constants :Dictionary = theme.get("constants", {})
	var fonts :Dictionary = theme.get("fonts", {})
	var icons :Dictionary = theme.get("icons", {})
	
	var styles_change_type: int = styles.get("change_type", -1)
	var colors_change_type: int = colors.get("change_type", -1)
	var constants_change_type: int = constants.get("change_type", -1)
	var fonts_change_type: int = fonts.get("change_type", -1)
	var icons_change_type: int = icons.get("change_type", -1)
	
	if styles_change_type == 0 || styles_change_type == 1:
		_update_styles(node, styles.get("value", {}))
	if colors_change_type == 0 || colors_change_type == 1:
		_update_colors(node, colors.get("value", {}))
	if constants_change_type == 0 || constants_change_type == 1:
		_update_constants(node, constants.get("value", {}))
	if fonts_change_type == 0 || fonts_change_type == 1:
		_update_fonts(node, fonts.get("value", {}))
	if icons_change_type == 0 || icons_change_type == 1:
		_update_icons(node, icons.get("value", {}))

func _update_styles(node: Control, styles: Dictionary) -> void:
	for b in styles:
		var style_name :String = b[0]
		var change_type = styles[b].change_type
		var style_obj :StyleBox = null
		
		if change_type == 0:
			style_obj = b[1].new()
			node.add_stylebox_override(style_name, style_obj)
		elif change_type == 2:
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
		elif change_type == 2:
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

func get_class() -> String: return "ReactTree"

































