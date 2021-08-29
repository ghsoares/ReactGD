extends Object

class_name ReactGDXParser

var rng : RandomNumberGenerator
var sed : String
var unfold_blocks : bool

func _init() -> void:
	rng = RandomNumberGenerator.new()

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

func _extract_tags(code: String) -> Array:
	var tokenizer := ReactGDTokenizer.new()
	tokenizer.add_token("symbol", '[\\w.]+')
	tokenizer.add_token("colon", ":")
	tokenizer.add_token("string", '"[^"]*"')
	tokenizer.add_token("multiline_string", '"""[^"""]*"""')
	tokenizer.add_token("tag_start_open", '<')
	tokenizer.add_token("tag_start_close", '>')
	tokenizer.add_token("tag_end_open", '</')
	tokenizer.add_token("tag_single_close", '/>')
	tokenizer.add_token("arrow", '=>')
	tokenizer.add_token("par_open", '\\(')
	tokenizer.add_token("par_close", '\\)')
	var tags := []
	
	var tokenized := tokenizer.tokenize(code)
	
	var i := 0
	var tag_start := -1
	var ignore_count := 0
	
	while i < tokenized.num_tokens:
		if tokenized.get_token(i).name == "symbol":
			var string: String = tokenized.get_token(i).string
			
			if string == "if" or string == "elif":
				var start_scope := tokenized.find_token("colon", i)
				assert(start_scope != -1, "Expected " + string + " statement block")
				
				var conditional = tokenized.slice_string(code, i + 1, start_scope - 1)
				
				var indent = tokenized.get_token(i).indent
				var end_scope := tokenized.get_scope_end(indent + 1, start_scope + 1)
				
				var substr = tokenized.slice_string(code, start_scope + 1, end_scope)
				var child_tags = _extract_tags(substr)
				
				var type = string.capitalize()
				
				tags.append({
					"type": "start",
					"code": type + " conditional = (" + conditional + ")",
					"indent": indent,
					"line": tokenized.get_token(i).line
				})
				tags += child_tags
				tags.append({
					"type": "end",
					"code": type,
					"indent": indent,
					"line": tokenized.get_token(i).line
				})
				
				i = end_scope + 1
				continue
			elif string == "else":
				var start_scope := tokenized.find_token("colon", i)
				assert(start_scope != -1, "Expected else statement block")
				
				var indent = tokenized.get_token(i).indent
				var end_scope := tokenized.get_scope_end(indent + 1, start_scope + 1)
				
				var substr = tokenized.slice_string(code, start_scope + 1, end_scope)
				var child_tags = _extract_tags(substr)
				
				tags.append({
					"type": "start",
					"code": "Else",
					"indent": indent,
					"line": tokenized.get_token(i).line
				})
				tags += child_tags
				tags.append({
					"type": "end",
					"code": "Else",
					"indent": indent,
					"line": tokenized.get_token(i).line
				})
				
				i = end_scope + 1
				continue
		
		if tokenized.get_token(i).name == "par_open":
			ignore_count += 1
		elif tokenized.get_token(i).name == "par_close":
			ignore_count -= 1
		if ignore_count == 0:
			if tokenized.get_token(i).name == "tag_start_open" || tokenized.get_token(i).name == "tag_end_open":
				tag_start = i
			elif tokenized.get_token(i).name == "tag_start_close" || tokenized.get_token(i).name == "tag_single_close":
				if tag_start != -1:
					var tag = code.substr(
						tokenized.get_token(tag_start + 1).start,
						tokenized.get_token(i).start - tokenized.get_token(tag_start + 1).start
					)
					if tokenized.get_token(tag_start).name == "tag_start_open":
						if tokenized.get_token(i).name == "tag_start_close":
							tags.append({
								"type": "start",
								"code": tag,
								"indent": tokenized.get_token(i).indent,
								"line": tokenized.get_token(i).line
							})
						elif tokenized.get_token(i).name == "tag_single_close":
							tags.append({
								"type": "single",
								"code": tag,
								"indent": tokenized.get_token(i).indent,
								"line": tokenized.get_token(i).line
							})
					elif tokenized.get_token(tag_start).name == "tag_end_open":
						tags.append({
							"type": "end",
							"code": tag,
							"indent": tokenized.get_token(i).indent,
							"line": tokenized.get_token(i).line
						})
					
					tag_start = -1
		i += 1
	
	return tags

func _parse_tag_info(tag: Dictionary) -> Dictionary:
	var tag_info := {}
	
	var tokenizer := ReactGDTokenizer.new()
	tokenizer.add_token("symbol", '[\\w.:]+')
	tokenizer.add_token("prop_assign", "=")
	tokenizer.add_token("arrow", "=>")
	
	tokenizer.add_token("integer", "[+-]?\\d+")
	tokenizer.add_token("float", "[+-]?\\d*\\.\\d+")
	
	tokenizer.add_token("string", '"[^"]*"')
	tokenizer.add_token("multiline_string", '"""[^"""]*"""')
	tokenizer.add_token("par_open", "\\(")
	tokenizer.add_token("par_close", "\\)")
	tokenizer.add_token("array_open", "\\[")
	tokenizer.add_token("array_close", "\\]")
	tokenizer.add_token("dict_open", "\\{")
	tokenizer.add_token("dict_close", "\\}")
	
	var tokenized := tokenizer.tokenize(tag.code)
	var type: String = tokenized.pop_front().string
	
	if type == "If" or type == "Elif" or type == "Else":
		type = '"' + type + '"'
	
	tag_info.type = type
	tag_info.tag_type = tag.type
	tag_info.props = {}
	
	var i := 0
	var prev_prop_name := ""
	var prev_prop_start := -1
	
	while i < tokenized.num_tokens:
		var prop_name: String = tokenized.get_token(i).string
		
		assert(tokenized.get_token(i + 1).name == "prop_assign", "Expected value assign at line " + str(tokenized.get_token(i).line))
		
		var value_end: int = tokenized.find_token_layered("prop_assign", i + 2)
		if value_end == -1:
			value_end = tokenized.num_tokens - 1
		else:
			value_end -= 2
		
		var prop_value = tokenized.slice_string(tag.code, i + 2, value_end)
		tag_info.props[prop_name] = prop_value
		i = value_end + 1
	
	return tag_info

func _find_tag_end(i: int, tags: Array, type: String) -> int:
	var count := 0
	var num_tags := tags.size()
	
	while i < num_tags:
		if tags[i].tag_type == "start":
			count += 1
		elif tags[i].tag_type == "end":
			count -= 1
			if count == 0:
				if tags[i].type == type:
					return i
				else:
					return -1
		
		i += 1
	
	return -1

func _build_hierarchy(tags: Array) -> Array:
	var hierarchy := []
	var added_ids := []
	
	var num_tags := tags.size()
	var i := 0
	var curr_node := {}
	
	while i < num_tags:
		var props_key: String = tags[i].props.get("key", "")
		var props := {}
		if tags[i].tag_type != "end":
			var type: String = tags[i].type
			
			curr_node['"type"'] = type
			curr_node['"id"'] = '"' + _random_id(added_ids) + '"'
			if props_key != "":
				curr_node['"id"'] += " + str(" + props_key + ")"
			
			for prop_name in tags[i].props.keys():
				var prop_value = tags[i].props[prop_name]
				props['"' + prop_name + '"'] = prop_value
			
			curr_node['"props"'] = props
		
		if tags[i].tag_type == "start":
			var type: String = tags[i].type
			
			var j := _find_tag_end(i, tags, type)
			
			var between := tags.slice(i + 1, j - 1)
			var children := _build_hierarchy(between)
			
			curr_node['"children"'] = children
			
			i = j
		
		if tags[i].tag_type == "end" || tags[i].tag_type == "single":
			hierarchy.append(curr_node)
			curr_node = {}
		
		i += 1
	
	return hierarchy

func _parse_gdx(code: String, indent: int) -> String:
	# Removes all comments from code
	var comment_reg := RegEx.new()
	comment_reg.compile("#.*")
	code = comment_reg.sub(code, " ", true)
	
	var tags := _extract_tags(code)
	
	for i in tags.size():
		tags[i] = _parse_tag_info(tags[i])
	
	rng.seed = hash(tags[0].type + sed)
	rng.state = 137
	
	var hierarchy :Dictionary = _build_hierarchy(tags)[0]
	var final : String
	if unfold_blocks:
		final += ReactGDDictionaryMethods.stringify(hierarchy, "\t", indent)
	else:
		final = str(hierarchy)
	
	return final

func parse(code: String) -> String:
	var tokenizer := ReactGDTokenizer.new()
	# Any kind of symbol accessor, like self, self.foo, something, etc.
	tokenizer.add_token("symbol", '[\\w.:]+')
	# Comment line
	tokenizer.add_token("comment", '#.*')
	tokenizer.add_ignore_token("comment")
	# Single line strings like "a string"
	tokenizer.add_token("string", '"[^"]*"')
	# Multiple line strings like
	# """A text
	# about apples"""
	tokenizer.add_token("multiline_string", '"""[^"""]*"""')
	tokenizer.add_token("tag_open", '<')
	tokenizer.add_token("tag_close", '>')
	# Open parentheses
	tokenizer.add_token("par_open", '\\(')
	# Close parentheses
	tokenizer.add_token("par_close", '\\)')
	
	while true:
		var parsed := false
		var tokenized := tokenizer.tokenize(code)
		
		var j := -1
		var find_start := tokenized.find_template(["par_open", "tag_open"], 0)
		if find_start[0] != -1:
			var find_end := tokenized.find_template(["tag_close", "par_close"], 0)
			if find_end[0] != -1:
				var substr := tokenized.slice_string(code, find_start[0], find_end[1])
				var code_to_parse := substr.substr(1, substr.length() - 2)
				
				var new_code := _parse_gdx(code_to_parse, tokenized.get_token(find_start[0]).indent + 1)
				code = code.replace(substr, new_code)
				parsed = true
		
		if !parsed: break
	
	return code









