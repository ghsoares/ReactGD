extends Reference
class_name ReactGDTheme

# The actual theme object
var theme: Theme

# The default theme object
var default: Theme

"""
var theme = ReactGDTheme.new()

theme.for_type('Button')
theme.for_style('*:flat')
theme.set_border_width(8)

"""

# Construct the ReactGDTheme
func _init() -> void:
	self.theme = Theme.new()
	self.default = Theme.new()
	self.theme.copy_default_theme()
	self.default.copy_default_theme()

# Get the stylebox from style name and box type
func __get_stylebox(style_name: String, node_type: String, box_type) -> StyleBox:
	# Get current stylebox
	var stylebox	:= theme.get_stylebox(style_name, node_type)

	# Check if need to create the stylebox
	if (stylebox == null) or not (stylebox is box_type):
		stylebox = box_type.new()
		theme.set_stylebox(style_name, node_type, stylebox)
	
	# Return the stylebox
	return stylebox

# Internal function to set a property in style
func __style_set(style: StyleBox, prop: String, value) -> void:
	# Match the property name
	match prop:
		# Content margin
		"content_margin":
			style.set("content_margin_left", value)
			style.set("content_margin_right", value)
			style.set("content_margin_top", value)
			style.set("content_margin_bottom", value)
		"content_margin_horizontal":
			style.set("content_margin_left", value)
			style.set("content_margin_right", value)
		"content_margin_vertical":
			style.set("content_margin_top", value)
			style.set("content_margin_bottom", value)

		# Border width
		"border_width":
			style.set("border_width_left", value)
			style.set("border_width_right", value)
			style.set("border_width_top", value)
			style.set("border_width_bottom", value)
		"border_width_horizontal":
			style.set("border_width_left", value)
			style.set("border_width_right", value)
		"border_width_vertical":
			style.set("border_width_top", value)
			style.set("border_width_top", value)
		
		# Corner radius
		"corner_radius":
			style.set("corner_radius_top_left", value)
			style.set("corner_radius_top_right", value)
			style.set("corner_radius_bottom_left", value)
			style.set("corner_radius_bottom_right", value)
		"corner_radius_left":
			style.set("corner_radius_top_left", value)
			style.set("corner_radius_bottom_left", value)
		"corner_radius_right":
			style.set("corner_radius_top_right", value)
			style.set("corner_radius_bottom_right", value)
		"corner_radius_top":
			style.set("corner_radius_top_left", value)
			style.set("corner_radius_top_right", value)
		"corner_radius_bottom":
			style.set("corner_radius_bottom_left", value)
			style.set("corner_radius_bottom_right", value)
		
		# Expand margin
		"expand_margin":
			style.set("expand_margin_left", value)
			style.set("expand_margin_right", value)
			style.set("expand_margin_top", value)
			style.set("expand_margin_bottom", value)
		"expand_margin_horizontal":
			style.set("expand_margin_left", value)
			style.set("expand_margin_right", value)
		"expand_margin_vertical":
			style.set("expand_margin_top", value)
			style.set("expand_margin_top", value)
		
		# Margin
		"margin":
			style.set("margin_left", value)
			style.set("margin_right", value)
			style.set("margin_top", value)
			style.set("margin_bottom", value)
		"margin_horizontal":
			style.set("margin_left", value)
			style.set("margin_right", value)
		"margin_vertical":
			style.set("margin_top", value)
			style.set("margin_bottom", value)

		# Default, just set the property
		_:
			style.set(prop, value)

# Add a color to the theme
func add_color(data: Dictionary) -> Reference:
	# Regex used for the selectors
	var selector_reg	:= RegEx.new()
	selector_reg.compile("\\[?([\\w*,]+)\\]?:\\[?([\\w*,]+)\\]?")

	# For each selector
	for selector in data:
		# Get selector info
		var sm	:= selector_reg.search(selector)

		assert(sm, "Style selector \"%s\" is invalid" % selector)

		# Get node type
		var node_types_s: String = sm.get_string(1)

		# Get color names
		var color_names_s: String = sm.get_string(2)

		# Get node types
		var node_types: PoolStringArray

		# Check if node types is all types
		if node_types_s == "*":
			# Add all the nodes
			node_types = theme.get_type_list("")
		else:
			# Add the node types splitted
			node_types = node_types_s.split(",")
		
		# For each node type
		for node_type in node_types:
			# Get color names
			var color_names: PoolStringArray

			# Check if color names is all names
			if color_names_s == "*":
				# Add all the styles
				color_names = theme.get_color_list(node_type)
			else:
				# Add the style name splitted
				color_names = color_names_s.split(",")
			
			# For each color name
			for color_name in color_names:
				# Get the color value
				var c = data[selector]

				# Set the color
				theme.set_color(color_name, node_type, c)

	return self

# Add a constant to the theme
func add_constant(data: Dictionary) -> Reference:
	# Regex used for the selectors
	var selector_reg	:= RegEx.new()
	selector_reg.compile("\\[?([\\w*,]+)\\]?:\\[?([\\w*,]+)\\]?")

	# For each selector
	for selector in data:
		# Get selector info
		var sm	:= selector_reg.search(selector)

		assert(sm, "Style selector \"%s\" is invalid" % selector)

		# Get node type
		var node_types_s: String = sm.get_string(1)

		# Get constant names
		var const_names_s: String = sm.get_string(2)

		# Get node types
		var node_types: PoolStringArray

		# Check if node types is all types
		if node_types_s == "*":
			# Add all the nodes
			node_types = theme.get_type_list("")
		else:
			# Add the node types splitted
			node_types = node_types_s.split(",")
		
		# For each node type
		for node_type in node_types:
			# Get constant names
			var const_names: PoolStringArray

			# Check if color names is all names
			if const_names_s == "*":
				# Add all the styles
				const_names = theme.get_color_list(node_type)
			else:
				# Add the style name splitted
				const_names = const_names_s.split(",")
			
			# For each constant name
			for const_name in const_names:
				# Get the constant value
				var c = data[selector]

				# Set the constant
				theme.set_constant(const_name, node_type, c)

	return self

# Add a style to the theme
func add_style(data: Dictionary) -> Reference:
	# Regex used for the selectors
	var selector_reg	:= RegEx.new()
	selector_reg.compile("\\[?([\\w*,]+)\\]?:\\[?([\\w*,]+)\\]?:([\\w]+)")

	# For each selector
	for selector in data:
		# Get the property
		var props: Dictionary = data[selector]

		# Get selector info
		var sm	:= selector_reg.search(selector)

		assert(sm, "Style selector \"%s\" is invalid" % selector)

		# Get node type
		var node_types_s: String = sm.get_string(1)

		# Get style names
		var style_names_s: String = sm.get_string(2)

		# Get style type
		var style_type_s: String = sm.get_string(3)

		# Get node types
		var node_types: PoolStringArray

		# Check if node types is all types
		if node_types_s == "*":
			# Add all the nodes
			node_types = theme.get_type_list("")
		else:
			# Add the node types splitted
			node_types = node_types_s.split(",")
		
		# For each node type
		for node_type in node_types:
			# Get style names
			var style_names: PoolStringArray

			# Check if style names is all names
			if style_names_s == "*":
				# Add all the styles
				style_names = theme.get_stylebox_list(node_type)
			else:
				# Add the style name splitted
				style_names = style_names_s.split(",")
			
			# Get the box type
			var box_type
			match style_type_s:
				"empty": box_type = StyleBoxEmpty
				"flat": box_type = StyleBoxFlat
				"line": box_type = StyleBoxLine
				"texture": box_type = StyleBoxTexture
				_: assert(false, "Style type \"%s\" is invalid" % style_type_s)
			
			# For each style name
			for style_name in style_names:
				# Get the stylebox
				var stylebox	:= __get_stylebox(style_name, node_type, box_type)
				
				# For each property
				for prop in props:
					__style_set(stylebox, prop, props[prop])

	return self
