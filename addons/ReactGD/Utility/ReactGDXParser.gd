extends Node

class_name ReactGDXParser

var rng :RandomNumberGenerator
var unfold_blocks: bool

func _init() -> void:
	rng = RandomNumberGenerator.new()
	rng.randomize()

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

func _find_literal_close(i: int, tokens: Array, open_name: String, close_name: String) -> int:
	var count := 0
	var num_tokens := tokens.size()
	
	while i < num_tokens:
		if tokens[i].name == open_name:
			count += 1
		elif tokens[i].name == close_name:
			count -= 1
			if count == 0:
				return i
		i += 1
	
	return -1

func _find_tag_end(i: int, tags: Array, type: String) -> int:
	var count := 0
	var num_tags := tags.size()
	
	while i < num_tags:
		if tags[i].type == "start":
			count += 1
		elif tags[i].type == "end":
			count -= 1
			if count == 0:
				if tags[i].class_type == type:
					return i
				else:
					return -1
		
		i += 1
	
	return -1

func _extract_tags(code: String) -> Array:
	var tokenizer := ReactGDTokenizer.new()
	tokenizer.add_token("symbol", "[\\w.]+")
	tokenizer.add_token("string", "\"[^\"]+\"")
	tokenizer.add_token("multiline_string", "\"\"\"[^\"\"\"]+\"\"\"")
	tokenizer.add_token("tag_start_open", "<")
	tokenizer.add_token("tag_start_close", ">")
	tokenizer.add_token("tag_end_open", "</")
	tokenizer.add_token("tag_single_close", "/>")
	tokenizer.add_token("par_open", "\\(")
	tokenizer.add_token("par_close", "\\)")
	var tags := []
	
	var tokens := tokenizer.tokenize(code)
	tokens.pop_front()
	tokens.pop_back()
	
	var num_tokens := tokens.size()
	var i := 0
	var j := -1
	var ignore_count := 0
	
	while i < num_tokens:
		if tokens[i].name == "par_open":
			ignore_count += 1
		elif tokens[i].name == "par_close":
			ignore_count -= 1
		if ignore_count == 0:
			if tokens[i].name == "tag_start_open" || tokens[i].name == "tag_end_open":
				j = i
			elif tokens[i].name == "tag_start_close" || tokens[i].name == "tag_single_close":
				if j != -1:
					var tag = code.substr(
						tokens[j].match.get_start(),
						tokens[i].match.get_end() - tokens[j].match.get_start()
					)
					if tokens[j].name == "tag_start_open":
						if tokens[i].name == "tag_start_close":
							tags.append({
								"type": "start",
								"code": tag
							})
						elif tokens[i].name == "tag_single_close":
							tags.append({
								"type": "single",
								"code": tag
							})
					elif tokens[j].name == "tag_end_open":
						tags.append({
							"type": "end",
							"code": tag
						})
					
					j = -1
		
		i += 1
	
	return tags

func _parse_tag_info(tag: Dictionary) -> Dictionary:
	var tag_info := {}
	
	var tokenizer := ReactGDTokenizer.new()
	tokenizer.add_token("symbol", "[\\w.:]+")
	tokenizer.add_token("prop_assign", "=")
	
	tokenizer.add_token("integer", "[+-]?\\d+")
	tokenizer.add_token("float", "[+-]?\\d*\\.\\d+")
	
	tokenizer.add_token("string", "\"[^\"]+\"")
	tokenizer.add_token("multiline_string", "\"\"\"[^\"\"\"]+\"\"\"")
	tokenizer.add_token("node_path", "\\@\"[^\"]+\"")
	tokenizer.add_token("get_node", "\\$\"[^\"]+\"")
	tokenizer.add_token("par_open", "\\(")
	tokenizer.add_token("par_close", "\\)")
	tokenizer.add_token("array_open", "\\[")
	tokenizer.add_token("array_close", "\\]")
	tokenizer.add_token("dict_open", "\\{")
	tokenizer.add_token("dict_close", "\\}")
	
	var tokens := tokenizer.tokenize(tag.code)
	tag_info.class_type = tokens.pop_front().match.get_string()
	tag_info.type = tag.type
	tag_info.props = {}
	
	var num_tokens := tokens.size()
	var i := 0
	
	while i < num_tokens:
		var skip := i + 3
		if (i + 2) < num_tokens:
			if tokens[i].name == "symbol" && tokens[i + 1].name == "prop_assign":
				var prop_name = tokens[i].match.get_string()
				var is_container_literal := false
				var end_i := -1
				
				if tokens[i + 2].name == "par_open":
					end_i = _find_literal_close(i + 2, tokens, "par_open", "par_close")
					is_container_literal = true
				elif tokens[i + 2].name == "array_open":
					end_i = _find_literal_close(i + 2, tokens, "array_open", "array_close")
					is_container_literal = true
				elif tokens[i + 2].name == "dict_open":
					end_i = _find_literal_close(i + 2, tokens, "dict_open", "dict_close")
					is_container_literal = true
				
				if is_container_literal && end_i != -1:
					var prop_val = tag.code.substr(
						tokens[i + 2].match.get_start(),
						tokens[end_i].match.get_end() - tokens[i + 2].match.get_start()
					)
					tag_info.props[prop_name] = prop_val
					skip = end_i + 1
				else:
					var prop_val = tokens[i + 2].match.get_string()
					tag_info.props[prop_name] = prop_val
		
		i = skip

	return tag_info

func _build_hierarchy(tags: Array) -> Array:
	var hierarchy := []
	var added_ids := []
	
	var num_tags := tags.size()
	var i := 0
	var curr_node := {}
	
	while i < num_tags:
		var props_key: String = tags[i].props.get("key", "")
		var props := {}
		if tags[i].type != "end":
			var type: String = tags[i].class_type
			
			curr_node['"type"'] = type
			curr_node['"id"'] = '"' + _random_id(added_ids) + '"'
			if props_key != "":
				curr_node['"id"'] += " + str(" + props_key + ")"
			
			for prop_name in tags[i].props.keys():
				props['"' + prop_name + '"'] = tags[i].props[prop_name]
			
			curr_node['"props"'] = props
		
		if tags[i].type == "start":
			var type: String = tags[i].class_type
			
			var j := _find_tag_end(i, tags, type)
			
			var between := tags.slice(i + 1, j - 1)
			var children := _build_hierarchy(between)
			
			props['"children"'] = children
			
			i = j
		
		if tags[i].type == "end" || tags[i].type == "single":
			hierarchy.append(curr_node)
			curr_node = {}
		
		i += 1
	
	return hierarchy

"""
GDX parsing function,
it parses the tags step by step:
	-Extract the tags;
	-Parse the tags properties;
	-Build the hierarchy.
"""
func _parse_gdx(code: String) -> String:
	# Removes all comments from code
	var comment_reg := RegEx.new()
	comment_reg.compile("#.*")
	code = comment_reg.sub(code, " ", true)
	
	var tags := _extract_tags(code)
	
	for i in range(tags.size()):
		tags[i] = _parse_tag_info(tags[i])
	
	var hierarchy :Dictionary = _build_hierarchy(tags)[0]
	var final := str(hierarchy)
	
	if unfold_blocks:
		final = ReactGDDictionaryMethods.unfold_string(final, "\t")
	
	return final

"""
Main parsing function,
searches for a templates that starts with "(<..." and end with ">)..." or "/>...",
meaning that there are a GDX block, and replaces with gdscript variant
"""
func parse(code: String) -> String:
	var tokenizer := ReactGDTokenizer.new()
	# Any kind of symbol accessor, like self, self.foo, something, etc.
	tokenizer.add_token("symbol", "[\\w\\.]+")
	# Comment line
	tokenizer.add_token("comment", "#.*")
	tokenizer.add_ignore_token("comment")
	# Single line strings like "a string"
	tokenizer.add_token("string", "\"[^\"]*\"")
	# Multiple line strings like
	# """A text
	# about apples"""
	tokenizer.add_token("multiline_string", "\"\"\"[^\"\"\"]*\"\"\"")
	tokenizer.add_token("tag_open", "<")
	tokenizer.add_token("tag_close", ">")
	# Open parentheses
	tokenizer.add_token("par_open", "\\(")
	# Close parentheses
	tokenizer.add_token("par_close", "\\)")
	
	while true:
		var parsed := false
		var tokens := tokenizer.tokenize(code)
		
		var num_tokens := tokens.size()
		var i := 0
		var j := -1
		
		while i < num_tokens:
			if tokens[i].name == "par_open":
				if tokens[i + 1].name == "tag_open":
					j = i
					i += 1
			elif tokens[i].name == "tag_close":
				if tokens[i + 1].name == "par_close" && j != -1:
					var substr = code.substr(
						tokens[j].match.get_start(),
						tokens[i + 1].match.get_end() - tokens[j].match.get_start()
					)
					var new_code = _parse_gdx(substr)
					code = code.replace(substr, new_code)
					parsed = true
					code = code.replace(substr, "{}")
					break
			
			i += 1
		
		if !parsed: break
	
	return code














