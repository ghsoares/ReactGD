extends Control

class_name ReactUI

class Transition:
	var data: Dictionary
	
	func _init(_data) -> void:
		self.data = _data

var _render_state: Dictionary
var _cached_nodes: Dictionary
var _components_to_update: Array
var _num_components_to_update: int
var _tw: Tween
var state: Dictionary

func _enter_tree() -> void:
	_render_state = {}
	_cached_nodes = {}
	_components_to_update = []
	_num_components_to_update = 0
	state = {}
	
	_tw = Tween.new()
	add_child(_tw)
	
	_add_component_to_update(self)
	construct()

func construct() -> void: pass

func set_state(new_state: Dictionary) -> void:
	ReactGDDictionaryMethods.merge_dict(self.state, new_state)
	_add_component_to_update(self)

func do_transition(final_val, duration: float, trans_type: int = 0, ease_type: int = 2, delay: float = 0.0):
	return Transition.new({
		"type": "simple",
		"final_val": final_val,
		"duration": duration,
		"trans_type": trans_type,
		"ease_type": ease_type,
		"delay": delay
	})

func do_shake(peak_val, final_val, duration: float, trans_type: int = 0, ease_type: int = 2, delay: float = 0.0):
	return Transition.new({
		"type": "shake",
		"peak_val": peak_val,
		"final_val": final_val,
		"duration": duration,
		"trans_type": trans_type,
		"ease_type": ease_type,
		"delay": delay
	})

func _add_component_to_update(comp: Node) -> void:
	for other_comp in _components_to_update:
		if other_comp.component == comp: return
	
	if comp == self:
		_components_to_update.append({
			"component": comp,
			"child_idx": 0
		})
	else:
		_components_to_update.append({
			"component": comp,
			"child_idx": comp.get_index()
		})
	
	_num_components_to_update += 1

func render() -> Dictionary:
	return {}

func _process(delta) -> void:
	render_process(delta)

func render_process(delta) -> void:
	if _num_components_to_update == 0: return
	
	var start = OS.get_ticks_msec()
	
	for i in range(_num_components_to_update):
		var comp_info :Dictionary = _components_to_update[i]
		var component :Node = comp_info.component
		var parent :Node = component.get_parent()
		if component == self:
			var new_render_state :Dictionary = component.render()
			new_render_state = _build_tree(self, new_render_state, "")
			var tree_diff = ReactGDDictionaryMethods.compute_diff(_render_state, new_render_state)
			
			_iterate_tree(self, self, tree_diff, 0)
			_render_state = new_render_state
		else:
			var path: String = component.path
			var _prev_render_state :Dictionary = ReactGDDictionaryMethods.path_get(_render_state, path, true, {})
			var new_render_state :Dictionary = _prev_render_state.duplicate(true)
			var render: Dictionary = component.render()
			
			render = _build_tree(component.parent_component, render, path + ".c.")
			
			var first_id = render[render.keys()[0]]
			new_render_state.c = {first_id: render}
			
			var tree_diff = ReactGDDictionaryMethods.compute_diff(_prev_render_state, new_render_state)
			
			_iterate_tree(component.parent_component, parent, tree_diff, component.get_index())
			_prev_render_state.c = {first_id: render}
	
	var elapsed = OS.get_ticks_msec() - start
	print("(" + name + ")" + " Render: ", elapsed, " ms")
	
	_num_components_to_update = 0
	_components_to_update.clear()

func _build_tree(prev_component: Node, render_state: Dictionary, path: String) -> Dictionary:
	var id = render_state.id
	path = path + id
	var type = render_state.type
	var props :Dictionary = render_state.get("props", {})
	var children :Array = props.get("children", [])
	var node := {}
	var node_added := false
	
	if self._cached_nodes.has(path):
		node = self._cached_nodes[path]
		var instance = node.instance
		node = {
			"id": id,
			"path": path,
			"type": type,
			"instance": instance,
			"c": {},
			"props": {},
			"signals": {},
			"theme": {},
			"ref": "",
		}
		self._cached_nodes[path] = node
	else:
		node = {
			"id": id,
			"path": path,
			"type": type,
			"instance": type.new(),
			"c": {},
			"props": {},
			"signals": {},
			"theme": {},
			"ref": "",
		}
		node_added = true
		self._cached_nodes[path] = node
	
	node.props = props
	for p_name in props.keys():
		var prop_value = props[p_name]
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
		node.instance.path = path
		node.instance.tree = self
		node.instance.props = props
		node.instance.parent_component = prev_component
		if node_added:
			node.instance.construct()
		children = [node.instance.render()]
		prev_component = node.instance
	
	if children.size() > 0:
		node.c = {}
		for i in range(children.size()):
			var c = self._build_tree(prev_component, children[i], path + ".c." )
			var c_id = c.id
			node.c[c_id] = c
	
	return node

func _iterate_tree(root_component: Node, parent: Node, tree: Dictionary, idx: int) -> void:
	var id: Dictionary = tree.id
	var path: Dictionary = tree.path
	var instance: Dictionary = tree.instance
	var children: Dictionary = tree.c
	var props: Dictionary = tree.props
	var signals: Dictionary = tree.signals
	var theme: Dictionary = tree.theme
	var ref: Dictionary = tree.ref
	var c_type: String = instance.value.get_class()
	
	# Set references
	if instance.change_type == 0:
		if ref.value != "":
			root_component.set(ref.value, instance.value)
	elif instance.change_type == 2:
		if ref.value != "":
			root_component.set(ref.value, null)
	
	# Set props, signals and theme
	if props.change_type == 0 || props.change_type == 1:
		_update_props(instance.value, props.value)
	if signals.change_type == 0 || signals.change_type == 1:
		_update_signals(root_component, instance.value, signals.value)
	if theme.change_type == 0 || theme.change_type == 1:
		_update_theme(instance.value, theme.value)
	
	# Instantiate or remove
	if instance.change_type == 0:
		parent.add_child(instance.value)
		parent.move_child(instance.value, idx)
	elif instance.change_type == 2:
		parent.remove_child(instance.value)
		_cached_nodes.erase(path.value)
		instance.value.queue_free()
		if !children.value.empty():
			for c_id in children.value.keys():
				var c :Dictionary = children.value[c_id]
				if c_type == "ReactComponent":
					_iterate_tree(instance.value, parent, c.value, 0)
				else:
					_iterate_tree(root_component, instance.value, c.value, 0)
		return
	
	if children.change_type == 0 || children.change_type == 1:
		var off = 0
		children = children.value
		for c_id in children.keys():
			var c :Dictionary = children[c_id]
			
			if c.change_type != 3:
				if c_type == "ReactComponent":
					_iterate_tree(instance.value, parent, c.value, idx + off + 1)
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
			var prop_value = prop.value
			if prop_value is Transition && prop.change_type != 2:
				prop_value.data.initial_val = node.get(prop_name)
				_property_transition(node, prop_name, prop_value)
			else:
				if node is LineEdit && prop_name == "text":
					node.text = prop_value
					node.caret_position = prop_value.length()
					continue
				elif node is TextureRect && prop_name == "texture":
					if prop_value is String && prop_value != "":
						node.texture = ResourceLoader.load(prop_value)
						continue
					else:
						node.texture = null
						continue
				node.set(prop_name, prop_value)

func _update_signals(target_component: Node, node: Node, signals: Dictionary) -> void:
	for signal_name in signals.keys():
		var sig = signals[signal_name]
		
		if sig.value is Dictionary:
			var expression :Expression
			var input_names :PoolStringArray 
			
			if sig.change_type < 2:
				expression = Expression.new()
				input_names = PoolStringArray(sig.value.args.value)
				
				input_names.insert(0, 'node')
				
				var err = expression.parse(sig.value.expression.value, input_names)
				if err != OK:
					push_error("A error occured when parsing lambda, error code: " + str(err))
					push_error(expression.get_error_text())
					continue
			
			if sig.change_type == 0:
				node.connect(signal_name, self, "on_dynamic_signal", [{
					"expression": expression,
					"node": node,
					"component": target_component
				}])
			elif sig.change_type == 1:
				node.disconnect(signal_name, self, "on_dynamic_signal")
				node.connect(signal_name, self, "on_dynamic_signal", [{
					"expression": expression,
					"node": node,
					"component": target_component
				}])
			elif sig.change_type == 2:
				node.disconnect(signal_name, self, "on_dynamic_signal")
		else:
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
	if not node is Control: return
	
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
			if prop_val is Transition:
				prop_val.data.initial_val = style_obj.get(prop)
				_property_transition(style_obj, prop, prop_val)
			else:
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
		var value = Color.black
		
		if change_type == 0:
			value = colors[c].value
		elif change_type == 2:
			var default = ClassDB.instance(node.get_class()).get_color(c)
			node.add_color_override(c, default)
			continue
		else:
			value = colors[c].value
		
		if value is Transition:
			value.data.initial_val = node.get_color(c)
			_property_transition(node, "custom_colors/" + c, value)
		else:
			node.add_color_override(c, value)

func _update_constants(node: Control, constants: Dictionary) -> void:
	for c in constants:
		var change_type = constants[c].change_type
		var value = 0
		
		if change_type == 0:
			value = constants[c].value
		elif change_type == 1:
			node.add_constant_override(c, 0)
			continue
		else:
			value = constants[c].value
		
		if value is Transition:
			value.data.initial_val = node.get_constant(c)
			_property_transition(node, "custom_constants/" + c, value)
		else:
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
			
			if prop_val is Transition:
				_property_transition(value, prop, prop_val)
			else:
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

func _property_transition(obj: Object, prop_name: String, transition_data: Transition) -> void:
	_tw.stop(obj, prop_name)
	
	match transition_data.data.type:
		"simple":
			_tw.interpolate_property(
				obj, prop_name, transition_data.data.initial_val, transition_data.data.final_val,
				transition_data.data.duration, transition_data.data.trans_type,
				transition_data.data.ease_type, transition_data.data.delay
			)
		"shake":
			_tw.interpolate_property(
				obj, prop_name, transition_data.data.initial_val, transition_data.data.peak_val,
				transition_data.data.duration * .5, transition_data.data.trans_type,
				transition_data.data.ease_type, transition_data.data.delay
			)
			_tw.interpolate_property(
				obj, prop_name, transition_data.data.peak_val, transition_data.data.final_val,
				transition_data.data.duration * .5, transition_data.data.trans_type,
				transition_data.data.ease_type, transition_data.data.delay + transition_data.data.duration * .5
			)
	
	_tw.start()

func on_dynamic_signal(
	a1 = null, a2 = null, a3 = null, a4 = null, a5 = null, a6 = null, a7 = null,
	a8 = null, a9 = null, a10 = null, a11 = null, a12 = null, a13 = null, a14 = null, a15 = null
) -> void:
	var args := [a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15]
	
	var i := 9
	
	while i >= 0:
		if args[i] is Dictionary:
			break
		i -= 1
	
	var inputs = args.slice(0, i - 1)
	var lambda_info = args[i]
	
	var e: Expression = lambda_info.expression
	var node: Node = lambda_info.node
	var component: Node = lambda_info.component
	
	var obj = e.execute([node] + inputs, component, true)
	if e.has_execute_failed():
		push_error("something bad happened")

func get_class() -> String: return "ReactUI"































