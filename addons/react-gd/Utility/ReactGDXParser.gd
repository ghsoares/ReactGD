extends Node

class_name ReactGDXParser

var rng : RandomNumberGenerator
var sed : String
var unfold_blocks : bool
var file_name: String

func _init() -> void:
	rng = RandomNumberGenerator.new()

# Generates a random id for a child node, two ids should never repeat
func _random_id(added_ids: Array):
	var random_chars := 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+_='
	var num_chars := random_chars.length()
	var length := 4
	var id := ""
	
	while true:
		id = ""
		
		for i in range(length):
			id += random_chars[rng.randi() % num_chars]
		
		if !id in added_ids: break
	
	added_ids.append(id)
	return id

# Throws an error at a given token line and column
func throw_error(line: int, column: int, error_message: String) -> void:
	error_message = "Parsing error at line " + str(line + 1) + ": \n" + error_message
	assert(false, error_message)

# This function finds all the GDX blocks in a code
func _find_gdx_blocks(code: String) -> Array:
	var found := []
	
	# Initializes a tokenizer
	var tokenizer := ReactGDTokenizer.new()
	# These tokens are only used to find GDX blocks
	tokenizer.add_token_expressions({
		"symbol": '[\\w.:]+',
		"string": ['"[^"]*"', "'[^']*'"],
		"multiline_string": '"""[^"""]*"""',
		"tag_open": '<',
		"tag_close": '>',
		"par_open": '\\(',
		"par_close": '\\)'
	})
	# Tokenize the code string
	var tokenized := tokenizer.tokenize(code)
	
	# Current block start
	var block_start := -1
	
	var i := 0
	while i < tokenized.num_tokens:
		var layer_increment := 0
		
		# A block open is `(` + `<`
		if tokenized.get_token_name(i) == "tag_open":
			if tokenized.get_token_name(i - 1) == "par_open":
				block_start = i - 1
		
		# A block close is `>` + `)` 
		if tokenized.get_token_name(i) == "tag_close":
			if tokenized.get_token_name(i + 1) == "par_close":
				# A whole block was found
				if block_start != -1:
					found.append({
						"start": tokenized.get_token_start(block_start),
						"end": tokenized.get_token_end(i + 1),
						"line": tokenized.get_token_line(block_start),
						"column": tokenized.get_token_column(block_start),
						"indent": tokenized.get_token_indent(block_start)
					})
					block_start = -1
		
		i += 1
	
	if block_start != -1:
		tokenized.throw_error(i - 1, "GDX block isn't closed")
	
	return found

# This function extracts all the tags inside a gdx block
# retrives tag type (start, end or single), tag class name and the tag code
func _extract_tags(code: String, line: int, column: int, indent: int) -> Array:
	var tags := []
	
	# Initializes a tokenizer
	var tokenizer := ReactGDTokenizer.new()
	tokenizer.off_line = line
	tokenizer.off_column = column
	tokenizer.off_indent = indent
	# These tokens are only used to find tags
	tokenizer.add_token_expressions({
		# Any kind of valid variable name, like
		# `foo`, `_btn0`, `btn.foo`, `btn.position:x`, etc.
		"symbol": '[\\w.:]+',
		"colon": ":",
		"string": ['"[^"]*"', "'[^']*'"],
		"multiline_string": '"""[^"""]*"""',
		"tag_start_open": '<',
		"tag_start_close": '>',
		"tag_end_open": "</",
		"tag_single_close": "/>",
		"arrow": '=>',
		# Matches any kind of data structure, like [], {} or parentheses ()
		"container_open": '\\(|\\[|\\{',
		"container_close": '\\)|\\]|\\}'
	})
	# Tokenize the code string
	var tokenized := tokenizer.tokenize(code)
	# Removes the first and last parentheses
	tokenized.pop_front()
	tokenized.pop_back()
	
	var i := 0
	var tag_start := -1
	var tag_type := ""
	var tag_class_name := ""
	# If the token is inside parentheses, so it's a pure GDScript code
	var ignore_count := 0
	
	while i < tokenized.num_tokens:
		# Current token is container open, increment ignore count
		if tokenized.get_token_name(i) == "container_open": ignore_count += 1
		# Current token is container close, decrement ignore count
		elif tokenized.get_token_name(i) == "container_close": ignore_count -= 1
		
		if ignore_count < 0:
			tokenized.throw_error(i, "Unexpected parentheses close")
		
		# Only parse tag if is not inside parentheses
		if ignore_count == 0:
			# This tag is opening
			if tokenized.get_token_name(i) in ["tag_start_open", "tag_end_open"]:
				# The previous tag should be closed before opening this one
				if tag_start != -1:
					tokenized.throw_error(i, "The previous tag didn't close")
				tag_start = i
				# Next token should be the class name
				if tokenized.get_token_name(i + 1) != "symbol":
					tokenized.throw_error(i + 1, "Expected tag class name")
				# Get the tag class name
				tag_class_name = tokenized.get_token_string(i + 1)
				# If the token string is `<` this tag is a start tag
				if tokenized.get_token_name(i) == "tag_start_open":
					tag_type = "start"
				# Else if the token string is `</` this tag is a end tag
				elif tokenized.get_token_name(i) == "tag_end_open":
					tag_type = "end"
			# This tag is closing
			elif tokenized.get_token_name(i) in ["tag_start_close", "tag_single_close"]:
				# The tag start should aready be found
				if tag_start == -1:
					tokenized.throw_error(i, "Couldn't find the tag start")
				# If the token string is `/>` this tag is a single tag
				if tokenized.get_token_name(i) == "tag_single_close":
					tag_type = "single"
				
				# We ignore the tag start, the tag class name and tag end tokens
				var tag_code := tokenized.substr(
					code, tag_start + 2, i, true, false
				)
				tags.append({
					"type": tag_type,
					"class": tag_class_name,
					"code": tag_code.strip_edges(),
					# Some info for better error log later
					"line": tokenized.get_token_line(tag_start + 2),
					"column": tokenized.get_token_column(tag_start + 2),
					"indent": tokenized.get_token_indent(tag_start + 2)
				})
				
				# Reset variables for the next tag
				tag_start = -1
				tag_type = ""
				tag_class_name = ""
		
		i += 1
	
	if ignore_count != 0:
		tokenized.throw_error(i - 1, "Parentheses isn't closed")
	if tag_start != -1:
		tokenized.throw_error(tag_start, "Tag didn't close")
	
	return tags

# This function parses the tag into a dictionary
func _parse_tag(tag: Dictionary) -> Dictionary:
	# This tag has no code, so just return it with empty props
	if tag.code == "":
		return {
			"type": tag.type,
			"class": tag.class,
			"props": {},
			"line": tag.line,
			"column": tag.column,
			"indent": tag.indent
		}
	
	# Initializes a tokenizer
	var tokenizer := ReactGDTokenizer.new()
	tokenizer.off_line = tag.line
	tokenizer.off_column = tag.column
	tokenizer.off_indent = tag.indent
	# These tokens are only used to find tags
	tokenizer.add_token_expressions({
		"symbol": '[\\w.:]+',
		"prop_assign": '=',
		"arrow": '=>',
		"integer": [
			"[+-]?\\d+",					# Simple integer
			"[+-]?0b[01]+",					# Binary integer
			"[+-]?0x[0-9a-fA-F]+",			# Hexadecimal integer
		],
		"float": [
			"[+-]?\\d+\\.\\d*",				# Simple float 1, matches optional digits after decimal
			"[+-]?\\d*\\.\\d+",				# Simple float 2, matches optional digits before decimal
			"[+-]?\\d*\\.\\d*e[+-]?\\d+"	# Exponential notation
		],
		"string": ['"[^"]*"', "'[^']*'"],
		"multiline_string": '"""[^"""]*"""',
		"container_open": '\\(|\\[|\\{',
		"container_close": '\\)|\\]|\\}'
	})
	# Tokenize the code string
	var tokenized := tokenizer.tokenize(tag.code)
	
	var tag_info := {
		"type": tag.type,
		"class": tag.class,
		"props": {},
		"line": tag.line,
		"column": tag.column,
		"indent": tag.indent
	}
	
	var i := 0
	while i < tokenized.num_tokens:
		var skip := i + 1
		
		# This token is a property
		if tokenized.get_token_name(i) == "symbol":
			var prop_name := tokenized.get_token_string(i)
			if tokenized.get_token_name(i + 1) == "prop_assign":
				# The prop value is a container
				if tokenized.get_token_name(i + 2) == "container_open":
					# Get the value close
					var end := tokenized.get_token_close(i + 2)
					if end == -1:
						tokenized.throw_error(i + 2, "Couldn't find the value end token")
					var value := tokenized.substr(
						tag.code, i + 2, end
					)
					tag_info.props[prop_name] = value
					
					# Skips to a token after the value close
					skip = end + 1
				# The prop value is a regular variable
				else:
					var value := tokenized.get_token_string(i + 2)
					tag_info.props[prop_name] = value
					
					# Skip to the next prop
					skip = i + 3
			# This is a property without assignation, so assign boolean true as default
			elif i + 1 >= tokenized.num_tokens or tokenized.get_token_name(i + 1) == "symbol":
				tag_info.props[prop_name] = 'true'
				
				# Skip to the next prop
				skip = i + 1
		# The current token should be the property name
		else:
			tokenized.throw_error(i, "Expected property name")
		
		i = skip
	return tag_info

# This function get the end tag of a start tag
func _find_tag_end(i: int, tags: Array, class_type: String) -> int:
	var count := 0
	var num_tags := tags.size()
	
	while i < num_tags:
		if tags[i].type == "start":
			count += 1
		elif tags[i].type == "end":
			count -= 1
			if count == 0:
				if tags[i].class == class_type:
					return i
				else:
					return -1
		
		i += 1
	
	return -1

# Finally, this function build the node tree structure
func _build_tree(tags: Array) -> Array:
	# Added ids for the node children
	var added_ids := []
	var tree := []
	
	var num_tags := tags.size()
	var i := 0
	var curr_node := {
		"id": "",
		"type": "",
		"props": {"children": []},
	}

	while i < num_tags:
		# Get the node key, this is used for nodes inside for loops,
		# so we use key to diff from other nodes
		var key: String = tags[i].props.get("key", "")
		
		# This tag has properties
		if tags[i].type != "end":
			var class_type: String = tags[i].class
			# Set the node type
			curr_node.type = class_type
			
			# Set the id to a random one
			curr_node.id = '"' + _random_id(added_ids) + '"'
			
			# Appends the key property if assigned
			if key != "":
				curr_node.id += "+str(" + key + ")"
			
			# Set the current node props to this tag prop
			for prop_name in tags[i].props.keys():
				curr_node.props[prop_name] = tags[i].props[prop_name]
		
		# This tag has a end tag
		if tags[i].type == "start":
			var class_type: String = tags[i].class
			# Get the end tag position
			var j := _find_tag_end(i, tags, class_type)
			
			# Get the tags between
			var between := tags.slice(i + 1, j - 1)
			
			# Build then recursively
			var children := _build_tree(between)
			
			# Set the current node children
			curr_node.props.children = children
			
			# Skips to the end tag
			i = j
		
		# Appends this node to the hierarchy
		if tags[i].type == "end" || tags[i].type == "single":
			tree.append(curr_node)
			curr_node = {
				"type": "",
				"props": {"children": []},
			}
		
		i += 1
	
	return tree

# The tree is formatted to look better when
# viewing the parsed script
func _format(obj, indent: String = " ", curr_indent: int = 0) -> String:
	var res := ""
	var line_break := "\n" if indent != "" else ""
	if obj is Array:
		res += "["
		var i := 0
		for val in obj:
			res += line_break + indent.repeat(curr_indent)
			if val is Array or val is Dictionary:
				res += _format(val, indent, curr_indent + 1)
			else:
				res += str(val)
			if i < obj.size() - 1:
				res += ","
			i += 1
		if !obj.empty():
			res += line_break + indent.repeat(curr_indent - 1)
		res += "]"
	elif obj is Dictionary:
		res += "{"
		var i := 0
		for k in obj.keys():
			var val = obj[k]
			res += line_break + indent.repeat(curr_indent) + '"' + str(k) + '":'
			if val is Array or val is Dictionary:
				res += _format(val, indent, curr_indent + 1)
			else:
				res += str(val)
			if i < obj.size() - 1:
				res += ","
			i += 1
		if !obj.empty():
			res += line_break + indent.repeat(curr_indent - 1)
		res += "}"
	return res

# Each gdx block is parsed individually
func _parse_gdx_block(code: String, line: int, column: int, indent: int) -> String:
	# First we extract the tags
	var tags := _extract_tags(code, line, column, indent)
	
	# Then we parse each tag into a dictionary
	for i in range(tags.size()):
		tags[i] = _parse_tag(tags[i])
	
	# Just seeding the random number generator using the class type
	rng.seed = hash(tags[0].class + sed)
	rng.state = 137
	
	# Finally we build the tree
	var tree: Dictionary = _build_tree(tags)[0]
	
	return _format(tree, "\t" if unfold_blocks else "", indent + 1)

# Main parsing function, finds all the GDX blocks and replace then
# with parsed ones
func parse_code(code: String) -> String:
	var blocks := _find_gdx_blocks(code)
	
	# When replacing a block, the range from posterior blocks become invalid,
	# so we take the difference into account
	var off := 0
	
	for block in blocks:
		# Use offset for correct block range
		var block_start = block.start + off
		var block_end = block.end + off
		
		# Parses the code
		var parsed: String = _parse_gdx_block(code.substr(
			block_start, block_end - block_start
		), block.line, block.column, block.indent)
		
		# Replace code in range by the new code
		var new_code := ReactGDTokenizer.replace_range(code, parsed, block_start, block_end)
		
		# Here we are taking the length difference
		var len_diff := new_code.length() - code.length()
		off += len_diff
		
		# Set the new code
		code = new_code
	
	# Appends a get component name function at the end of the file.
	code += "\n"
	code += 'func get_component_name() -> String: return "%s"' % file_name.replace(".gdx", "")
	
	return code























